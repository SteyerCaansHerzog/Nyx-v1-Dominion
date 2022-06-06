--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseClamber
--- @class NodeTraverseClamber : NodeTypeTraverse
local NodeTraverseClamber = {
    name = "Jump (Clamber)",
    description = {
        "Informs the AI of how to traverse the map",
        "by crouching before climbing an obstacle.",
        "",
        "- Use for tricky jumps where crouch is needed."
    },
    colorSecondary = Color:hsla(60, 0.8, 0.6),
    isJump = true,
    isCollisionTestWeak = true,
    zDeltaThreshold = 80,
}

--- @param fields NodeTraverseClamber
--- @return NodeTraverseClamber
function NodeTraverseClamber:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseClamber", NodeTraverseClamber, NodeTypeTraverse)
--}}}
