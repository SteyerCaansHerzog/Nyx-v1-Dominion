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
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
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
--- @field retakeNode string
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
    self.throwTime = 0.1
    self.threatCooldownTimer = Timer:new():startThenElapse()
    self.cooldownTimer = Timer:new():startThenElapse()

    Callbacks.runCommand(function()
    	self:watchForOccupiedNodes()
    end)

    Callbacks.grenadeThrown(function(e)
        if e.player:isClient() then
            self.isInThrow = false
            self.node = nil

            self.cooldownTimer:start()
        end
    end)
end

--- @return void
function AiStateGrenadeBase:assess()
    -- No need to use grenades.
    if AiUtility.isRoundOver or AiUtility.enemiesAlive == 0 then
        return AiPriority.IGNORE
    end

    -- Ignore before round starts. Otherwise we can trip the cooldown.
    if Entity.getGameRules():m_bFreezePeriod() == 1 then
        return AiPriority.IGNORE
    end

    -- We're on cooldown from using any line-ups.
    if not AiStateGrenadeBase.globalCooldownTimer:isElapsed(10) then
        return AiPriority.IGNORE
    end

    -- We're on a cooldown from using the current type of grenade.
    if not self.cooldownTimer:isElapsed(self.cooldown) then
        return AiPriority.IGNORE
    end

    -- We don't have the type of grenade in question.
    if not AiUtility.client:hasWeapons(self.weapons) then
        return AiPriority.IGNORE
    end

    -- We're threatened by an enemy.
    if AiUtility.isClientThreatened then
        self.threatCooldownTimer:restart()

        return AiPriority.IGNORE
    end

    -- Prevent dithering with enemy presence.
    if not self.threatCooldownTimer:isElapsed(3) then
        return AiPriority.IGNORE
    end

    -- Prevent dithering with plant behaviour.
    if self.inBehaviorTimer:isStarted() then
        return AiPriority.GOING_TO_THROW_GRENADE
    end

    -- We already have a line-up.
    -- Only exit here if we're in throw, because we need to ensure teammates don't occupy our line-up
    -- after we've picked it.
    if self.node then
        -- We're about to throw a grenade.
        if self.isInThrow then
            return AiPriority.THROWING_GRENADE
        end
    end

    -- Find all possible line-ups.
    local nodes = self:getNodes()

    -- No nodes on the map.
    if not nodes then
        return AiPriority.IGNORE
    end

    -- Find the best line-up for the type of grenade we want to use.
    local node = self:getBestLineup(nodes)

    -- Something went wrong when finding a line-up. Possibly all nodes are unavailable.
    if not node then
        return AiPriority.IGNORE
    end

    self.node = node

    -- We've got a line-up to use.
    return self.priority
end

--- @param nodes Node[]
--- @return Node
function AiStateGrenadeBase:getBestLineup(nodes)
    -- Should we check if enemies could be affected by the line-up?
    local isCheckingEnemies = true

    if AiUtility.client:isTerrorist() and not AiUtility.roundTimer:isElapsed(20) then
        isCheckingEnemies = false
    end

    local player = AiUtility.client
    local clientOrigin = player:getOrigin()
    local clientCenter = clientOrigin:offset(0, 0, 48)

    --- @type Node
    local closestNode
    local closestDistance = math.huge

    -- Find a suitable grenade line-up to use.
    for _, node in pairs(nodes) do repeat
        local distance = clientOrigin:getDistance(node.origin)

        if distance > 600 or distance >= closestDistance then
            break
        end

        local usedNodeTimer = AiStateGrenadeBase.usedNodes[node.id]

        -- A teammate has already used this node.
        if usedNodeTimer and not usedNodeTimer:isElapsed(15) then
            break
        end

        local bounds = node.origin:getBounds(Vector3.align.BOTTOM, 500, 500, 64)

        if not clientCenter:isInBounds(bounds) then
            break
        end

        local isValidGrenadeNode = true

        -- We care if enemies could be affected by this line-up.
        if isCheckingEnemies then
            isValidGrenadeNode = self:isEnemyThreatenedByNode(node)
        end

        -- This line-up is no use to us.
        if not isValidGrenadeNode then
            break
        end

        closestDistance = distance
        closestNode = node
    until true end

    return closestNode
end

--- @param node Node
--- @return boolean
function AiStateGrenadeBase:isEnemyThreatenedByNode(node)
    for _, enemy in pairs(AiUtility.enemies) do repeat
        local enemyOrigin = enemy:getOrigin()
        local enemyDistance = node.origin:getDistance(enemyOrigin)

        -- Enemy is too far away.
        if enemyDistance > self.rangeThreshold then
            break
        end

        local fov = node.direction:clone():set(0, nil):getFov(node.origin, enemyOrigin)

        -- Enemy is not within an acceptable field of view.
        if fov > 65 then
            break
        end

        return true
    until true end

    return false
end

--- @return void
function AiStateGrenadeBase:watchForOccupiedNodes()
    -- Find all possible line-ups.
    local nodes = self:getNodes()

    if not nodes then
        return
    end

    local clientOrigin = AiUtility.client:getOrigin()

    for _, node in pairs(nodes) do repeat
        local distance = clientOrigin:getDistance(node.origin)

        if distance > 1500 then
            break
        end

        if not AiStateGrenadeBase.usedNodes[node.id] then
            AiStateGrenadeBase.usedNodes[node.id] = Timer:new():startThenElapse()
        end

        local isOccupied = false

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance2(node.origin) < 45 then
                isOccupied = true

                break
            end
        end

        if isOccupied then
           AiStateGrenadeBase.usedNodes[node.id]:restart()
        end
    until true end
end

--- @return void
function AiStateGrenadeBase:activate()
    if not self.node then
        return
    end

    self.inBehaviorTimer:start()

    self.reachedDestination = false

   self.ai.nodegraph:pathfind(self.node.origin, {
        objective = Node.types.GOAL,
        task = string.format("Throw %s", self.name:lower()),
        onComplete = function()
           self.ai.nodegraph:log(string.format("Throwing %s", self.name:lower()))

            self.reachedDestination = true
        end
    })
end

--- @return void
function AiStateGrenadeBase:deactivate()
    self.node = nil
    self.inBehaviorTimer:stop()

    if AiUtility.client:hasPrimary() then
        Client.equipPrimary()
    else
        Client.equipPistol()
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateGrenadeBase:think(cmd)
    -- Don't know why we are running with a nil node.
    if not self.node then
        self:deactivate()

        return
    end


    if AiStateGrenadeBase.usedNodes[self.node.id] and AiStateGrenadeBase.usedNodes[self.node.id]:isNotElapsed(15) then
        self:deactivate()

        return
    end

    -- We haven't thrown the grenade within this time.
    -- We're probably stuck. Abort the throw.
    if self.inBehaviorTimer:isElapsedThenStop(6) then
        self.cooldownTimer:start()

        self:deactivate()

        return
    end

    self.activity = string.format("Going to throw %s", self.name)

    self.ai.states.evade.isBlocked = true

    local player = AiUtility.client
    local playerOrigin = player:getOrigin()

    self.isInThrow = false

    if not self.reachedDestination and self.ai.nodegraph:isIdle() then
        self:activate()
    end

    local distance = playerOrigin:getDistance(self.node.origin)

    if distance < 20 then
       self.ai.nodegraph.isAllowedToMove = false
    end

    if distance < 46 then
        self.throwTimer:ifPausedThenStart()
    end

    if distance < 250 then
        self.activity = string.format("Throwing %s", self.name)

        self.ai.canUseGear = false
        self.ai.canLookAwayFromFlash = false
        self.ai.isQuickStopping = true

        self.equipFunction()
    end

    if distance < 150 then
       self.ai.nodegraph.moveAngle = playerOrigin:getAngle(self.node.origin)
       self.ai.nodegraph.isAllowedToAvoidTeammates = false
       self.ai.view.isCrosshairUsingVelocity = false
       self.ai.view.isCrosshairSmoothed = true

       self.ai.view:lookInDirection(self.node.direction, 5, self.ai.view.noiseType.NONE, "GrenadeBase look at line-up")

        local deltaAngles = self.node.direction:getAbsDiff(Client.getCameraAngles())

        if deltaAngles.p < 15 and deltaAngles.y < 15 then
            self.isInThrow = true
        end

        local speed = AiUtility.client:m_vecVelocity():getMagnitude()

        if deltaAngles.p < 1.5
            and deltaAngles.y < 1.5
            and distance < 32
            and self.throwTimer:isElapsedThenRestart(self.throwTime)
            and player:isHoldingWeapons(self.weapons)
            and player:isAbleToAttack()
            and speed < 10
        then
            cmd.in_attack = 1
        end
    else
        self.throwTimer:stop()
    end
end

--- @return Node[]
function AiStateGrenadeBase:getNodes()
    local player = AiUtility.client

    if player:isCounterTerrorist() then
        if AiUtility.plantedBomb then
            return self.ai.nodegraph[self.retakeNode]
        end

        return self.ai.nodegraph[self.defendNode]
    elseif player:isTerrorist() then
        local isSiteTaken = false

        if AiUtility.plantedBomb then
            isSiteTaken = true
        elseif AiUtility.bombCarrier then
            local bombCarrierOrigin = AiUtility.bombCarrier:m_vecOrigin()

            if bombCarrierOrigin then
                if bombCarrierOrigin:getDistance(self.ai.nodegraph:getSiteNode("a").origin) < 750 then
                    isSiteTaken = true
                elseif bombCarrierOrigin:getDistance(self.ai.nodegraph:getSiteNode("b").origin) < 750 then
                    isSiteTaken = true
                end
            end
        end

        return isSiteTaken and self.ai.nodegraph[self.holdNode] or self.ai.nodegraph[self.executeNode]
    end
end

return Nyx.class("AiStateGrenadeBase", AiStateGrenadeBase, AiState)
--}}}
