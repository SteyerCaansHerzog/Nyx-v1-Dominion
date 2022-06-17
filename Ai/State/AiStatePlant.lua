--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStatePlant
--- @class AiStatePlant : AiStateBase
--- @field node NodeSpotPlant
--- @field bombsite string
--- @field plantDelayTimer Timer
--- @field plantDelayTime number
--- @field isPlanting boolean
--- @field tellSiteTimer Timer
--- @field pickRandomSiteTimer Timer
local AiStatePlant = {
    name = "Plant",
    requiredNodes = {
        Node.spotPlant
    },
    requiredGamemodes = {
        AiUtility.gamemodes.DEMOLITION,
        AiUtility.gamemodes.WINGMAN,
    }
}

--- @param fields AiStatePlant
--- @return AiStatePlant
function AiStatePlant:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePlant:__init()
    self.plantDelayTimer = Timer:new()
    self.plantDelayTime = 0.2
    self.tellSiteTimer = Timer:new():startThenElapse()
    self.pickRandomSiteTimer = Timer:new()

    Callbacks.roundStart(function()
        self.isPlanting = false

        self.pickRandomSiteTimer:start()
        self.tellSiteTimer:elapse()
        self:setPlantNode(AiUtility.randomBombsite)
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
function AiStatePlant:assess()
    if AiUtility.gameRules:m_bFreezePeriod() == 1 then
        return AiPriority.IGNORE
    end

    if not LocalPlayer.hasBomb() then
        return AiPriority.IGNORE
    end

    local clientOrigin = LocalPlayer:getOrigin()
    local bombsite = Nodegraph.getClosestBombsite(clientOrigin)
    local closestPlantNode = Nodegraph.getClosest(clientOrigin, Node.spotPlant)
    local isCovered = false
    local distanceToSite = clientOrigin:getDistance(bombsite.origin)
    local isNearSite = distanceToSite < 1400
    local isOnPlant = clientOrigin:getDistance(closestPlantNode.origin) < 200

    if AiUtility.closestTeammate and AiUtility.closestTeammateDistance < 400 then
        isCovered = true
    end

    -- Do not try to plant if the enemy is in top of us.
    if AiUtility.closestEnemy and AiUtility.closestEnemyDistance < 400 then
        return AiPriority.IGNORE
    end

    -- On plant-spot and covered.
    if isOnPlant and isCovered then
        return AiPriority.PLANT_COVERED
    end

    -- Not much time left in the round.
    if AiUtility.timeData.roundtime_remaining < 20 then
        return AiPriority.PLANT_EXPEDITE
    end

    -- We already begun planting.
    if self.isPlanting then
        return AiPriority.PLANT_EXPEDITE
    end

    -- Near site and covered.
    if isNearSite then
        return AiPriority.PLANT_ACTIVE
    end

    -- Near site and not threatened.
    if isNearSite and not AiUtility.isClientThreatenedMinor then
        return AiPriority.PLANT_PASSIVE
    end

    -- Covered and not threatened.
    if isCovered and not AiUtility.isClientThreatenedMajor then
        return AiPriority.PLANT_PASSIVE
    end

    -- We have the bomb.
    return AiPriority.PLANT_GENERIC
end

--- @return void
function AiStatePlant:activate()
    self:setPlantNode(self.bombsite)

    local origin = LocalPlayer:getOrigin()

    Pathfinder.moveToNode(self.node, {
        task = string.format("Plant the bomb at bombsite %s", self.bombsite),
        isCounterStrafingOnGoal = true
    })

    if self.tellSiteTimer:isElapsedThenRestart(25) and MenuGroup.useChatCommands:get() then
        self.ai.commands.go:bark(self.bombsite:lower())

        local distanceToSite = origin:getDistance(Nodegraph.getClosestBombsite(origin).origin)

        Client.fireAfter(1, function()
            if not AiUtility.isLastAlive and distanceToSite > 800 then
                self.ai.voice.pack:speakRequestTeammatesToPush(self.bombsite)
            end
        end)
    end
end

--- @return void
function AiStatePlant:deactivate()
    self.plantDelayTimer:stop()
end

--- @param bombsite string
--- @return void
function AiStatePlant:invoke(bombsite)
    self.bombsite = bombsite

    self:queueForReactivation()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePlant:think(cmd)
    self.activity = "Going to plant bomb"

    local distance = LocalPlayer:getOrigin():getDistance2(self.node.origin)

    if distance < 150 then
        self.activity = "Planting bomb"

        self.ai.routines.manageGear:block()

        LocalPlayer.equipBomb()
    end

    if distance < 72 then
        View.lookAlongAngle(self.node.direction, 5, View.noise.idle, "Plant look at angle")
        Pathfinder.counterStrafe()
    end

    if distance < 25 then
        cmd.in_duck = true

        if LocalPlayer:isAbleToAttack() then
            self.plantDelayTimer:ifPausedThenStart()

            if self.plantDelayTimer:isElapsed(self.plantDelayTime) then
                cmd.in_use = true
            end
        end
    end

    Pathfinder.ifIdleThenRetryLastRequest()
end

--- @param site string
--- @return Node
function AiStatePlant:setPlantNode(site)
    local clientOrigin = LocalPlayer:getOrigin()

    if clientOrigin:getDistance(Nodegraph.getOne(Node.objectiveBombsiteA).origin) < 1024 then
        site = "A"
    elseif clientOrigin:getDistance(Nodegraph.getOne(Node.objectiveBombsiteB).origin) < 1024 then
        site = "B"
    else
        site = site or AiUtility.randomBombsite
    end

    self.bombsite = site

    local nodes = Nodegraph.getForBombsite(Node.spotPlant, site)

    if not nodes then
        return
    end

    --- @type NodeSpotPlant
    local closestNode
    local closestDistance = math.huge

    for _, node in pairs(nodes) do
        local distance = clientOrigin:getDistance(node.origin)

        if distance < closestDistance then
            closestDistance = distance
            closestNode = node
        end
    end

    if not closestNode then
        return
    end

    self.node = closestNode
end

return Nyx.class("AiStatePlant", AiStatePlant, AiStateBase)
--}}}
