--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotLurkCt
--- @class NodeSpotLurkCt : NodeTypeSpot
local NodeSpotLurkCt = {
    name = "Lurk (CT)",
    description = {
        "Informs the AI of lurk spots when CT-side",
        "and picking bombsite.",
        "",
        "- The AI will use these to pick enemies leaving a bombsite."
    },
    colorPrimary = Color:hsla(60, 0.8, 0.7),
    colorSecondary = ColorList.COUNTER_TERRORIST,
    isDirectional = true,
    isLinkedToBombsite = true
}

--- @param fields NodeSpotLurkCt
--- @return NodeSpotLurkCt
function NodeSpotLurkCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotLurkCt", NodeSpotLurkCt, NodeTypeSpot)
--}}}
