--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotWaitOnBoost
--- @class NodeSpotWaitOnBoost : NodeTypeSpot
--- @field chance number
local NodeSpotWaitOnBoost = {
    name = "Wait on Boost (CT)",
    description = {
        "Informs the AI of where to wait on boosts."
    },
    colorPrimary = Color:hsla(20, 0.8, 0.6),
    colorSecondary = Color:hsla(0, 1, 1),
    isDirectional = true
}

--- @param fields NodeSpotWaitOnBoost
--- @return NodeSpotWaitOnBoost
function NodeSpotWaitOnBoost:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotWaitOnBoost", NodeSpotWaitOnBoost, NodeTypeSpot)
--}}}
