--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseDrop
--- @class NodeTraverseDrop : NodeTypeTraverse
local NodeTraverseDrop = {
    name = "Jump (Drop)",
    description = {
        "Informs the AI of how to traverse the map",
        "by dropping down a ledge."
    },
    colorSecondary = Color:hsla(250, 0.8, 0.72),
    isJump = true,
    traversalCost = 0,
    zDeltaThreshold = 32,
    zDeltaGoalThreshold = 32,
}

--- @param fields NodeTraverseDrop
--- @return NodeTraverseDrop
function NodeTraverseDrop:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseDrop", NodeTraverseDrop, NodeTypeTraverse)
--}}}
