--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotPlant
--- @class NodeSpotPlant : NodeTypeSpot
local NodeSpotPlant = {
    name = "Plant",
    description = {
        "Informs the AI of locations to plant the bomb."
    },
    colorSecondary = Color:hsla(350, 0.8, 0.7),
    isLinkedToBombsite = true,
    isDirectional = true,
}

--- @param fields NodeSpotPlant
--- @return NodeSpotPlant
function NodeSpotPlant:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotPlant", NodeSpotPlant, NodeTypeSpot)
--}}}
