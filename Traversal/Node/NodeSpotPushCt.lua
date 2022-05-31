--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotPushCt
--- @class NodeSpotPushCt : NodeTypeSpot
local NodeSpotPushCt = {
    name = "Push (CT)",
    description = {
        "Informs the CT AI of how to push the map."
    },
    colorPrimary = Color:hsla(310, 0.8, 0.8),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeSpotPushCt
--- @return NodeSpotPushCt
function NodeSpotPushCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotPushCt", NodeSpotPushCt, NodeTypeSpot)
--}}}
