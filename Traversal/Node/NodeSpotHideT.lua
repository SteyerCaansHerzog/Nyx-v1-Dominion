--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotHideT
--- @class NodeSpotHideT : NodeTypeSpot
local NodeSpotHideT = {
    name = "Hide (T)",
    description = {
        "Informs the AI of hiding spots on the map.",
        "",
        "- The AI will use these to hide.",
        "- The AI will check these corners when passing by."
    },
    colorSecondary = ColorList.TERRORIST,
    isDirectional = true,
    lookZOffset = 28
}

--- @param fields NodeSpotHideT
--- @return NodeSpotHideT
function NodeSpotHideT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotHideT", NodeSpotHideT, NodeTypeSpot)
--}}}
