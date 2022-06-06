--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeObjective = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeObjective"
--}}}

--{{{ NodeObjectiveBombsiteB
--- @class NodeObjectiveBombsiteB : NodeTypeObjective
local NodeObjectiveBombsiteB = {
    name = "Bombsite B",
    description = {
        "This node represents bombsite B.",
    },
    colorPrimary = Color:hsla(0, 1, 1),
    colorSecondary = Color:hsla(225, 0.8, 0.65),
    bombsite = "B"
}

--- @param fields NodeObjectiveBombsiteB
--- @return NodeObjectiveBombsiteB
function NodeObjectiveBombsiteB:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeObjectiveBombsiteB", NodeObjectiveBombsiteB, NodeTypeObjective)
--}}}
