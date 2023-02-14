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
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStatePlant
--- @class AiStatePlant : AiStateBase
--- @field node NodeSpotPlant
--- @field bombsite string
--- @field lastBombsite string
--- @field plantDelayTimer Timer
--- @field plantDelayTime number
--- @field isPlanting boolean
--- @field tellSiteTimer Timer
--- @field pickRandomSiteTimer Timer
local AiStatePlant = {
    name = "Plant",
    isLockable = false,
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

    Callbacks.bombPickup(function(e)
        if not e.player:isLocalPlayer() then
            return
        end

        if AiUtility.timeData.roundtime_elapsed < 10 then
            return
        end

        local bombsite = Nodegraph.getClosestBombsite(LocalPlayer:getOrigin())

        if LocalPlayer:getOrigin():getDistance(bombsite.origin) > 1500 then
            return
        end

        self.bombsite = bombsite.bombsite

        self.ai.commands.go:bark(self.bombsite:lower())
    end)

    Callbacks.roundPrestart(function()
        if not LocalPlayer:isTerrorist() then
            return
        end

        self.isPlanting = false

        self.pickRandomSiteTimer:start()
        self.tellSiteTimer:elapse()

        Client.onNextTick(function()
            if not LocalPlayer:isBombCarrier() then
                return
            end

            self.bombsite = AiUtility.randomBombsite
            self.lastBombsite = self.bombsite

            self.ai.commands.go:bark(self.bombsite:lower())
        end)
    end)

    Callbacks.bombBeginPlant(function(e)
        if not e.player:isLocalPlayer() then
            return
        end

        self.isPlanting = true
    end)

    Callbacks.bombAbortPlant(function(e)
        if not e.player:isLocalPlayer() then
            return
        end

        self.isPlanting = false
    end)

    Callbacks.setupCommand(function()
        if AiUtility.gameRules:m_bFreezePeriod() == 1 then
            return
        end

        if not self.bombsite or not LocalPlayer.isCarryingBomb() then
            return
        end

        if self.bombsite == self.lastBombsite then
            return
        end

        self.lastBombsite = self.bombsite

        local origin = LocalPlayer:getOrigin()

        if not AiUtility.isLastAlive and not self.ai.reaper.isActive and MenuGroup.useChatCommands:get() then
            self.ai.commands.go:bark(self.bombsite:lower())

            local distanceToSite = origin:getDistance(Nodegraph.getClosestBombsite(origin).origin)

            Client.fireAfterRandom(0, 1, function()
                if not AiUtility.isLastAlive and distanceToSite > 800 then
                    self.ai.voice.pack:speakRequestTeammatesToPush(self.bombsite)
                end
            end)
        end
    end)
end

--- @return void
function AiStatePlant:assess()
    if AiUtility.gameRules:m_bFreezePeriod() == 1 or not LocalPlayer.isCarryingBomb() then
        return AiPriority.IGNORE
    end

    if self.ai.states.evacuate.isSaving then
        return AiPriority.IGNORE
    end

    -- Set plant node every tick.
    -- Before it would only set if this behaviour activated, but this assess logic relies on a plant node to be set.
    self:setPlantNode(self.bombsite)

    local clientOrigin = LocalPlayer:getOrigin()
    local isTeammateNearby = AiUtility.closestTeammate and clientOrigin:getDistance(AiUtility.closestTeammate:getOrigin()) < 500
    local isAtPlantSpot = self.node and clientOrigin:getDistance(self.node.floorOrigin) < 100
    local isNearPlantSpot = self.node and clientOrigin:getDistance(self.node.floorOrigin) < 600
    local isVeryNearPlantSpot = self.node and clientOrigin:getDistance(self.node.floorOrigin) < 300
    local closestEnemyDistance = AiUtility.closestEnemy and clientOrigin:getDistance(AiUtility.closestEnemy:getOrigin())

    if AiUtility.isLastAlive and closestEnemyDistance and closestEnemyDistance < 600 then
        return AiPriority.IGNORE
    end

    if isAtPlantSpot and isTeammateNearby then
        return AiPriority.PLANT_COVERED
    end

    if isAtPlantSpot and not AiUtility.isClientThreatenedMajor then
        return AiPriority.PLANT_COVERED
    end

    if self.isPlanting then
        return AiPriority.PLANT_EXPEDITE
    end

    if isVeryNearPlantSpot and isTeammateNearby
        and (not closestEnemyDistance or (closestEnemyDistance and closestEnemyDistance > 250))
    then
        return AiPriority.PLANT_EXPEDITE
    end

    if isAtPlantSpot and not AiUtility.isEnemyVisible then
        return AiPriority.PLANT_EXPEDITE
    end

    if isNearPlantSpot and isTeammateNearby then
        return AiPriority.PLANT_EXPEDITE
    end

    if AiUtility.timeData.roundtime_remaining < 20 then
        return AiPriority.PLANT_EXPEDITE
    end

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():getDistance(self.node.origin) < 1250 then
            return AiPriority.PLANT_EXPEDITE
        end
    end

    if isNearPlantSpot then
        return AiPriority.PLANT_ACTIVE
    end

    if AiUtility.timeData.roundtime_remaining < 40 then
        return AiPriority.PLANT_ACTIVE
    end

    return AiPriority.PLANT_PASSIVE
end

--- @return void
function AiStatePlant:activate()
    Pathfinder.moveToNode(self.node, {
        task = string.format("Plant the bomb at bombsite %s", self.bombsite),
        isCounterStrafingOnGoal = true
    })
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
    self.activity = string.format("Going to plant on %s", self.node.bombsite)

    local distance = LocalPlayer:getOrigin():getDistance2(self.node.origin)

    if distance < 250 and AiUtility.teammatesAlive > 0 then
        self.ai.routines.walk:block()
    end

    if distance < 150 then
        self.activity = string.format("Planting on %s", self.node.bombsite)

        self.ai.routines.manageGear:block()

        LocalPlayer.equipBomb()
    end

    if distance < 72 then
        VirtualMouse.lookAlongAngle(self.node.direction, 5, VirtualMouse.noise.idle, "Plant look at angle")
        Pathfinder.counterStrafe()
    end

    if distance < 35 then
        cmd.in_duck = true

        if LocalPlayer:isAbleToAttack() then
            self.plantDelayTimer:ifPausedThenStart()

            if self.plantDelayTimer:isElapsed(self.plantDelayTime) then
                cmd.in_use = true
            end
        end
    end
end

--- @param site string
--- @return Node
function AiStatePlant:setPlantNode(site)
    local clientOrigin = LocalPlayer:getOrigin()

    if not site then
        site = AiUtility.randomBombsite
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
        local distance = clientOrigin:getDistance(node.floorOrigin)

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
