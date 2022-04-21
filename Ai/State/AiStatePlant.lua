--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStatePlant
--- @class AiStatePlant : AiState
--- @field node Node
--- @field plantAt string
--- @field plantDelayTimer Timer
--- @field plantDelayTime number
--- @field mustPathfind boolean
--- @field isPlanting boolean
--- @field tellSiteTimer Timer
--- @field pickRandomSiteTimer Timer
local AiStatePlant = {
    name = "Plant"
}

--- @param fields AiStatePlant
--- @return AiStatePlant
function AiStatePlant:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePlant:__init()
    self.plantDelayTimer = Timer:new()
    self.plantDelayTime = 0.33
    self.tellSiteTimer = Timer:new():startThenElapse()
    self.pickRandomSiteTimer = Timer:new()

    Callbacks.init(function()
        self:setSite()
    end)

    Callbacks.roundEnd(function()
        self:setSite()
    end)

    Callbacks.roundStart(function()
        self.isPlanting = false

        self.pickRandomSiteTimer:start()
    end)

    Callbacks.bombBeginPlant(function(e)
        if not e.player:isClient() then
            return
        end

        self.isPlanting = true
    end)

    Callbacks.bombAbortPlant(function(e)
        if not e.player:isClient() then
            return
        end

        self.isPlanting = false
    end)
end

--- @return void
function AiStatePlant:setSite()
    self.plantAt = Client.getRandomInt(1, 2) == 1 and "a" or "b"
end

--- @param nodegraph Nodegraph
--- @return void
function AiStatePlant:assess(nodegraph)
    if not Client.hasBomb() then
        return AiState.priority.IGNORE
    end

    local player = AiUtility.client
    local playerOrigin = player:getOrigin()
    local siteName = nodegraph:getNearestSiteName(playerOrigin)
    local site = nodegraph:getSiteNode(siteName)
    local closestPlantNode = nodegraph:getClosestNodeOf(playerOrigin, Node.types.PLANT)
    local isCovered = false
    local distanceToSite = playerOrigin:getDistance(site.origin)
    local isOnSite = distanceToSite < 750
    local isNearSite = distanceToSite < 1400
    local isOnPlant = playerOrigin:getDistance(closestPlantNode.origin) < 200

    for _, teammate in pairs(AiUtility.teammates) do
        local teammateOrigin = teammate:getOrigin()

        local distance = 500

        if playerOrigin:getDistance(teammateOrigin) < distance then
            isCovered = true

            break
        end
    end

    -- On plant-spot and covered.
    if isOnPlant and isCovered then
        return AiState.priority.PLANT_COVERED
    end

    -- Not much time left in the round.
    if AiUtility.timeData.roundtime_remaining < 35 then
        return AiState.priority.PLANT_EXPEDITE
    end

    -- Near site and covered.
    if isNearSite and isCovered then
        return AiState.priority.PLANT_ACTIVE
    end

    -- Near site and not threatened.
    if isNearSite and not AiUtility.isClientThreatened then
        return AiState.priority.PLANT_ACTIVE
    end

    -- Covered and not threatened.
    if isCovered and not AiUtility.isClientThreatened then
        return AiState.priority.PLANT_PASSIVE
    end

    -- We have the bomb.
    return AiState.priority.PLANT_GENERIC
end

--- @param ai AiOptions
--- @param site string
--- @return void
function AiStatePlant:activate(ai, site)
    local player = AiUtility.client
    local origin = player:getOrigin()

    if site then
        self.plantAt = site
    end

    if origin:getDistance(ai.nodegraph.objectiveA.origin) < 1024 then
        site = "a"
    elseif origin:getDistance(ai.nodegraph.objectiveB.origin) < 1024 then
        site = "b"
    end

    local node = self:getPlantNode(ai.nodegraph, site)

    if not node then
        return
    end

    self.node = node
    self.mustPathfind = true

    self.plantDelayTimer:stop()

    ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid(),
        task = string.format("Plant on %s site [%i]", node.site:upper(), node.id),
        onComplete = function()
            ai.nodegraph:log("Planting on %s site [%i]", node.site:upper(), node.id)
            self.plantDelayTimer:ifPausedThenStart()

            self.mustPathfind = false
        end
    })

    if self.tellSiteTimer:isElapsedThenRestart(25) and Menu.useChatCommands:get() then
        Messenger.send(string.format(" go %s", self.plantAt), true)

        local color = self.plantAt == "a" and ai.radio.color.BLUE or ai.radio.color.PURPLE

        ai.radio:speak(ai.radio.message.FOLLOW_ME, 1, 0.5, 1, "I'm %staking%s the %sbomb%s to %sbombsite %s%s.", ai.radio.color.YELLOW, ai.radio.color.DEFAULT, ai.radio.color.GOLD, ai.radio.color.DEFAULT, color, self.plantAt:upper(), ai.radio.color.DEFAULT)

        local distanceToSite = origin:getDistance(ai.nodegraph:getNearestSiteNode(origin).origin)

        if not AiUtility.isLastAlive and distanceToSite > 800 then
            ai.voice.pack:speakRequestTeammatesToPush(self.plantAt)
        end
    end
end

--- @param ai AiOptions
--- @return void
function AiStatePlant:think(ai)
    self.activity = "Going to plant bomb"

    if not self.node then
        self:activate(ai)
    end

    local player = AiUtility.client
    local distance = player:getOrigin():getDistance(self.node.origin)

    if distance < 20 then
        ai.cmd.in_duck = 1
    end

    if distance < 72 then
        ai.view:lookInDirection(self.node.direction, 5, ai.view.noiseType.IDLE, "Plant look at angle")
        ai.controller.isQuickStopping = true
    end

    if distance < 100 then
        self.activity = "Planting bomb"

        ai.controller.canUseGear = false

        Client.equipBomb()
    end

    if self.isPlanting then
        ai.cmd.in_use = 1
    elseif self.plantDelayTimer:isElapsed(self.plantDelayTime) then
        ai.cmd.in_use = 1
    end

    if not ai.nodegraph.path and ai.nodegraph:canPathfind() and self.mustPathfind then
        self:activate(ai)
    end
end

--- @param nodegraph Nodegraph
--- @param site string
--- @return Node
function AiStatePlant:getPlantNode(nodegraph, site)
    local sites = {
        a = nodegraph.objectiveAPlant,
        b = nodegraph.objectiveBPlant
    }

    if site then
        self.plantAt = site

        return sites[site][1]
    else
        return sites[self.plantAt][1]
    end
end

return Nyx.class("AiStatePlant", AiStatePlant, AiState)
--}}}
