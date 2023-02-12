--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBoost"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotRunBoostCt
--- @class NodeSpotRunBoostCt : NodeTypeBoost
local NodeSpotRunBoostCt = {
    name = "Run Boost (CT)",
    description = {
        "Informs the CT AI of run boost spots.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeSpotRunBoostCt
--- @return NodeSpotRunBoostCt
function NodeSpotRunBoostCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotRunBoostCt", NodeSpotRunBoostCt, NodeTypeBoost)
--}}}
