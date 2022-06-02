--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseClimb
--- @class NodeTraverseClimb : NodeTypeTraverse
local NodeTraverseClimb = {
    name = "Jump (Climb)",
    description = {
        "Informs the AI of how to traverse the map",
        "by climbing an obstacle."
    },
    colorSecondary = Color:hsla(100, 0.8, 0.6),
    isJump = true,
    isCollisionTestWeak = true
}

--- @param fields NodeTraverseClimb
--- @return NodeTraverseClimb
function NodeTraverseClimb:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseClimb", NodeTraverseClimb, NodeTypeTraverse)
--}}}
