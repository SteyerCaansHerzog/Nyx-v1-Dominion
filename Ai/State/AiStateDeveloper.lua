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

--- @return void
function AiStateDeveloper:__init() end

--- @return void
function AiStateDeveloper:assess()
    return -2
end

--- @param ai AiOptions
--- @return void
function AiStateDeveloper:activate(ai)
    ai.nodegraph:pathfind(ai.nodegraph.objectiveB.origin, {
        objective = Node.types.GOAL,
        retry = false,
        ignore = Client.getEid(),
        task = "Test",
        onComplete = function() end
    })
end

--- @return void
function AiStateDeveloper:reset() end

--- @param ai AiOptions
--- @return void
function AiStateDeveloper:think(ai) end

return Nyx.class("AiStateDeveloper", AiStateDeveloper, AiState)
--}}}
