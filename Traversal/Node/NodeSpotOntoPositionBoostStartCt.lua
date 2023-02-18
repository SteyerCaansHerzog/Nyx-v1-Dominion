--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeOntoPositionStartBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeOntoPositionStartBoost"
local NodeSpotOntoPositionBoostEndCt = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeSpotOntoPositionBoostEndCt"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotOntoPositionBoostStartCt
--- @class NodeSpotOntoPositionBoostStartCt : NodeTypeOntoPositionStartBoost
local NodeSpotOntoPositionBoostStartCt = {
    name = "Boost Position Start (CT)",
    description = {
        "Informs the CT AI of boost spots.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorSecondary = ColorList.COUNTER_TERRORIST,
    endNodeClass = NodeSpotOntoPositionBoostEndCt
}

--- @param fields NodeSpotOntoPositionBoostStartCt
--- @return NodeSpotOntoPositionBoostStartCt
function NodeSpotOntoPositionBoostStartCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotOntoPositionBoostStartCt", NodeSpotOntoPositionBoostStartCt, NodeTypeOntoPositionStartBoost)
--}}}
