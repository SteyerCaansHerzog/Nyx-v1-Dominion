--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
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
    },
    requiredGamemodes = {
        AiUtility.gamemodes.DEMOLITION,
        AiUtility.gamemodes.WINGMAN,
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
    self.jiggleTime = Math.getRandomFloat(0.25, 0.6)
    self.jiggleTimer = Timer:new():start()
    self.teammateInTroubleTimer = Timer:new():startThenElapse()
    self.bombsite = AiUtility.randomBombsite

    Callbacks.roundPrestart(function()
        self.getToSiteTimer:stop()

        local slot = 0

        for _, teammate in Table.sortedPairs(Player.get(function(p)
            return p:isTeammate()
        end, true), function(a, b)
            return a:getKdRatio() < b:getKdRatio()
        end) do
            slot = slot + 1

            if teammate:isClient() then
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
        if not e.victim:isTeammate() or e.victim:isClient() then
            return
        end

        local clientOrigin = LocalPlayer:getOrigin()

        if clientOrigin:getDistance(e.victim:getOrigin()) > 500 then
            return
        end

        if clientOrigin:getDistance(e.attacker:getOrigin()) > 650 then
            return
        end

        self.teammateInTroubleTimer:restart()
    end)


    Callbacks.setupCommand(function()
        if not AiUtility.bombCarrier then
            return
        end

        if AiUtility.bombCarrier:isClient() then
            return
        end

        if self.getToSiteTimer:isStarted() then
            return
        end

        local nearestBombsite = Nodegraph.getClosestBombsite(AiUtility.bombCarrier:getOrigin())

        if AiUtility.bombCarrier:getOrigin():getDistance(nearestBombsite.origin) > 1400 then
            return
        end

        local distance = LocalPlayer:isTerrorist() and 950 or 1500

        if LocalPlayer:getOrigin():getDistance(nearestBombsite.origin) < distance then
            return
        end

        self.getToSiteTimer:start()
    end)
end

--- @return number
function AiStateDefend:assess()
    if AiUtility.enemiesAlive == 0 then
        return AiPriority.IGNORE
    end

    if AiUtility.gamemode == "demolition" or AiUtility.gamemode == "wingman" then
        return self:assessDemolition()
    elseif AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
        return self:assessHostage()
    end

    return AiPriority.IGNORE
end

--- @return number
function AiStateDefend:assessDemolition()
    local bomb = AiUtility.plantedBomb

    if AiUtility.isBombBeingDefusedByEnemy or AiUtility.isBombBeingPlantedByEnemy then
        return AiPriority.IGNORE
    end

    if LocalPlayer:isCounterTerrorist() then
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

        -- We're not near the site.
        -- This will practically force the AI to go to the site.
        if self.getToSiteTimer:isStarted() and not self.getToSiteTimer:isElapsed(12) then
            return AiPriority.DEFEND_EXPEDITE
        end

        if bomb then
            -- Defend our teammate who is defusing.
            if AiUtility.isBombBeingDefusedByTeammate then
                return AiPriority.DEFEND_DEFUSER
            end
        end

        -- We can hold an approaching enemy.
        if self.isOnDefendSpot and self:isEnemyHoldable() then
            return AiPriority.DEFEND_ACTIVE
        end

        -- Basic defend behaviour.
        return AiPriority.DEFEND_GENERIC
    end

    if LocalPlayer:isTerrorist() then
        -- Hold specific angle.
        if bomb and self.isSpecificNodeSet and self:isEnemyHoldable() then
            return AiPriority.DEFEND_EXPEDITE
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

        -- We should probably go to the site.
        if AiUtility.bombCarrier and not AiUtility.bombCarrier:is(LocalPlayer) then
            local bombCarrierOrigin = AiUtility.bombCarrier:getOrigin()
            local bombsite = Nodegraph.getClosestBombsite(bombCarrierOrigin)
            local distance = bombCarrierOrigin:getDistance(bombsite.origin)

            if AiUtility.isBombBeingPlantedByTeammate or distance < 750 then
                return AiPriority.DEFEND_PLANTER
            end

            if distance < 750 then
                return AiPriority.DEFEND_PASSIVE
            end
        end

        -- Basic defend behaviour.
        return AiPriority.DEFEND_GENERIC
    end

    return AiPriority.IGNORE
end

--- @return number
function AiStateDefend:assessHostage()
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

    if AiUtility.isClientThreatenedMajor then
        return false
    end

    local cameraAngles = Client.getCameraAngles()
    local eyeOrigin = Client.getEyeOrigin()
    local clientOrigin = Client.getEyeOrigin()
    local isEnemyInFoV = false
    local isEnemies = false

    for _, enemy in pairs(AiUtility.enemies) do
        isEnemies = true

        local enemyOrigin = enemy:getOrigin()

        if clientOrigin:getDistance(enemyOrigin) < 1000 and cameraAngles:getFov(eyeOrigin, enemyOrigin:offset(0, 0, 64)) < 85 then
            isEnemyInFoV = true

            break
        end
    end

    if not isEnemies then
        return false
    end

    return isEnemyInFoV
end

--- @return void
function AiStateDefend:activate()
    if not self.isSpecificNodeSet then
        self:setActivityNode(self.bombsite)
    end

    if not self.node then
        self:invoke()
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

    if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
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
    self.bombsite = bombsite

    self:queueForReactivation()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDefend:think(cmd)
    if not self.node then
        self:reset()

        return
    end

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

    local distance = AiUtility.clientNodeOrigin:getDistance(self.node.origin)

    if distance < 300 then
        self.isOnDefendSpot = true

        self.ai.routines.manageGear:block()
        self.ai.routines.manageWeaponScope:block()
        self.defendTimer:ifPausedThenStart()

        local nodeVisibleTrace = Trace.getLineToPosition(Client.getEyeOrigin(), self.node.origin, AiUtility.traceOptionsAttacking, "AiStateDefend.think<FindSpotVisible>")

        -- Duck when holding this node.
        if self.isAllowedToDuckAtNode and distance < 32 and self.node.isAllowedToDuck then
            Pathfinder.duck()
        end

        -- Look at the angle we intend to hold.
        if not nodeVisibleTrace.isIntersectingGeometry then
            View.lookAtLocation(self.node.lookAtOrigin, 5.5, View.noise.moving, "Defend look at angle")

            if self.priority ~= AiPriority.DEFEND_DEFUSER and self.priority ~= AiPriority.DEFEND_PLANTER then
                Pathfinder.walk()
            end
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
    if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
        self.activity = "Defending hostages"
    else
        if distance < 750 then
            self.activity = string.format("Defending %s", self.node.bombsite)
        else
            self.activity = string.format("Going %s", self.node.bombsite)
        end
    end

    -- There's a teammate already near this defensive spot. We should hold someplace else.
    if self.priority ~= AiPriority.DEFEND_ACTIVE then
        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(self.node.origin) < 50 then
                self:invoke(self.node.bombsite)
            end
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

    -- Repathfind.
    if not self.isAtDestination and Pathfinder.isIdle() then
        Pathfinder.retryLastRequest()
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

        if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
            class = Node.defendHostageT
        elseif self.priority == AiPriority.DEFEND_PLANTER then
            class = Node.defendBombT
        else
            class = Node.defendSiteT
        end

        self.node = Nodegraph.getRandomForBombsite(class, bombsite)
    end
end

return Nyx.class("AiStateDefend", AiStateDefend, AiStateBase)
--}}}
