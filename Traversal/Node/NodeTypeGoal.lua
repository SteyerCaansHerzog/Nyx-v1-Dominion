--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
--}}}

--{{{ NodeTypeGoal
--- @class NodeTypeGoal : NodeTypeBase
local NodeTypeGoal = {
    type = "Goal",
    colorPrimary = Color:hsla(338, 0.54, 0.48),
    isTransient = true,
    isGoal = true
}

--- @param fields NodeTypeGoal
--- @return NodeTypeGoal
function NodeTypeGoal:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("NodeTypeGoal", NodeTypeGoal, NodeTypeBase)
--}}}
