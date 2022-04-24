--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
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

--- @return void
function AiStatePlant:assess()
    if not Client.hasBomb() then
        return AiPriority.IGNORE
    end

    local player = AiUtility.client
    local playerOrigin = player:getOrigin()
    local siteName = self.ai.nodegraph:getNearestSiteName(playerOrigin)
    local site = self.ai.nodegraph:getSiteNode(siteName)
    local closestPlantNode = self.ai.nodegraph:getClosestNodeOf(playerOrigin, Node.types.PLANT)
    local isCovered = false
    local distanceToSite = playerOrigin:getDistance(site.origin)
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
        return AiPriority.PLANT_COVERED
    end

    -- Not much time left in the round.
    if AiUtility.timeData.roundtime_remaining < 35 then
        return AiPriority.PLANT_EXPEDITE
    end

    -- We already begun planting.
    if self.isPlanting then
        return AiPriority.PLANT_EXPEDITE
    end

    -- Near site and covered.
    if isNearSite and isCovered then
        return AiPriority.PLANT_ACTIVE
    end

    -- Near site and not threatened.
    if isNearSite and not AiUtility.isClientThreatened then
        return AiPriority.PLANT_ACTIVE
    end

    -- Covered and not threatened.
    if isCovered and not AiUtility.isClientThreatened then
        return AiPriority.PLANT_PASSIVE
    end

    -- We have the bomb.
    return AiPriority.PLANT_GENERIC
end

--- @param site string
--- @return void
function AiStatePlant:activate(site)
    local player = AiUtility.client
    local origin = player:getOrigin()

    if site then
        self.plantAt = site
    end

    if origin:getDistance(self.ai.nodegraph.objectiveA.origin) < 1024 then
        site = "a"
    elseif origin:getDistance(self.ai.nodegraph.objectiveB.origin) < 1024 then
        site = "b"
    end

    local node = self:getPlantNode(site)

    if not node then
        return
    end

    self.node = node
    self.mustPathfind = true

   self.ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        task = string.format("Plant on %s site [%i]", node.site:upper(), node.id),
        onComplete = function()
            self.mustPathfind = false
        end
    })

    if self.tellSiteTimer:isElapsedThenRestart(25) and Menu.useChatCommands:get() then
        self.ai.commands.go:bark(self.plantAt)

        local distanceToSite = origin:getDistance(self.ai.nodegraph:getNearestSiteNode(origin).origin)

        if not AiUtility.isLastAlive and distanceToSite > 800 then
           self.ai.voice.pack:speakRequestTeammatesToPush(self.plantAt)
        end
    end
end

--- @return void
function AiStatePlant:deactivate()
    self.plantDelayTimer:stop()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePlant:think(cmd)
    self.activity = "Going to plant bomb"

    if not self.node then
        self:activate()
    end

    local player = AiUtility.client
    local distance = player:getOrigin():getDistance2(self.node.origin)

    if distance < 250 then
        self.activity = "Planting bomb"

        self.ai.canUseGear = false

        Client.equipBomb()
    end

    if distance < 72 then
        self.ai.view:lookInDirection(self.node.direction, 5, self.ai.view.noiseType.IDLE, "Plant look at angle")
        self.ai.isQuickStopping = true
    end

    if distance < 20 then
        cmd.in_duck = 1

        if player:isAbleToAttack() then
            self.plantDelayTimer:ifPausedThenStart()

            if self.plantDelayTimer:isElapsed(self.plantDelayTime) then
                cmd.in_use = 1
            end
        end
    end

    if self.ai.nodegraph:isIdle() and self.mustPathfind then
        self:activate()
    end
end

--- @param site string
--- @return Node
function AiStatePlant:getPlantNode(site)
    local sites = {
        a = self.ai.nodegraph.objectiveAPlant,
        b = self.ai.nodegraph.objectiveBPlant
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
