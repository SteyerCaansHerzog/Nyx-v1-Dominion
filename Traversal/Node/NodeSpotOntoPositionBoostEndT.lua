--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotOntoPositionBoostEndT
--- @class NodeSpotOntoPositionBoostEndT : NodeTypeSpot
local NodeSpotOntoPositionBoostEndT = {
    name = "Boost Position End (T)",
    description = {
        "Informs the T AI of boost spots.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorPrimary = Color:hsla(20, 0.8, 0.6),
    colorSecondary = ColorList.TERRORIST,
    isDirectional = true,
}

--- @param fields NodeSpotOntoPositionBoostEndT
--- @return NodeSpotOntoPositionBoostEndT
function NodeSpotOntoPositionBoostEndT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotOntoPositionBoostEndT", NodeSpotOntoPositionBoostEndT, NodeTypeSpot)
--}}}
