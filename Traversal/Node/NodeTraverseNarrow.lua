--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseNarrow
--- @class NodeTraverseNarrow : NodeTypeTraverse
local NodeTraverseNarrow = {
    name = "Narrow",
    description = {
        "Informs the AI of how to traverse the map by walking.",
        "Intended for narrow throughways."
    },
    isPlanar = false,
    colorSecondary = Color:hsla(235, 0.65, 0.7)
}

--- @param fields NodeTraverseNarrow
--- @return NodeTraverseNarrow
function NodeTraverseNarrow:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseNarrow", NodeTraverseNarrow, NodeTypeTraverse)
--}}}
