--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeDefend = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeDefend"
--}}}

--{{{ NodeDefendHostageT
--- @class NodeDefendHostageT : NodeTypeDefend
local NodeDefendHostageT = {
	name = "Defend Hostage (T)",
	description = {
		"Informs T AI of how to defend the hostage area.",
		"",
		"- AI will sometimes jiggle on this node.",
		"- This node is paired with the closest node of this type."
	},
	colorPrimary = Color:hsla(40, 0.8, 0.6),
	colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeDefendHostageT
--- @return NodeDefendHostageT
function NodeDefendHostageT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeDefendHostageT", NodeDefendHostageT, NodeTypeDefend)
--}}}
