--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeObjective = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeObjective"
--}}}

--{{{ NodeObjectiveMiddle
--- @class NodeObjectiveMiddle : NodeTypeObjective
local NodeObjectiveMiddle = {
    name = "Middle",
    description = {
        "This node represents the middle of the map.",
    },
    colorPrimary = Color:hsla(0, 1, 1),
    colorSecondary = Color:hsla(120, 0.8, 0.6),
}

--- @param fields NodeObjectiveMiddle
--- @return NodeObjectiveMiddle
function NodeObjectiveMiddle:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeObjectiveMiddle", NodeObjectiveMiddle, NodeTypeObjective)
--}}}
