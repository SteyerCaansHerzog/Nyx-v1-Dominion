--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
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
    self.tellSiteTimer = Timer:new():startAndElapse()
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

    local player = Player.getClient()
    local playerOrigin = player:getOrigin()
    local siteName = nodegraph:getNearestBombSite(playerOrigin)
    local site = nodegraph:getSiteNode(siteName)
    local closestPlantNode = nodegraph:getClosestNodeOf(playerOrigin, Node.types.PLANT)
    local isCovered = false
    local isOnSite = playerOrigin:getDistance(site.origin) < 512
    local isOnPlant = playerOrigin:getDistance(closestPlantNode.origin) < 64

    if isOnSite then
        for _, teammate in pairs(AiUtility.teammates) do
            local teammateOrigin = teammate:getOrigin()

            local distance = isOnSite and 512 or 256

            if playerOrigin:getDistance(teammateOrigin) < distance then
                isCovered = true

                break
            end
        end
    end

    if isOnPlant and isCovered then
        return AiState.priority.PLANT_COVERED
    elseif isOnSite and isCovered then
        return AiState.priority.PLANT_COVERED
    end

    if playerOrigin:getDistance(site.origin) < 1024 then
        return AiState.priority.PLANT_IGNORE_NADES
    end

    return AiState.priority.PLANT_PASSIVE
end

--- @param ai AiOptions
--- @param site string
--- @return void
function AiStatePlant:activate(ai, site)
    local player = Player.getClient()
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
            self.plantDelayTimer:startIfPaused()

            self.mustPathfind = false
        end
    })

    if self.tellSiteTimer:isElapsedThenRestart(25) and Menu.useChatCommands:get() then
        Messenger.send(string.format("/go %s", self.plantAt), true)

        local color = self.plantAt == "a" and ai.radio.color.BLUE or ai.radio.color.PURPLE

        ai.radio:speak(ai.radio.message.FOLLOW_ME, 1, 0.5, 1, "I'm %staking%s the %sbomb%s to %sbombsite %s%s.", ai.radio.color.YELLOW, ai.radio.color.DEFAULT, ai.radio.color.GOLD, ai.radio.color.DEFAULT, color, self.plantAt:upper(), ai.radio.color.DEFAULT)
    end
end

--- @param ai AiOptions
--- @return void
function AiStatePlant:think(ai)
    if not self.node then
        self:activate(ai)
    end

    local player = Player.getClient()

    if player:getOrigin():getDistance(self.node.origin) < 80 then
        ai.controller.canUseKnife = false

        if not player:isHoldingWeapon(Weapons.C4) then
            Client.equipBomb()
        end
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
