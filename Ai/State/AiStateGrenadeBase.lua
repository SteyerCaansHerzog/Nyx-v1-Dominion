--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateGrenadeBase
--- @class AiStateGrenadeBase : AiState
--- @field priority number
--- @field cooldown number
--- @field defendNode string
--- @field executeNode string
--- @field holdNode string
--- @field weapons string[]
--- @field equipFunction fun(): nil
--- @field rangeThreshold number
---
--- @field isInThrow boolean
--- @field node Node
--- @field throwTimer Timer
--- @field throwTime number
--- @field reachedDestination boolean
--- @field cooldownTimer Timer
--- @field inBehaviorTimer Timer
--- @field usedNodes Timer[]
--- @field threatCooldownTimer Timer
local AiStateGrenadeBase = {
    name = "GrenadeBase",
    globalCooldownTimer = Timer:new():startThenElapse(),
    cooldownTimer = Timer:new():startThenElapse(),
    usedNodes = {},
    rangeThreshold = 2000
}

--- @param fields AiStateGrenadeBase
--- @return AiStateGrenadeBase
function AiStateGrenadeBase:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateGrenadeBase:__init()
    self.inBehaviorTimer = Timer:new()
    self.throwTimer = Timer:new()
    self.throwTime = 0.2
    self.threatCooldownTimer = Timer:new():startThenElapse()

    Callbacks.grenadeThrown(function(e)
        if e.player:isClient() then
            self.isInThrow = false
            self.node = nil

            AiStateGrenadeBase.cooldownTimer:start()
        end
    end)
end

--- @param nodegraph Nodegraph
--- @return void
function AiStateGrenadeBase:assess(nodegraph)
    if Entity.getGameRules():m_bFreezePeriod() == 1 then
        return AiState.priority.IGNORE
    end

    if AiUtility.isClientThreatened then
        self.threatCooldownTimer:restart()

        return AiState.priority.IGNORE
    end

    if not self.threatCooldownTimer:isElapsed(3) then
        return AiState.priority.IGNORE
    end

    if AiUtility.isRoundOver or AiUtility.enemiesAlive == 0 then
        return AiState.priority.IGNORE
    end

    local isCheckingEnemies = true

    if AiUtility.client:isTerrorist() and not AiUtility.roundTimer:isElapsed(20) then
        isCheckingEnemies = false
    end

    local grenadeNodes = self:getNodes(nodegraph)

    if not grenadeNodes then
        return AiState.priority.IGNORE
    end

    local player = AiUtility.client
    local playerOrigin = player:getOrigin()
    local playerCenter = playerOrigin:offset(0, 0, 48)

    --- @type Node
    local closestNode
    local closestDistance = math.huge

    for _, grenadeNode in pairs(grenadeNodes) do repeat
        local usedNodeTimer = AiStateGrenadeBase.usedNodes[grenadeNode.id]

        if usedNodeTimer then
            if usedNodeTimer:isElapsed(10) then
                AiStateGrenadeBase.usedNodes[grenadeNode.id] = nil
            else
                break
            end
        end

        local isOccupied = false

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance(grenadeNode.origin) < 32 then
                isOccupied = true

                break
            end
        end

        if isOccupied and playerOrigin:getDistance(grenadeNode.origin) > 32 then
            AiStateGrenadeBase.usedNodes[grenadeNode.id] = Timer:new():start()

            break
        end

        local distance = playerOrigin:getDistance(grenadeNode.origin)

        if distance < 600 and distance < closestDistance then
            local bounds = grenadeNode.origin:getBounds(Vector3.align.BOTTOM, 500, 500, 64)
            local isValidGrenadeNode = false

            if playerCenter:isInBounds(bounds) then
                if isCheckingEnemies then
                    for _, enemy in pairs(AiUtility.enemies) do
                        local enemyOrigin = enemy:getOrigin()
                        local enemyDistance = grenadeNode.origin:getDistance(enemyOrigin)

                        if enemyDistance < self.rangeThreshold then
                            local fov = grenadeNode.direction:clone():set(0, nil):getFov(grenadeNode.origin, enemyOrigin)

                            if fov < 40 then
                                isValidGrenadeNode = true

                                break
                            end
                        end
                    end
                else
                    isValidGrenadeNode = true
                end

                if not isValidGrenadeNode then
                    break
                end

                closestDistance = distance
                closestNode = grenadeNode
            end
        end
    until true end

    if self.inBehaviorTimer:isElapsedThenStop(5) then
        AiStateGrenadeBase.cooldownTimer:start()

        self.node = nil

        return AiState.priority.IGNORE
    end

    if self.node and self.isInThrow then
        return AiState.priority.THROWING_GRENADE
    end

    if AiUtility.isRoundOver then
        return AiState.priority.IGNORE
    end

    if self.node then
        return self.priority
    end

    if AiStateGrenadeBase.globalCooldownTimer:isStarted() and not AiStateGrenadeBase.globalCooldownTimer:isElapsedThenStop(10) then
        return AiState.priority.IGNORE
    end

    if AiStateGrenadeBase.cooldownTimer:isStarted() and not AiStateGrenadeBase.cooldownTimer:isElapsedThenStop(self.cooldown or 0) then
        return AiState.priority.IGNORE
    end

    if not player:hasWeapons(self.weapons) then
        return AiState.priority.IGNORE
    end

    if closestNode then
        self.node = closestNode

        return self.priority
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateGrenadeBase:activate(ai)
    if not self.node then
        return
    end

    self.inBehaviorTimer:start()

    self.reachedDestination = false

    ai.nodegraph:pathfind(self.node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid(),
        task = string.format("Throw %s", self.name:lower()),
        onComplete = function()
            ai.nodegraph:log(string.format("Throwing %s", self.name:lower()))

            self.reachedDestination = true
        end
    })
end

--- @return void
function AiStateGrenadeBase:deactivate()
    if AiUtility.client:hasPrimary() then
        Client.equipPrimary()
    else
        Client.equipPistol()
    end
end

--- @param ai AiOptions
--- @return void
function AiStateGrenadeBase:think(ai)
    self.activity = string.format("Going to throw %s", self.name)

    if self.node and AiStateGrenadeBase.usedNodes[self.node.id] then
        self.node = nil

        return
    end

    ai.controller.states.evade.isBlocked = true

    local player = AiUtility.client
    local playerOrigin = player:getOrigin()

    self.isInThrow = false

    if not self.reachedDestination and not ai.nodegraph.path and ai.nodegraph:canPathfind() then
        self:activate(ai)
    end

    local distance = playerOrigin:getDistance(self.node.origin)

    if distance < 20 then
        ai.nodegraph.isAllowedToMove = false
    end

    if distance < 46 then
        self.throwTimer:ifPausedThenStart()
    end

    if distance < 250 then
        self.activity = string.format("Throwing %s", self.name)

        ai.controller.canUseGear = false
        ai.controller.canLookAwayFromFlash = false
        ai.controller.isQuickStopping = true

        self.equipFunction()
    end

    if distance < 150 then
        ai.nodegraph.moveAngle = playerOrigin:getAngle(self.node.origin)
        ai.nodegraph.isAllowedToAvoidTeammates = false
        ai.view.isCrosshairUsingVelocity = false
        ai.view.isCrosshairSmoothed = true

        ai.view:lookInDirection(self.node.direction, 5, ai.view.noiseType.NONE, "GrenadeBase look at line-up")

        local deltaAngles = self.node.direction:getAbsDiff(Client.getCameraAngles())

        if deltaAngles.p < 15 and deltaAngles.y < 15 then
            self.isInThrow = true
        end

        if deltaAngles.p < 1.5
            and deltaAngles.y < 1.5
            and distance < 32
            and self.throwTimer:isElapsedThenRestart(self.throwTime)
            and player:isHoldingWeapons(self.weapons)
            and player:isAbleToAttack()
        then
            ai.cmd.in_attack = 1
        end
    else
        self.throwTimer:stop()
    end
end

--- @param nodegraph Nodegraph
--- @return Node[]
function AiStateGrenadeBase:getNodes(nodegraph)
    local player = AiUtility.client

    if player:isCounterTerrorist() then
        return nodegraph[self.defendNode]
    elseif player:isTerrorist() then
        local isSiteTaken = false

        if AiUtility.plantedBomb then
            isSiteTaken = true
        elseif AiUtility.bombCarrier then
            local bombCarrierOrigin = AiUtility.bombCarrier:m_vecOrigin()

            if bombCarrierOrigin then
                if bombCarrierOrigin:getDistance(nodegraph:getSiteNode("a").origin) < 750 then
                    isSiteTaken = true
                elseif bombCarrierOrigin:getDistance(nodegraph:getSiteNode("b").origin) < 750 then
                    isSiteTaken = true
                end
            end
        end

        return isSiteTaken and nodegraph[self.holdNode] or nodegraph[self.executeNode]
    end
end

return Nyx.class("AiStateGrenadeBase", AiStateGrenadeBase, AiState)
--}}}
