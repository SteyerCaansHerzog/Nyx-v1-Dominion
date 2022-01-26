--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateEvacuate
--- @class AiStateEvacuate : AiState
--- @field reachedDestination boolean
--- @field node Node
local AiStateEvacuate = {
    name = "Evacuate",
    canDelayActivation = true
}

--- @param fields AiStateEvacuate
--- @return AiStateEvacuate
function AiStateEvacuate:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateEvacuate:assess()
    if AiUtility.isRoundOver then
        return AiState.priority.ROUND_OVER
    end

    local bomb = AiUtility.plantedBomb

    if not bomb then
        return AiState.priority.IGNORE
    end

    for _, enemy in pairs(AiUtility.enemies) do
        if enemy:m_bIsDefusing() == 1 then
            return AiState.priority.IGNORE
        end
    end

    local player = AiUtility.client

    if player:isCounterTerrorist() then
        if player:m_bIsDefusing() == 1 then
            return AiState.priority.IGNORE
        end

        if not AiUtility.canDefuse then
            return AiState.priority.EVACUATE
        end
    else
        if AiUtility.bombDetonationTime < 15 then
            return AiState.priority.EVACUATE
        end
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateEvacuate:activate(ai)
    local node = self:getHideNode(ai, AiUtility.bombPlantedAt)

    if not node then
        return
    end

    self.node = node

    ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid(),
        task = string.format("Evacuating to hiding spot", node.id),
        onComplete = function()
            self.reachedDestination = true

            ai.nodegraph:log("Hiding [%i]", node.id)
        end
    })
end

--- @param ai AiOptions
--- @return void
function AiStateEvacuate:think(ai)
    if not self.node then
        self:activate(ai)

        return
    end

    local player = AiUtility.client

    if player:getOrigin():getDistance(self.node.origin) < 200 then
        ai.view:lookInDirection(self.node.direction, 7)
        ai.controller.canUseKnife = false
    end
end

--- @param ai AiOptions
--- @param site string
--- @return Node
function AiStateEvacuate:getHideNode(ai, site)
    local bombSite = site == "A" and ai.nodegraph.objectiveA or ai.nodegraph.objectiveB
    local checkOrigin = site and bombSite.origin or AiUtility.client:getOrigin()
    local nodes = {}

    for _, node in pairs(ai.nodegraph.nodes) do
        if node.type == Node.types.HIDE and node.origin:getDistance(checkOrigin) > 1500 then
            table.insert(nodes, node)
        end
    end

    return nodes[Client.getRandomInt(1, #nodes)]
end

return Nyx.class("AiStateEvacuate", AiStateEvacuate, AiState)
--}}}
