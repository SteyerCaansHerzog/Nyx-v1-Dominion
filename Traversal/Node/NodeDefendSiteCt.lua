--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeDefend = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeDefend"
--}}}

--{{{ NodeDefendSiteCt
--- @class NodeDefendSiteCt : NodeTypeDefend
local NodeDefendSiteCt = {
	name = "Defend Site (CT)",
	description = {
		"Informs CT AI of how to defend the bombsite.",
		"",
		"- AI will sometimes jiggle on this node.",
		"- This node is paired with the closest node of this type."
	},
	colorPrimary = Color:hsla(150, 0.9, 0.6),
	colorSecondary = ColorList.COUNTER_TERRORIST,
	isLinkedToBombsite = true
}

--- @param fields NodeDefendSiteCt
--- @return NodeDefendSiteCt
function NodeDefendSiteCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeDefendSiteCt", NodeDefendSiteCt, NodeTypeDefend)
--}}}
