--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseGeneric
--- @class NodeTraverseGeneric : NodeTypeTraverse
local NodeTraverseGeneric = {
    name = "Run (Volume)",
    description = {
        "Informs the AI of how to traverse the map by walking."
    },
    isPlanar = true,
    isNameHidden = true,
    colorSecondary = Color:hsla(235, 0.3, 0.7)
}

--- @param fields NodeTraverseGeneric
--- @return NodeTraverseGeneric
function NodeTraverseGeneric:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseGeneric", NodeTraverseGeneric, NodeTypeTraverse)
--}}}
