--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeObjective = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeObjective"
--}}}

--{{{ NodeObjectiveBombsiteA
--- @class NodeObjectiveBombsiteA : NodeTypeObjective
local NodeObjectiveBombsiteA = {
    name = "Bombsite A",
    description = {
        "This node represents bombsite A.",
    },
    colorPrimary = Color:hsla(0, 1, 1),
    colorSecondary = Color:hsla(0, 0.8, 0.65),
    bombsite = "A"
}

--- @param fields NodeObjectiveBombsiteA
--- @return NodeObjectiveBombsiteA
function NodeObjectiveBombsiteA:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeObjectiveBombsiteA", NodeObjectiveBombsiteA, NodeTypeObjective)
--}}}
