--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
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
            if AiUtility.plantedBomb and AiUtility.client:getOrigin():getDistance(AiUtility.plantedBomb:m_vecOrigin()) > 1000 then
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
    local player = AiUtility.client
    local bomb = AiUtility.plantedBomb

    if player:isCounterTerrorist() then
        if bomb then
            self.bombsite = self.ai.nodegraph:getNearestSiteName(bomb:m_vecOrigin())

            -- Defend our teammate who is defusing.
            if AiUtility.isBombBeingDefusedByTeammate then
                self.isDefendingDefuser = true

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

    if player:isTerrorist() then
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
        if AiUtility.bombCarrier and not AiUtility.bombCarrier:is(AiUtility.client) then
            local bombCarrierOrigin = AiUtility.bombCarrier:getOrigin()
            local bombsite = self.ai.nodegraph:getNearestSiteNode(bombCarrierOrigin)

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
    local player = AiUtility.client

    if player:isTerrorist() then
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
    self.isDefendingDefuser = false
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
        site = self.ai.nodegraph:getNearestSiteName(bomb:m_vecOrigin())
    end

    --- @type Node
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
    self.isDefendingDefuser = false
    self.isAtDestination = false
    self.isOnDefendSpot = false
    self.isJiggling = false
    self.isAllowedToDuckAtNode = Client.getChance(2)

    self.defendTimer:stop()
    self.jiggleTimer:stop()

    local task

    if AiUtility.gamemode == "hostage" then
        task = "Defending hostages"
    else
        task = string.format("Defending %s site", self.node.site:upper())
    end

    self.ai.nodegraph:pathfind(self.node.origin, {
        objective = Node.types.GOAL,
        task = task
    })
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDefend:think(cmd)
    if not self.node then
        return
    end

    local distance = AiUtility.client:getOrigin():offset(0, 0, 18):getDistance(self.node.origin)

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
    if self.ai.priority ~= AiPriority.DEFEND_ACTIVE and self.defendTimer:isElapsedThenStop(self.defendTime) then
        self.defendTime = Client.getRandomFloat(3, 8)
        self.isJigglingUponReachingSpot = Client.getChance(2)
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
            self.jiggleTimer:ifPausedThenStart()

            if self.jiggleTimer:isElapsedThenRestart(self.jiggleTime) then
                self.jiggleDirection = self.jiggleDirection == "Left" and "Right" or "Left"
            end

            --- @type Vector3
            local direction = self.node.direction[string.format("get%s", self.jiggleDirection)](self.node.direction)

            self.ai.nodegraph.moveAngle = direction:getAngleFromForward()
        end
    end

    if distance < 300 then
        self.isOnDefendSpot = true
        self.ai.canUseKnife = false

        self.defendTimer:ifPausedThenStart()

        local lookOrigin = self.node.origin:clone():offset(0, 0, 46)
        local lookDirectionTrace = Trace.getLineAtAngle(lookOrigin, self.node.direction, AiUtility.traceOptionsPathfinding, "AiStateDefend.think<FindLookAngle>")
        local nodeVisibleTrace = Trace.getLineToPosition(Client.getEyeOrigin(), self.node.origin, AiUtility.traceOptionsAttacking, "AiStateDefend.think<FindSpotVisible>")

        -- Duck when holding this node.
        if self.isAllowedToDuckAtNode and distance < 32 then
            local duckTrace = Trace.getLineToPosition(self.node.origin:clone():offset(0, 0, 28), lookDirectionTrace.endPosition, AiUtility.traceOptionsAttacking, "AiStateDefend.think<FindCanDuck>")

            if not duckTrace.isIntersectingGeometry then
                cmd.in_duck = true
            end
        end

        -- Look at the angle we intend to hold.
        if not nodeVisibleTrace.isIntersectingGeometry then
            View.lookAtLocation(lookDirectionTrace.endPosition, 4, View.noise.moving, "Defend look at angle")

            self.ai.isWalking = true
        end

        -- Equip the correct gear.
        if not AiUtility.client:isHoldingGun() then
            if AiUtility.client:hasPrimary() then
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

        if AiUtility.client:isHoldingSniper() then
            Client.unscope()
        end

        self.defendTimer:stop()
    end

    -- Repathfind.
    if not self.isAtDestination and self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:rePathfind()
    end

    -- Reached destination.
    if distance < 30 then
        self.isAtDestination = true
        self.isDefending = true

        if AiUtility.client:isHoldingSniper() then
            Client.scope()
        end
    end
end

--- @param site string|Node
--- @return Node
function AiStateDefend:getActivityNode(site)
    local team = AiUtility.client:m_iTeamNum()

    if AiUtility.gamemode == "hostage" then
        return Nodegraph.getRandom(Node.defendHostageT)
    end

    if not site then
        site = self.bombsite
    end

    local nodes

    if self.isDefendingDefuser then
        local defendNodes = {
            A = Nodegraph.getForBombsite(Node.defendBombCt, "A"),
            B = Nodegraph.getForBombsite(Node.defendBombCt, "B"),
        }

        nodes = defendNodes[site]
    else
        local defendNodes = {
            [2] = {
                A = Nodegraph.getForBombsite(Node.defendSiteT, "A"),
                B = Nodegraph.getForBombsite(Node.defendSiteT, "B"),
            },
            [3] = {
                A = Nodegraph.getForBombsite(Node.defendSiteCt, "A"),
                B = Nodegraph.getForBombsite(Node.defendSiteCt, "B"),
            }
        }

        nodes = defendNodes[team][site]
    end

    --- @type Node
    local node = {}

    while node and not node.active do
        node = Table.getRandom(nodes)
    end

    return node
end

return Nyx.class("AiStateDefend", AiStateDefend, AiStateBase)
--}}}
