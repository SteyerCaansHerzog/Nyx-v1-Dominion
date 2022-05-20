--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
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
    return AiPriority.SWEEP
end

--- @return void
function AiStateSweep:activate()
    self:move()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateSweep:think(cmd)
    self.activity = "Sweeping the map"

    if self.ai.nodegraph:isIdle() then
        self:move()
    end
end

--- @return void
function AiStateSweep:move()
   self.ai.nodegraph:pathfind(self.ai.nodegraph:getRandomNodeWithin(AiUtility.client:getOrigin(), 8192).origin, {
        objective = Node.types.GOAL,
        task = string.format("Sweeping the map")
    })
end

return Nyx.class("AiStateSweep", AiStateSweep, AiState)
--}}}
