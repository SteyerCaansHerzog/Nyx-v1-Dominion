--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseLadderTop
--- @class NodeTraverseLadderTop : NodeTypeTraverse
local NodeTraverseLadderTop = {
    name = "Ladder (Top)",
    description = {
        "Informs the AI of how to traverse the map via ladders."
    },
    colorSecondary = Color:hsla(40, 0.8, 0.6),
    isPlanar = false,
    isDirectional = true,
    traversalCost = 150,
}

--- @param fields NodeTraverseLadderTop
--- @return NodeTraverseLadderTop
function NodeTraverseLadderTop:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @return string
function NodeTraverseLadderTop:getError(nodegraph)
    local isConnected = false

    for _, connection in pairs(self.connections) do
        if connection.__classname == "NodeTraverseLadderBottom" then
            isConnected = true

            break
        end
    end

    return not isConnected and "No ladder bottom"
end

return Nyx.class("NodeTraverseLadderTop", NodeTraverseLadderTop, NodeTypeTraverse)
--}}}
