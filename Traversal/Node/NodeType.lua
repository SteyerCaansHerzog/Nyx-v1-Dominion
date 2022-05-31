--{{{ Node
--- @class NodeType
local NodeType = {
    defend = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeDefend",
    goal = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGoal",
    grenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade",
    hint = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeHint",
    objective = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeObjective",
    spot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot",
    traverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse",
}

return NodeType
--}}}
