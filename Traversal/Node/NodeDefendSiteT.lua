--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeDefend = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeDefend"
--}}}

--{{{ NodeDefendSiteT
--- @class NodeDefendSiteT : NodeTypeDefend
local NodeDefendSiteT = {
	name = "Defend Site (T)",
	description = {
		"Informs T AI of how to hold the bombsite.",
		"",
		"- AI will sometimes jiggle on this node.",
		"- This node is paired with the closest node of this type."
	},
	colorPrimary = Color:hsla(150, 0.8, 0.6),
	colorSecondary = ColorList.TERRORIST,
	isLinkedToBombsite = true
}

--- @param fields NodeDefendSiteT
--- @return NodeDefendSiteT
function NodeDefendSiteT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeDefendSiteT", NodeDefendSiteT, NodeTypeDefend)
--}}}
