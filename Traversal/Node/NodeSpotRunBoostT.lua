--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBoost"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotRunBoostT
--- @class NodeSpotRunBoostT : NodeTypeBoost
local NodeSpotRunBoostT = {
    name = "Run Boost (T)",
    description = {
        "Informs the T AI of run boost spots.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeSpotRunBoostT
--- @return NodeSpotRunBoostT
function NodeSpotRunBoostT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotRunBoostT", NodeSpotRunBoostT, NodeTypeBoost)
--}}}
