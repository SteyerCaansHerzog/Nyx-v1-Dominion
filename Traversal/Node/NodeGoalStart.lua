--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeGoal = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGoal"
--}}}

--{{{ NodeGoalStart
--- @class NodeGoalStart : NodeTypeTraverse
local NodeGoalStart = {
    name = "Start",
    description = {},
    colorSecondary = Color:hsla(338, 0.9, 0.65),
    isHiddenFromEditor = true
}

--- @param fields NodeGoalStart
--- @return NodeGoalStart
function NodeGoalStart:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGoalStart", NodeGoalStart, NodeTypeGoal)
--}}}
