--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotPushT
--- @class NodeSpotPushT : NodeTypeSpot
local NodeSpotPushT = {
    name = "Push (T)",
    description = {
        "Informs the T AI of how to push the bombsite."
    },
    colorPrimary = Color:hsla(310, 0.8, 0.8),
    colorSecondary = ColorList.TERRORIST,
    isLinkedToBombsite = true
}

--- @param fields NodeSpotPushT
--- @return NodeSpotPushT
function NodeSpotPushT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotPushT", NodeSpotPushT, NodeTypeSpot)
--}}}
