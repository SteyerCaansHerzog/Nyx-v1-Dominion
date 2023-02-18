--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeOntoPositionStartBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeOntoPositionStartBoost"
local NodeSpotOntoPositionBoostEndT = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeSpotOntoPositionBoostEndT"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotOntoPositionBoostStartT
--- @class NodeSpotOntoPositionBoostStartT : NodeTypeOntoPositionStartBoost
local NodeSpotOntoPositionBoostStartT = {
    name = "Boost Position Start (T)",
    description = {
        "Informs the T AI of boost spots.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorSecondary = ColorList.TERRORIST,
    endNodeClass = NodeSpotOntoPositionBoostEndT
}

--- @param fields NodeSpotOntoPositionBoostStartT
--- @return NodeSpotOntoPositionBoostStartT
function NodeSpotOntoPositionBoostStartT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotOntoPositionBoostStartT", NodeSpotOntoPositionBoostStartT, NodeTypeOntoPositionStartBoost)
--}}}
