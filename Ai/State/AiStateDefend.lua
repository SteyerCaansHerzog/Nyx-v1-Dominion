--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Voice = require "gamesense/Nyx/v1/Api/Voice"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateDefend
--- @class AiStateDefend : AiState
--- @field bombCarrier Player
--- @field bombNearSite string
--- @field defendingSite string
--- @field defendTime number
--- @field defendTimer Timer
--- @field equippedGun boolean
--- @field isDefending boolean
--- @field isDefendingBomb boolean
--- @field isDefendingDefuser boolean
--- @field isJiggling boolean
--- @field isJigglingUponReachingSpot boolean
--- @field jiggleDirection string
--- @field jiggleTime number
--- @field jiggleTimer Timer
--- @field node Node
--- @field reachedDestination boolean
--- @field sectorClearTimer Timer
--- @field speakCooldownTimer Timer
--- @field getToSiteTimer Timer
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
    self.speakCooldownTimer = Timer:new(30):startThenElapse()
    self.jiggleTimer = Timer:new():start()
    self.jiggleTime = 0.66
    self.jiggleDirection = "Left"
    self.getToSiteTimer = Timer:new()

    Callbacks.init(function()
        self.defendingSite = Client.getRandomInt(1, 2) == 1 and "a" or "b"
    end)

    Callbacks.roundPrestart(function()
        self.getToSiteTimer:stop()

        self.defendingSite = Client.getRandomInt(1, 2) == 1 and "a" or "b"
    end)

    Callbacks.roundEnd(function()
        self.speakCooldownTimer:startThenElapse()
        self.isDefending = false
        self.isDefendingBomb = false
        self.isDefendingDefuser = false
        self.node = nil
    end)

    Callbacks.itemPickup(function(e)
        if not e.item == "c4" then
            return
        end

        self.bombCarrier = e.player
    end)

    Callbacks.bombPlanted(function()
    	Client.fireAfter(1, function()
            if AiUtility.plantedBomb and AiUtility.client:getOrigin():getDistance(AiUtility.plantedBomb:m_vecOrigin()) > 1000 then
                self.getToSiteTimer:start()
            end
    	end)
    end)
end

--- @param nodegraph Nodegraph
--- @return number
function AiStateDefend:assess(nodegraph)
    -- No point saving if there are no enemies to save from.
    if AiUtility.enemiesAlive == 0 then
        return AiState.priority.IGNORE
    end

    local player = AiUtility.client
    local bomb = AiUtility.plantedBomb

    if player:isCounterTerrorist() then
        if bomb then
            self.defendingSite = nodegraph:getNearestSiteName(bomb:m_vecOrigin())

            if AiUtility.isBombBeingDefusedByTeammate then
                self.isDefendingDefuser = true

                return AiState.priority.DEFEND_DEFUSER
            end
        end

        return AiState.priority.DEFEND
    end

    if player:isTerrorist() then
        -- We're not near the site.
        -- This will practically force the AI to go to the site.
        if self.getToSiteTimer:isStarted() and not self.getToSiteTimer:isElapsed(12) then
            return AiState.priority.DEFEND_EXPEDITE
        end

        -- We should probably go to the site.
        if AiUtility.bombCarrier and not AiUtility.bombCarrier:is(AiUtility.client) then
            local bombCarrierOrigin = AiUtility.bombCarrier:getOrigin()
            local bombsite = nodegraph:getNearestSiteNode(bombCarrierOrigin)

            if bombCarrierOrigin:getDistance(bombsite.origin) < 750 then
                return AiState.priority.DEFEND_ACTIVE
            end
        end

        return AiState.priority.DEFEND
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @param site string
--- @param swapPair boolean
--- @return void
function AiStateDefend:activate(ai, site, swapPair, useClosestSite)
    local bomb = AiUtility.plantedBomb

    if bomb then
        site = ai.nodegraph:getNearestSiteName(bomb:m_vecOrigin())
    elseif useClosestSite then
        site = ai.nodegraph:getNearestSiteName(AiUtility.client:getOrigin())
    end

    --- @type Node
    local node

    if swapPair then
        node = self.node.pair
    else
        node = self:getActivityNode(ai, site)
    end

    if not node then
        return
    end

    self.node = node
    self.reachedDestination = false

    ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid(),
        task = string.format("Defending %s site", node.site:upper()),
        onComplete = function()
            self.reachedDestination = true
            self.isDefending = true

            ai.nodegraph:log("Defending %s site", node.site)
        end
    })

    if self.speakCooldownTimer:isElapsedThenRestart(self.speakCooldownTimer.time) then
        local player = AiUtility.client
        local playerOrigin = player:getOrigin()
        local color = node.site == "a" and ai.radio.color.BLUE or ai.radio.color.PURPLE

        local text

        if playerOrigin:getDistance(node.origin) < 1024 then
            text = "I'm %sdefending %sbombsite %s%s."
        else
            text = "I'm going to %sdefend %sbombsite %s%s."
        end

        ai.radio:speak(ai.radio.message.SPREAD_OUT, 1, 1, 2, text, ai.radio.color.YELLOW, color, node.site:upper(), ai.radio.color.DEFAULT)
    end
end

--- @return void
function AiStateDefend:deactivate() end

--- @param ai AiOptions
--- @return void
function AiStateDefend:think(ai)
    if not self.node then
        return
    end

    local player = AiUtility.client
    local distance = player:getOrigin():offset(0, 0, 18):getDistance(self.node.origin)

    if distance < 256 then
        ai.controller.canUseKnife = false
    else
        self.isJigglingUponReachingSpot = false
        self.isJiggling = false
    end

    local bomb = AiUtility.plantedBomb

    if bomb and not self.isDefendingBomb then
        self:activate(ai, ai.nodegraph:getNearestSiteName(bomb:m_vecOrigin()))

        self.isDefendingBomb = true

        return
    end

    if not self.reachedDestination and not ai.nodegraph.path and ai.nodegraph:canPathfind() then
        self:activate(ai, self.defendingSite)
    end

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():getDistance(self.node.origin) < 32 and ai.nodegraph:canPathfind() then
            self:activate(ai, self.defendingSite)

            return
        end
    end

    if not self.isJigglingUponReachingSpot and distance > 16 and distance < 64 then
        ai.nodegraph.moveAngle = player:getOrigin():getAngle(self.node.origin)
    end

    if distance < 32 then
        ai.view.isCrosshairFloating = false

        if self.defendTimer:isElapsedThenRestart(self.defendTime) then
            self.defendTime = Client.getRandomFloat(3, 6)

            if Client.getChance(4) then
                self:activate(ai, nil, false, true)

                self.isJigglingUponReachingSpot = false
                self.isJiggling = false

                return
            else
                self:activate(ai, nil,true)

                self.isJigglingUponReachingSpot = Client.getChance(2)
                self.isJiggling = false

                return
            end
        end

        if player:isHoldingSniper() then
            Client.scope()
        end
    end

    if distance < 256 then
        local lookOrigin = self.node.origin:clone():offset(0, 0, 46)
        local lookDirectionTrace = Trace.getLineAtAngle(lookOrigin, self.node.direction, AiUtility.traceOptionsPathfinding)
        local nodeVisibleTrace = Trace.getLineToPosition(Client.getEyeOrigin(), self.node.origin, AiUtility.traceOptionsAttacking)

        self.defendTimer:ifPausedThenStart()

        if not nodeVisibleTrace.isIntersectingGeometry then
            ai.view:lookAtLocation(lookDirectionTrace.endPosition, 4)

            ai.controller.isWalking = true
        end

        if not player:isHoldingGun() then
            Client.equipAnyWeapon()
        end

        ai.controller.canUnscope = false
    else
        if player:m_bIsScoped() == 1 then
            Client.unscope()
        end

        self.defendTimer:stop()
    end

    if self.isJigglingUponReachingSpot then
        if distance < 8 then
            self.isJiggling = true
        end

        if self.isJiggling then
            if self.jiggleTimer:isElapsedThenRestart(self.jiggleTime) then
                self.jiggleDirection = self.jiggleDirection == "Left" and "Right" or "Left"
            end

            --- @type Vector3
            local direction = self.node.direction[string.format("get%s", self.jiggleDirection)](self.node.direction)

            ai.nodegraph.moveAngle = direction:getAngleFromForward()
        end
    end
end

--- @param ai AiOptions
--- @param site string|Node
--- @return Node
function AiStateDefend:getActivityNode(ai, site)
    local team = AiUtility.client:m_iTeam()

    if not site then
        site = self.defendingSite
    end

    local nodes

    if self.isDefendingDefuser then
        local defendNodes = {
            a = ai.nodegraph.objectiveADefendDefuser,
            b = ai.nodegraph.objectiveBDefendDefuser
        }

        nodes = defendNodes[site]
    else
        local defendNodes = {
            [2] = {
                a = ai.nodegraph.objectiveAHold,
                b = ai.nodegraph.objectiveBHold,
            },
            [3] = {
                a = ai.nodegraph.objectiveADefend,
                b = ai.nodegraph.objectiveBDefend
            }
        }

        nodes = defendNodes[team][site]
    end

    --- @type Node
    local node = {}

    while node and not node.active do
        node = nodes[Client.getRandomInt(1, #nodes)]
    end

    return node
end

return Nyx.class("AiStateDefend", AiStateDefend, AiState)
--}}}
