--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateSweep
--- @class AiStateSweep : AiStateBase
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

    if not Pathfinder.isOnValidPath() then
        self:move()
    end
end

--- @return void
function AiStateSweep:move()
    Pathfinder.moveToNode(Nodegraph.getRandom(Node.traverseGeneric), {
        task = "Sweep the map",
        goalReachedRadius = 100
    })
end

return Nyx.class("AiStateSweep", AiStateSweep, AiStateBase)
--}}}
