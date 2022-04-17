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
--- @return void
function AiStateSweep:activate(ai)
    self:move(ai)
end

--- @param ai AiOptions
--- @return void
function AiStateSweep:think(ai)
    self.activity = "Sweeping the map"
end

--- @param ai AiOptions
--- @return void
function AiStateSweep:move(ai)
    ai.nodegraph:pathfind(ai.nodegraph:getRandomNodeWithin(AiUtility.client:getOrigin(), 8192).origin, {
        objective = Node.types.GOAL,
        retry = false,
        ignore = Client.getEid(),
        task = string.format("Sweeping the map"),
        onComplete = function()
            self:move(ai)
        end
    })
end

return Nyx.class("AiStateSweep", AiStateSweep, AiState)
--}}}
