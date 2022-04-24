--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
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
    return AiPriority.IGNORE
end

--- @return void
function AiStateDeveloper:activate()
    local node =self.ai.nodegraph.nodes[382]

   self.ai.nodegraph:pathfind(node.origin)
end

--- @return void
function AiStateDeveloper:reset() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDeveloper:think(cmd)
    self.activity = "Testing"
end

return Nyx.class("AiStateDeveloper", AiStateDeveloper, AiState)
--}}}
