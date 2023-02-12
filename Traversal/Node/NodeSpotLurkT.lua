--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotLurkT
--- @class NodeSpotLurkT : NodeTypeSpot
local NodeSpotLurkT = {
    name = "Lurk (T)",
    description = {
        "Informs the AI of lurk spots when T-side.",
        "",
        "- The AI will use these to wait at opposite sites."
    },
    colorPrimary = Color:hsla(60, 0.8, 0.7),
    colorSecondary = ColorList.TERRORIST,
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
