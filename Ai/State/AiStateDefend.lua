--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateDefend
--- @class AiStateDefend : AiStateBase
--- @field bombsite string
--- @field defendTime number
--- @field defendTimer Timer
--- @field getToSiteTimer Timer
--- @field isAllowedToDuckAtNode boolean
--- @field isAtDestination boolean
--- @field isDefending boolean
--- @field isFirstSpot boolean
--- @field isJiggling boolean
--- @field isJigglingUponReachingSpot boolean
--- @field isOnDefendSpot boolean
--- @field isWeaponEquipped boolean
--- @field jiggleDirection string
--- @field jiggleTime number
--- @field jiggleTimer Timer
--- @field node NodeTypeDefend
--- @field priority number
--- @field teammateInTroubleTimer Timer
--- @field isSpecificNodeSet boolean
local AiStateDefend = {
    name = "Defend",
    requiredNodes = {
        Node.defendSiteCt,
        Node.defendSiteT,
        Node.defendBombCt,
        Node.defendBombT,
        Node.defendHostageT
    },
    requiredGamemodes = {
        AiUtility.gamemodes.DEMOLITION,
        AiUtility.gamemodes.WINGMAN,
        AiUtility.gamemodes.HOSTAGE
    }
}

--- @param fields AiStateDefend
--- @return AiStateDefend
function AiStateDefend:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDefend:__init()
    self.defendTime = Math.getRandomFloat(2, 6)
    self.defendTimer = Timer:new()
    self.getToSiteTimer = Timer:new()
    self.jiggleDirection = "Left"
    self.jiggleTime = Math.getRandomFloat(0.2, 0.5)
    self.jiggleTimer = Timer:new():start()
    self.teammateInTroubleTimer = Timer:new():startThenElapse()
    self.bombsite = AiUtility.randomBombsite

    Callbacks.roundStart(function()
        self.getToSiteTimer:stop()

        local slot = 0

        for _, teammate in Table.sortedPairs(Player.get(function(p)
            return p:isTeammate()
        end, true), function(a, b)
            return a:getKdRatio() < b:getKdRatio()
        end) do
            slot = slot + 1

            if teammate:isLocalPlayer() then
                break
            end
        end

        local operand = slot + Entity.getGameRules():m_totalRoundsPlayed()
        local bombsite = (operand % 2) == 0 and "A" or "B"

        self:invoke(bombsite)
    end)

    Callbacks.roundEnd(function()
        self:reset()
    end)

    Callbacks.bombSpawned(function(e)
    	Client.fireAfter(1, function()
            if e.bomb and LocalPlayer:getOrigin():getDistance(e.bomb:m_vecOrigin()) > 1000 then
                self.getToSiteTimer:start()
            end

            self:invoke(Nodegraph.getClosestBombsiteName(e.bomb:m_vecOrigin()))
    	end)
    end)

    Callbacks.playerHurt(function(e)
        if not e.victim:isTeammate() or e.victim:isLocalPlayer() then
            return
        end

        local clientOrigin = LocalPlayer:getOrigin()

        if clientOrigin:getDistance(e.victim:getOrigin()) > 500 then
            return
        end

        if clientOrigin:getDistance(e.attacker:getOrigin()) > 650 then
            return
        end

        self.teammateInTroubleTimer:start()
    end)

    Callbacks.setupCommand(function()
        if AiUtility.gameRules:m_bFreezePeriod() == 1 then
            return
        end

        if not AiUtility.bombCarrier then
            return
        end

        if AiUtility.bombCarrier:isLocalPlayer() then
            return
        end

        if self.getToSiteTimer:isStarted() then
            return
        end

        local nearestBombsite = Nodegraph.getClosestBombsite(AiUtility.bombCarrier:getOrigin())

        if AiUtility.bombCarrier:getOrigin():getDistance(nearestBombsite.origin) > 1500 then
            return
        end

        local distance = 1450

        if LocalPlayer:getOrigin():getDistance(nearestBombsite.origin) < distance then
            return
        end

        self.getToSiteTimer:start()
        self:invoke(nearestBombsite.bombsite)
    end)
end

--- @return number
function AiStateDefend:assess()
    if AiUtility.enemiesAlive == 0 then
        return AiPriority.IGNORE
    end

    if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.DEMOLITION or AiUtility.mapInfo.gamemode == AiUtility.gamemodes.WINGMAN then
        return self:getDemolitionPriority()
    elseif AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE then
        return self:getHostagePriority()
    end

    return AiPriority.IGNORE
end

--- @return number
function AiStateDefend:getDemolitionPriority()
    if LocalPlayer.isCarryingBomb() then
        return AiPriority.IGNORE
    end

    local bomb = AiUtility.plantedBomb

    if AiUtility.isBombBeingDefusedByEnemy or AiUtility.isBombBeingPlantedByEnemy then
        return AiPriority.IGNORE
    end

    if LocalPlayer:isCounterTerrorist() then
        -- The bomb is planted.
        if AiUtility.isBombPlanted() then
            -- Defend our teammate who is defusing.
            if AiUtility.isBombBeingDefusedByTeammate then
                return AiPriority.DEFEND_DEFUSER
            end

            return AiPriority.IGNORE
        end

        -- We're not near the site.
        -- This will practically force the AI to go to the site.
        if self.getToSiteTimer:isStarted() and not self.getToSiteTimer:isElapsed(12) then
            return AiPriority.DEFEND_EXPEDITE
        end

        -- Hold specific angle.
        if not bomb and self.isSpecificNodeSet and self:isEnemyHoldable() then
            local isAbleToDefend = true

            if AiUtility.bombCarrier then
                local bombOrigin = AiUtility.bombCarrier:getOrigin()

                if bombOrigin:getDistance(Nodegraph.getClosestBombsite(bombOrigin).origin) < 650 then
                    isAbleToDefend = false
                end
            end

            if isAbleToDefend then
                return AiPriority.DEFEND_EXPEDITE
            end
        end

        -- We can hold an approaching enemy.
        if self.isOnDefendSpot and self:isEnemyHoldable() then
            return AiPriority.DEFEND_ACTIVE
        end

        -- Basic defend behaviour.
        return AiPriority.DEFEND_GENERIC
    elseif LocalPlayer:isTerrorist() then
        -- Hold specific angle.
        if bomb and self.isSpecificNodeSet and self:isEnemyHoldable() then
            return AiPriority.DEFEND_EXPEDITE
        end

        -- We should probably go to the site.
        if AiUtility.bombCarrier and not AiUtility.bombCarrier:is(LocalPlayer) then
            local bombCarrierOrigin = AiUtility.bombCarrier:getOrigin()
            local bombsite = Nodegraph.getClosestBombsite(bombCarrierOrigin)
            local distance = bombCarrierOrigin:getDistance(bombsite.origin)

            if AiUtility.isBombBeingPlantedByTeammate or distance < 900 then
                self.ai.routines.walk:block()

                return AiPriority.DEFEND_PLANTER
            end
        end

        -- We're not near the site.
        -- This will practically force the AI to go to the site.
        if self.getToSiteTimer:isStarted() and not self.getToSiteTimer:isElapsed(12) then
            return AiPriority.DEFEND_EXPEDITE
        end

        -- We can hold an approaching enemy.
        if AiUtility.plantedBomb and not AiUtility.isBombBeingDefusedByEnemy and self.isOnDefendSpot and self:isEnemyHoldable() then
            return AiPriority.DEFEND_ACTIVE
        end

        -- Bomb is planted.
        if AiUtility.plantedBomb then
            return AiPriority.DEFEND_ACTIVE
        end

        -- Basic defend behaviour.
        return AiPriority.DEFEND_GENERIC
    end

    return AiPriority.IGNORE
end

--- @return number
function AiStateDefend:getHostagePriority()
    if LocalPlayer:isTerrorist() then
        -- The CTs have a hostage.
        if AiUtility.isHostageCarriedByEnemy then
            return AiPriority.IGNORE
        end

        -- We can hold an approaching enemy.
        if self.isOnDefendSpot and self:isEnemyHoldable() then
            return AiPriority.DEFEND_PASSIVE
        end

        -- Basic defend behaviour.
        return AiPriority.DEFEND_GENERIC
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateDefend:reset()
    self.isDefending = false
    self.isAtDestination = false
    self.isOnDefendSpot = false
    self.isSpecificNodeSet = false
    self.node = nil

    self.defendTimer:stop()
end

--- @return boolean
function AiStateDefend:isEnemyHoldable()
    if AiUtility.isBombBeingPlantedByEnemy or AiUtility.isBombBeingDefusedByEnemy or AiUtility.isHostageCarriedByEnemy then
        return false
    end

    if not self.teammateInTroubleTimer:isElapsed(4) then
        return false
    end

    if Table.isEmpty(AiUtility.enemies) then
        return false
    end

    local cameraAngles = LocalPlayer.getCameraAngles()
    local eyeOrigin = LocalPlayer.getEyeOrigin()
    local clientOrigin = LocalPlayer.getEyeOrigin()
    local isAnyEnemies = false

    for _, enemy in pairs(AiUtility.enemies) do
        isAnyEnemies = true

        if clientOrigin:getDistance(enemy:getOrigin()) < 1500
            and cameraAngles:getFov(eyeOrigin, enemy:getEyeOrigin()) > 80
        then
            return false
        end
    end

    if not isAnyEnemies then
        return false
    end

    return true
end

--- @return void
function AiStateDefend:activate()
    if not self.isSpecificNodeSet then
        self:setActivityNode(self.bombsite)
    end

    if not self.node then
        self:invoke()
        self:setActivityNode(self.bombsite)
    end

    self:move()
end

--- @return void
function AiStateDefend:deactivate()
    self:reset()
end

--- @return void
function AiStateDefend:move()
    self.lastPriority = self.priority
    self.isDefending = false
    self.isAtDestination = false
    self.isOnDefendSpot = false
    self.isJiggling = false
    self.isFirstJiggle = true
    self.isAllowedToDuckAtNode = Math.getChance(2)
    self.isJigglingUponReachingSpot = Math.getChance(0.75)

    self.defendTimer:stop()
    self.jiggleTimer:stop()

    local task

    if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE then
        task = "Defend the hostages"
    else
        task = string.format("Defend %s site", self.node.bombsite:upper())
    end

    Pathfinder.moveToNode(self.node, {
        task = task,
        isCounterStrafingOnGoal = true,
        goalReachedRadius = 8
    })
end

--- @param bombsite string
--- @return void
function AiStateDefend:invoke(bombsite)
    if bombsite then
        self.bombsite = bombsite
    end

    self:queueForReactivation()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDefend:think(cmd)
    if not self.node then
        self:reset()

        return
    end

    Pathfinder.canRandomlyJump()

    if self.priority ~= self.lastPriority then
        self.lastPriority = self.priority

        if self.priority == AiPriority.DEFEND_DEFUSER or self.priority == AiPriority.DEFEND_PLANTER then
            local origin

            if AiUtility.plantedBomb then
                origin = AiUtility.plantedBomb:m_vecOrigin()
            elseif AiUtility.bombCarrier then
                origin = AiUtility.bombCarrier:getOrigin()
            end

            self:invoke(Nodegraph.getClosestBombsiteName(origin))
        end
    end

    local distance = AiUtility.clientNodeOrigin:getDistance(self.node.floorOrigin)
    local trace = Trace.getLineToPosition(LocalPlayer.getEyeOrigin(), self.node.lookFromOrigin, AiUtility.traceOptionsVisible, "AiStateDefend.think<FindIfVisibleNode>")

    if not trace.isIntersectingGeometry then
        if AiUtility.closestEnemy and LocalPlayer:getOrigin():getDistance(AiUtility.closestEnemy:getOrigin()) < 1250 then
            if distance < 750 then
                VirtualMouse.lookAtLocation(self.node.lookAtOrigin, 5.5, VirtualMouse.noise.moving, "Defend look at angle")
            end
        else
            if distance < 500 then
                VirtualMouse.lookAtLocation(self.node.lookAtOrigin, 5, VirtualMouse.noise.moving, "Defend look at angle")
            end
        end
    end

    -- Walk.
    if self.priority == AiPriority.DEFEND_DEFUSER or self.priority == AiPriority.DEFEND_PLANTER then
        self.ai.routines.walk:block()
    end

    if distance < 300 then
        self.isOnDefendSpot = true

        self.ai.routines.manageGear:block()
        self.ai.routines.manageWeaponScope:block()
        self.defendTimer:ifPausedThenStart()

        -- Duck when holding this node.
        if self.isAllowedToDuckAtNode and distance < 32 and self.node.isAllowedToDuckAt then
            Pathfinder.duck()
        end

        -- Equip the correct gear.
        LocalPlayer.equipAvailableWeapon()
    else
        self.isOnDefendSpot = false
        self.isJiggling = false
        self.isJigglingUponReachingSpot = false

        if LocalPlayer:isHoldingSniper() then
            LocalPlayer.unscope()
        end

        self.defendTimer:stop()
    end

    -- Set activity string.
    if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE then
        self.activity = "Defending hostages"
    else
        if self.priority == AiPriority.DEFEND_DEFUSER then
            self.activity = string.format("Covering defuser on %s", self.node.bombsite)
        elseif self.priority == AiPriority.DEFEND_PLANTER then
            self.activity = string.format("Covering planter on %s", self.node.bombsite)
        else
            if distance < 750 then
                self.activity = string.format("Defending %s", self.node.bombsite)
            else
                self.activity = string.format("Going %s", self.node.bombsite)
            end
        end
    end

    -- There's a teammate already near this defensive spot. We should hold someplace else.
    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():getDistance(self.node.floorOrigin) < 128 then
            self:invoke(self.node.bombsite)
        end
    end

    -- Restart defend procedure somewhere else.
    -- Don't do this if we're defending against a specific threat.
    if self.priority ~= AiPriority.DEFEND_ACTIVE and self.defendTimer:isElapsedThenStop(self.defendTime) then
        self.defendTime = Math.getRandomFloat(3.5, 6)

        -- Move to another spot on the site.
        if Math.getChance(16) then
            self:invoke(self.node.bombsite)
        else
            self:swapActivityNode()
        end

        return
    end

    -- Jiggle hold the angle.
    if self.isJigglingUponReachingSpot then
        if distance < 8 then
            self.isJiggling = true
        end

        if self.isJiggling then
            local jiggleTime = self.jiggleTime

            if self.isFirstJiggle then
                jiggleTime = jiggleTime * 0.5
            end

            self.jiggleTimer:ifPausedThenStart()

            if self.jiggleTimer:isElapsedThenRestart(jiggleTime) then
                self.isFirstJiggle = false

                self.jiggleDirection = self.jiggleDirection == "Left" and "Right" or "Left"
            end

            --- @type Vector3
            local direction = self.node.direction[string.format("get%s", self.jiggleDirection)](self.node.direction)

            Pathfinder.moveInDirection(direction)
        end
    end

    -- Reached destination.
    if distance < 10 then
        self.isAtDestination = true
        self.isDefending = true

        if LocalPlayer:isHoldingSniper() then
            LocalPlayer.scope()
        end
    end
end

--- @return void
function AiStateDefend:swapActivityNode()
    self.node = self.node.pairedWith

    self:move()
end

--- @param bombsite string
--- @return NodeTypeDefend
function AiStateDefend:setActivityNode(bombsite)
    bombsite = bombsite or AiUtility.randomBombsite

    if LocalPlayer:isCounterTerrorist() then
        local class

        if self.priority == AiPriority.DEFEND_DEFUSER then
            class = Node.defendBombCt
        else
            class = Node.defendSiteCt
        end

        self.node = Nodegraph.getRandomForBombsite(class, bombsite)
    elseif LocalPlayer:isTerrorist() then
        local class

        if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE then
            class = Node.defendHostageT

            self.node = Nodegraph.getRandom(class)
        elseif AiUtility.mapInfo.gamemode == AiUtility.gamemodes.DEMOLITION or AiUtility.mapInfo.gamemode == AiUtility.gamemodes.WINGMAN then
            if self.priority == AiPriority.DEFEND_PLANTER then
                class = Node.defendBombT
            else
                class = Node.defendSiteT
            end

            self.node = Nodegraph.getRandomForBombsite(class, bombsite)
        end
    end
end

return Nyx.class("AiStateDefend", AiStateDefend, AiStateBase)
--}}}
