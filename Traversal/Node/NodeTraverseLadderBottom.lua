--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseLadderBottom
--- @class NodeTraverseLadderBottom : NodeTypeTraverse
local NodeTraverseLadderBottom = {
    name = "Ladder (Bottom)",
    description = {
        "Informs the AI of how to traverse the map via ladders."
    },
    colorSecondary = Color:hsla(50, 0.8, 0.6),
    isPlanar = false,
    isDirectional = true
}

--- @param fields NodeTraverseLadderBottom
--- @return NodeTraverseLadderBottom
function NodeTraverseLadderBottom:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseLadderBottom", NodeTraverseLadderBottom, NodeTypeTraverse)
--}}}
