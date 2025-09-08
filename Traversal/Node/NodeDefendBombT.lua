--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeDefend = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeDefend"
--}}}

--{{{ NodeDefendBombT
--- @class NodeDefendBombT : NodeTypeDefend
local NodeDefendBombT = {
	name = "Defend Bomb (T)",
	description = {
		"Informs T AI of how to defend the bomb planter.",
		"",
		"- AI will sometimes jiggle on this node.",
		"- This node is paired with the closest node of this type."
	},
	colorPrimary = Color:hsla(100, 0.8, 0.6),
	colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeDefendBombT
--- @return NodeDefendBombT
function NodeDefendBombT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeDefendBombT", NodeDefendBombT, NodeTypeDefend)
--}}}
