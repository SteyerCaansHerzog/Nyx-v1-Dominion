--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
--}}}

--{{{ NodeTypeTraverse
--- @class NodeTypeTraverse : NodeTypeBase
--- @field isWithinTrafficControlZone boolean
--- @field trafficControlNode NodeHintTrafficControl
local NodeTypeTraverse = {
    type = "Traverse",
    colorPrimary = Color:hsla(235, 0.16, 0.65),
    isConnectable = true,
    isPathable = true,
    isTraversal = true,
}

--- @param fields NodeTypeTraverse
--- @return NodeTypeTraverse
function NodeTypeTraverse:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("NodeTypeTraverse", NodeTypeTraverse, NodeTypeBase)
--}}}
