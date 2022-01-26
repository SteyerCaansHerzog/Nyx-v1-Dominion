--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateSweep
--- @class AiStateSweep : AiState
--- @field node Node
local AiStateSweep = {
    name = "Sweep"
}

--- @param fields AiStateSweep
--- @return AiStateSweep
function AiStateSweep:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateSweep:assess()
    return AiState.priority.SWEEP
end

--- @param ai AiOptions
--- @param site string
--- @return void
function AiStateSweep:activate(ai, site)
    self.node = self:getObjective(ai, site)

    local objective = self.node

    if not objective then
        return
    end

    local objectiveName = Node.typesName[objective.type]

    ai.nodegraph:pathfind(objective.origin, {
        objective = Node.types.GOAL,
        retry = false,
        ignore = Client.getEid(),
        task = string.format("Sweeping %s site", objectiveName),
        onComplete = function()
            ai.nodegraph:log("Cleared %s", objectiveName)

            self.node = self:getObjective(ai)
        end
    })
end

--- @param ai AiOptions
--- @return void
function AiStateSweep:think(ai) end

--- @param ai AiOptions
--- @param site string
--- @return Node
function AiStateSweep:getObjective(ai, site)
    --- @type Node[]
    local objective

    if site then
        objective = site == "a" and ai.nodegraph.objectiveA or ai.nodegraph.objectiveB
    else
        local origin = AiUtility.client:getOrigin()
        local distanceA = origin:getDistance(ai.nodegraph.objectiveA.origin)
        local distanceB = origin:getDistance(ai.nodegraph.objectiveB.origin)

        if distanceA > distanceB then
            objective = ai.nodegraph.objectiveA
        else
            objective = ai.nodegraph.objectiveB
        end
    end

    return objective
end

return Nyx.class("AiStateSweep", AiStateSweep, AiState)
--}}}
