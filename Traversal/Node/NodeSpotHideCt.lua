--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotHideCt
--- @class NodeSpotHideCt : NodeTypeSpot
local NodeSpotHideCt = {
    name = "Hide (CT)",
    description = {
        "Informs the AI of hiding spots on the map.",
        "",
        "- The AI will use these to hide.",
        "- The AI will check these corners when passing by."
    },
    colorSecondary = ColorList.COUNTER_TERRORIST,
    isDirectional = true,
    lookZOffset = 28
}

--- @param fields NodeSpotHideCt
--- @return NodeSpotHideCt
function NodeSpotHideCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotHideCt", NodeSpotHideCt, NodeTypeSpot)
--}}}
