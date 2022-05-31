--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseVault
--- @class NodeTraverseVault : NodeTypeTraverse
local NodeTraverseVault = {
    name = "Jump (Vault)",
    description = {
        "Informs the AI of how to traverse the map",
        "by vaulting over an obstacle."
    },
    colorSecondary = Color:hsla(150, 0.8, 0.6),
    isJump = true
}

--- @param fields NodeTraverseVault
--- @return NodeTraverseVault
function NodeTraverseVault:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseVault", NodeTraverseVault, NodeTypeTraverse)
--}}}
