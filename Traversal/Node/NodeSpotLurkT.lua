--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotLurkT
--- @class NodeSpotLurkT : NodeTypeSpot
local NodeSpotLurkT = {
    name = "Lurk (General)",
    description = {
        "Informs the AI of lurk spots when T-side.",
        "",
        "- The AI will use these to wait at opposite sites."
    },
    colorSecondary = Color:hsla(80, 0.8, 0.7),
    isDirectional = true,
    isLinkedToBombsite = true
}

--- @param fields NodeSpotLurkT
--- @return NodeSpotLurkT
function NodeSpotLurkT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotLurkT", NodeSpotLurkT, NodeTypeSpot)
--}}}
