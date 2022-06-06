--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseDoor
--- @class NodeTraverseDoor : NodeTypeTraverse
local NodeTraverseDoor = {
    name = "Door",
    description = {
        "Informs the AI of how to traverse the map through doors."
    },
    colorSecondary = Color:hsla(20, 0.8, 0.6)
}

--- @param fields NodeTraverseDoor
--- @return NodeTraverseDoor
function NodeTraverseDoor:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTraverseDoor", NodeTraverseDoor, NodeTypeTraverse)
--}}}
