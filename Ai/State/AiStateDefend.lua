--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local DrawDebug = require "gamesense/Nyx/v1/Api/DrawDebug"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
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
--- @field bombAtBombsiteName string
--- @field isAllowedToDuckAtNode boolean
--- @field bombsite string
--- @field defendTime number
--- @field defendTimer Timer
--- @field isWeaponEquipped boolean
--- @field getToSiteTimer Timer
--- @field isAtDestination boolean
--- @field isDefending boolean
--- @field isDefendingDefuser boolean
--- @field isJiggling boolean
--- @field isJigglingUponReachingSpot boolean
--- @field isOnDefendSpot boolean
--- @field jiggleDirection string
--- @field jiggleTime number
--- @field jiggleTimer Timer
--- @field node NodeTypeDefend
local AiStateDefend = {
    name = "Defend"
}

--- @param fields AiStateDefend
--- @return AiStateDefend
function AiStateDefend:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDefend:__init()
    self.defendTimer = Timer:new()
    self.defendTime = Client.getRandomFloat(2, 6)
    self.jiggleTimer = Timer:new():start()
    self.jiggleTime = Client.getRandomFloat(0.25, 0.5)
    self.jiggleDirection = "Left"
    self.getToSiteTimer = Timer:new()

    Callbacks.init(function()
        self.bombsite = Client.getRandomInt(1, 2) == 1 and "A" or "B"
    end)

    Callbacks.roundStart(function()
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
        local site = (operand % 2) == 0 and "A" or "B"

        self.bombsite = site
    end)

    Callbacks.roundEnd(function()
        self:reset()
    end)

    Callbacks.bombPlanted(function()
    	Client.fireAfter(1, function()
            if AiUtility.plantedBomb and LocalPlayer.origin:getDistance(AiUtility.plantedBomb:m_vecOrigin()) > 1000 then
                self.getToSiteTimer:start()
            end
    	end)
    end)
end

--- @return number
function AiStateDefend:assess()
    if AiUtility.enemiesAlive == 0 then
        return AiPriority.IGNORE
    end

    if AiUtility.gamemode == "demolition" or AiUtility.gamemode == "wingman" then
        return self:assessDemolition()
    elseif AiUtility.gamemode == "hostage" then
        return self:assessHostage()
    end

    return AiPriority.IGNORE
end

--- @return number
function AiStateDefend:assessDemolition()
    local bomb = AiUtility.plantedBomb

    if LocalPlayer:isCounterTerrorist() then
        if bomb then
            self.bombsite = Nodegraph.getClosestBombsiteName(bomb:m_vecOrigin())

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
            local bombsite = Nodegraph.getClosestBombsiteName(bombCarrierOrigin)

            if bombCarrierOrigin:getDistance(bombsite.origin) < 750 then
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
    self.node = nil

    self.defendTimer:stop()
end

--- @return boolean
function AiStateDefend:isEnemyHoldable()
    if AiUtility.isBombBeingPlantedByEnemy then
        return false
    end

    local cameraAngles = Client.getCameraAngles()
    local eyeOrigin = Client.getEyeOrigin()
    local isEnemyInFoV = false

    for _, enemy in pairs(AiUtility.enemies) do
        if cameraAngles:getFov(eyeOrigin, enemy:getOrigin():offset(0, 0, 64)) < 85 then
            isEnemyInFoV = true

            break
        end
    end

    return isEnemyInFoV
end

--- @param site string
--- @param swapPair boolean
--- @return void
function AiStateDefend:activate(site, swapPair)
    local bomb = AiUtility.plantedBomb

    if bomb then
        site = Nodegraph.getClosestBombsiteName(bomb:m_vecOrigin())
    end

    --- @type NodeTypeDefend
    local node

    if swapPair and self.node then
        node = self.node.pair
    else
        node = self:getActivityNode(site)
    end

    if not node then
        return
    end

    self.node = node
    self.isDefending = false
    self.isAtDestination = false
    self.isOnDefendSpot = false
    self.isJiggling = false
    self.isFirstJiggle = true
    self.isAllowedToDuckAtNode = Client.getChance(2)

    self.defendTimer:stop()
    self.jiggleTimer:stop()

    local task

    if AiUtility.gamemode == "hostage" then
        task = "Defending hostages"
    else
        task = string.format("Defending %s site", self.node.bombsite:upper())
    end

    Pathfinder.moveToNode(self.node, {
        task = task,
        isCounterStrafingOnGoal = true,
        goalReachedRadius = 8,
    })
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDefend:think(cmd)
    if not self.node then
        return
    end

    local distance = AiUtility.clientNodeOrigin:getDistance(self.node.origin)

    -- Set activity string.
    if AiUtility.gamemode == "hostage" then
        self.activity = "Defending hostages"
    else
        if distance < 750 then
            self.activity = string.format("Going %s", self.bombsite:upper())
        else
            self.activity = string.format("Defending %s", self.bombsite:upper())
        end
    end

    -- There's a teammate already near this defensive spot. We should hold someplace else.
    if self.ai.priority ~= AiPriority.DEFEND_ACTIVE then
        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(self.node.origin) < 50 then
                self:activate(self.bombsite)
            end
        end
    end

    -- Restart defend procedure somewhere else.
    -- Don't do this if we're defending against a specific threat.
    if self.ai.priority ~= AiPriority.DEFEND_ACTIVE and self.defendTimer:isElapsedThenStop(self.defendTime) then
        self.defendTime = Client.getRandomFloat(3, 8)
        self.isJigglingUponReachingSpot = Client.getChance(0.75)
        self.isJiggling = false

        -- Move to another spot on the site.
        if Client.getChance(15) then
            self:activate(self.bombsite, false)
        else
            self:activate(self.bombsite, true)
        end
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

    if distance < 300 then
        self.isOnDefendSpot = true
        self.ai.canUseKnife = false

        self.defendTimer:ifPausedThenStart()

        local nodeVisibleTrace = Trace.getLineToPosition(Client.getEyeOrigin(), self.node.origin, AiUtility.traceOptionsAttacking, "AiStateDefend.think<FindSpotVisible>")

        -- Duck when holding this node.
        if self.isAllowedToDuckAtNode and distance < 32 and self.node.isAllowedToDuck then
            cmd.in_duck = true
        end

        -- Look at the angle we intend to hold.
        if not nodeVisibleTrace.isIntersectingGeometry then
            View.lookAtLocation(self.node.lookAtOrigin, 6.5, View.noise.moving, "Defend look at angle")

            self.ai.isWalking = true
        end

        -- Equip the correct gear.
        if not LocalPlayer:isHoldingGun() then
            if LocalPlayer:hasPrimary() then
                Client.equipPrimary()
            else
                Client.equipPistol()
            end
        end

        self.ai.canUnscope = false
    else
        self.isOnDefendSpot = false
        self.isJiggling = false
        self.isJigglingUponReachingSpot = false

        if LocalPlayer:isHoldingSniper() then
            Client.unscope()
        end

        self.defendTimer:stop()
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
            Client.scope()
        end
    end
end

--- @param bombsite string|NodeTypeDefend
--- @return NodeTypeDefend
function AiStateDefend:getActivityNode(bombsite)
    bombsite = bombsite or self.bombsite

    if LocalPlayer:isCounterTerrorist() then
        local class

        if AiUtility.isBombBeingDefusedByTeammate then
            class = Node.defendBombCt
        else
            class = Node.defendSiteCt
        end

        return Nodegraph.getRandomForBombsite(class, bombsite)
    elseif LocalPlayer:isTerrorist() then
        local class

        if AiUtility.gamemode == "hostage" then
            class = Node.defendHostageT
        elseif AiUtility.isBombBeingPlantedByTeammate then
            class = Node.defendBombT
        else
            class = Node.defendSiteT
        end

        return Nodegraph.getRandomForBombsite(class, bombsite)
    end
end

return Nyx.class("AiStateDefend", AiStateDefend, AiStateBase)
--}}}
