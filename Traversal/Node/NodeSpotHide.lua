--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotHide
--- @class NodeSpotHide : NodeTypeSpot
local NodeSpotHide = {
    name = "Hide",
    description = {
        "Informs the AI of hiding spots on the map.",
        "",
        "- The AI will use these to hide.",
        "- The AI will check these corners when passing by."
    },
    colorSecondary = Color:hsla(55, 0.8, 0.6),
    isDirectional = true,
    lookZOffset = 28
}

--- @param fields NodeSpotHide
--- @return NodeSpotHide
function NodeSpotHide:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotHide", NodeSpotHide, NodeTypeSpot)
--}}}
