--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateEvacuate
--- @class AiStateEvacuate : AiState
--- @field isBombPlanted boolean
--- @field isForcedToSave boolean
--- @field node Node
--- @field isAtDestination boolean
local AiStateEvacuate = {
    name = "Evacuate"
}

--- @param fields AiStateEvacuate
--- @return AiStateEvacuate
function AiStateEvacuate:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateEvacuate:__init()
    self.isForcedToSave = false

    Callbacks.roundPrestart(function()
    	self:reset()
    end)
end

--- @return void
function AiStateEvacuate:assess()
    -- A human has told us to save this round.
    if self.isForcedToSave then
        return AiPriority.SAVE_ROUND
    end

    if AiUtility.client:isCounterTerrorist() then
        -- We're defusing, we shouldn't evacuate.
        -- We can only be defusing if we have time.
        if AiUtility.client:m_bIsDefusing() == 1 then
            return AiPriority.IGNORE
        end

        -- We should save.
        if self:isRoundWinProbabilityLow() then
            return AiPriority.SAVE_ROUND
        end

        -- We're not able to defuse the bomb due to time.
        if AiUtility.plantedBomb and not AiUtility.canDefuse then
            return AiPriority.SAVE_ROUND
        end
    elseif AiUtility.client:isTerrorist() then
        -- We should save.
        if self:isRoundWinProbabilityLow()then
            return AiPriority.SAVE_ROUND
        end

        -- The enemy likely cannot defuse now, and we need to leave the site.
        if AiUtility.plantedBomb and not AiUtility.isBombBeingDefusedByEnemy and AiUtility.bombDetonationTime < 10 then
            return AiPriority.ABANDON_BOMBSITE
        end
    end

    -- Round is effectively over.
    if AiUtility.isRoundOver and AiUtility.enemiesAlive == 0 then
        return AiPriority.ROUND_OVER
    end

    return AiPriority.IGNORE
end

--- @return boolean
function AiStateEvacuate:isRoundWinProbabilityLow()
    -- Prevent sitting in a corner and being murdered.
    if self.isAtDestination and AiUtility.isClientThreatened then
        return false
    end

    local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
    local maxRounds = cvar.mp_maxrounds:get_int()
    local halfTime = math.ceil(maxRounds / 2)

    -- First round, last round of half, last round of game.
    if roundsPlayed == 0 or roundsPlayed == (maxRounds - 1) or roundsPlayed == (halfTime - 1) then
        return false
    end

    -- We have no valuables.
    if not AiUtility.client:hasPrimary() then
        return false
    end

    local teamDisparity = AiUtility.teammatesAlive - AiUtility.enemiesAlive
    local isBombPlanted = AiUtility.isBombPlanted()

    if AiUtility.client:isCounterTerrorist() then
        -- 5v1 scenario.
        if teamDisparity <= -4 then
            return true
        end

        -- Bomb is down. This makes our odds really bad.
        if isBombPlanted then
            -- 5v2 scenario.
            if teamDisparity <= -3 then
                return true
            end

            -- We're last, there's 2+ enemies, and we're low.
            if AiUtility.isLastAlive and AiUtility.enemiesAlive >= 2 and AiUtility.client:m_iHealth() <= 33 then
                return true
            end
        end
    elseif AiUtility.client:isTerrorist() then
        -- We haven't planted. This makes our odds really bad.
        if not isBombPlanted then
            -- 5v1 scenario.
            if teamDisparity <= -4 then
                return true
            end

            -- We're last, there's 2+ enemies, and we're low.
            if AiUtility.isLastAlive and AiUtility.enemiesAlive >= 3 and AiUtility.client:m_iHealth() <= 33 then
                return true
            end
        end
    end

    return false
end

--- @return void
function AiStateEvacuate:activate()
    local node = self:getHideNode()

    if not node then
        return
    end

    self.isBombPlanted = AiUtility.isBombPlanted()
    self.node = node
    self.isAtDestination = false
end

--- @return void
function AiStateEvacuate:reset()
    self.isForcedToSave = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEvacuate:think(cmd)
    if not self.node then
        self:activate()

        return
    end

    if not self.isBombPlanted and AiUtility.isBombPlanted() then
        self:activate()

        return
    end

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():getDistance(self.node.origin) < 32 then
            self.node = nil

            self:activate()
        end
    end

    self.activity = "Going to hide"

    if not self.isAtDestination and self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:pathfind(self.node.origin, {
            objective = Node.types.GOAL,
            task = "Evacuating to hiding spot",
            onComplete = function()
                self.isAtDestination = true
            end
        })
    end

    local trace = Trace.getLineToPosition(AiUtility.client:getEyeOrigin(), self.node.origin, AiUtility.traceOptionsAttacking, "AiStateEvacuate.think<FindSpotVisible>")
    local distance = AiUtility.client:getOrigin():getDistance(self.node.origin)

    if distance < 32 then
        cmd.in_duck = 1
    end

    if not trace.isIntersectingGeometry and distance < 200 then
        self.activity = "Hiding"

        self.ai.canUseKnife = false

        local lookOrigin = self.node.origin:clone():offset(0, 0, 46)
        local trace = Trace.getLineAtAngle(lookOrigin, self.node.direction, AiUtility.traceOptionsPathfinding, "AiStateEvacuate.think<FindLookAngle>")

       self.ai.view:lookAtLocation(trace.endPosition, 4, self.ai.view.noiseType.NONE, "Evacuate look at angle")
    end
end

--- @return Node
function AiStateEvacuate:getHideNode()
    local nodes = {}
    local clientOrigin = AiUtility.client:getOrigin()
    local plantOrigin

    if AiUtility.plantedBomb then
        plantOrigin = AiUtility.plantedBomb:getOrigin()
    end

    if self.isForcedToSave then
        --- @type Node
        local closestNode
        local closestNodeDistance = math.huge

        for _, node in pairs(self.ai.nodegraph.nodes) do repeat
            -- Node is too close to planted bomb.
            if plantOrigin and node.origin:getDistance(plantOrigin) < 2500 then
                break
            end

            local distanceToClient = clientOrigin:getDistance(node.origin)
            local isAvailable = true

            -- Teammate is already in this spot.
            for _, teammate in pairs(AiUtility.teammates) do
                if teammate:getOrigin():getDistance(node.origin) < 32 then
                    isAvailable = false

                    break
                end
            end

            -- This node is fine.
            if isAvailable and node.type == Node.types.HIDE and distanceToClient < closestNodeDistance then
                closestNodeDistance = distanceToClient

                closestNode = node
            end
        until true end

        return closestNode
    else
        -- Find a random node.
        for _, node in pairs(self.ai.nodegraph.nodes) do repeat
            -- Node is too close to planted bomb.
            if plantOrigin and node.origin:getDistance(plantOrigin) < 2500 then
                break
            end

            if node.type == Node.types.HIDE then
                table.insert(nodes, node)
            end
        until true end

        return nodes[Client.getRandomInt(1, #nodes)]
    end
end

return Nyx.class("AiStateEvacuate", AiStateEvacuate, AiState)
--}}}
