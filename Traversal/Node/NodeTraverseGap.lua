--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseGap
--- @class NodeTraverseGap : NodeTypeTraverse
local NodeTraverseGap = {
    name = "Jump (Gap)",
    description = {
        "Informs the AI of how to traverse the map",
        "by clearing gaps."
    },
    colorSecondary = Color:hsla(200, 0.8, 0.6),
    isJump = true
}

--- @param fields NodeTraverseGap
--- @return NodeTraverseGap
function NodeTraverseGap:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseGap", NodeTraverseGap, NodeTypeTraverse)
--}}}
