--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotOntoPositionBoostEndCt
--- @class NodeSpotOntoPositionBoostEndCt : NodeTypeSpot
local NodeSpotOntoPositionBoostEndCt = {
    name = "Boost Position End (CT)",
    description = {
        "Informs the CT AI of boost spots.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorPrimary = Color:hsla(20, 0.8, 0.6),
    colorSecondary = ColorList.COUNTER_TERRORIST,
    isDirectional = true,
}

--- @param fields NodeSpotOntoPositionBoostEndCt
--- @return NodeSpotOntoPositionBoostEndCt
function NodeSpotOntoPositionBoostEndCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotOntoPositionBoostEndCt", NodeSpotOntoPositionBoostEndCt, NodeTypeSpot)
--}}}
