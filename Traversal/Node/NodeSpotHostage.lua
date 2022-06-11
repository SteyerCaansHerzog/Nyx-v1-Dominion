--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotHostage
--- @class NodeSpotHostage : NodeTypeSpot
local NodeSpotHostage = {
    name = "Hostage Point",
    description = {
        "This node represents a potential hostage location.",
    },
    colorSecondary = Color:hsla(100, 0.8, 0.7)
}

--- @param fields NodeSpotHostage
--- @return NodeSpotHostage
function NodeSpotHostage:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotHostage", NodeSpotHostage, NodeTypeSpot)
--}}}
