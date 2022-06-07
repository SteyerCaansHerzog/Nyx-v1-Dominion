--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseDuck
--- @class NodeTraverseDuck : NodeTypeTraverse
local NodeTraverseDuck = {
    name = "Duck",
    description = {
        "Informs the AI of how to traverse the map by ducking."
    },
    colorSecondary = Color:hsla(320, 0.8, 0.66),
    isDuck = true,
    traversalCost = 75,
}

--- @param fields NodeTraverseDuck
--- @return NodeTraverseDuck
function NodeTraverseDuck:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseDuck", NodeTraverseDuck, NodeTypeTraverse)
--}}}
