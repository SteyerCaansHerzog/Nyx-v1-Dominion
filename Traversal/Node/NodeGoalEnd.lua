--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeGoal = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGoal"
--}}}

--{{{ NodeGoalEnd
--- @class NodeGoalEnd : NodeTypeGoal
local NodeGoalEnd = {
    name = "End",
    description = {},
    colorSecondary = Color:hsla(338, 0.9, 0.65),
    isHiddenFromEditor = true
}

--- @param fields NodeGoalEnd
--- @return NodeGoalEnd
function NodeGoalEnd:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGoalEnd", NodeGoalEnd, NodeTypeGoal)
--}}}
