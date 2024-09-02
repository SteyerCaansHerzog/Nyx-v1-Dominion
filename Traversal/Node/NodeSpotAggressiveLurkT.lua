--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotAggressiveLurkT
--- @class NodeSpotAggressiveLurkT : NodeTypeSpot
local NodeSpotAggressiveLurkT = {
    name = "Aggressive Lurk (T)",
    description = {
        "Informs the AI of lurk spots when T-side near bombsites to catch rotates.",
        "",
        "- The AI will use these to catch CTs off-guard."
    },
    colorPrimary = Color:hsla(60, 0.8, 0.7),
    colorSecondary = ColorList.TERRORIST,
    isDirectional = true,
    isLinkedToBombsite = true
}

--- @param fields NodeSpotAggressiveLurkT
--- @return NodeSpotAggressiveLurkT
function NodeSpotAggressiveLurkT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotAggressiveLurkT", NodeSpotAggressiveLurkT, NodeTypeSpot)
--}}}
