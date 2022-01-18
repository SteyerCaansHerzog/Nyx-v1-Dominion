--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateDeveloper
--- @class AiStateDeveloper : AiState
local AiStateDeveloper = {
    name = "Developer"
}

--- @param fields AiStateDeveloper
--- @return AiStateDeveloper
function AiStateDeveloper:new(fields)
    return Nyx.new(self, fields)
end

--- @return nil
function AiStateDeveloper:__init() end

--- @return nil
function AiStateDeveloper:assess()
    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return nil
function AiStateDeveloper:activate(ai)
    local node = ai.nodegraph.nodes[835]
    --local node = ai.nodegraph.objectiveA

    ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        retry = false,
        ignore = Client.getEid(),
        task = "Test",
        onComplete = function() end
    })
end

--- @return nil
function AiStateDeveloper:reset() end

--- @param ai AiOptions
--- @return nil
function AiStateDeveloper:think(ai) end

return Nyx.class("AiStateDeveloper", AiStateDeveloper, AiState)
--}}}
