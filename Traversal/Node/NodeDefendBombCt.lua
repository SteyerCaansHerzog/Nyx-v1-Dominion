--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeDefend = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeDefend"
--}}}

--{{{ NodeDefendBombCt
--- @class NodeDefendBombCt : NodeTypeDefend
local NodeDefendBombCt = {
	name = "Defend Bomb (CT)",
	description = {
		"Informs CT AI of how to defend the bomb defuser.",
		"",
		"- AI will sometimes jiggle on this node.",
		"- This node is paired with the closest node of this type."
	},
	colorPrimary = Color:hsla(100, 0.8, 0.6),
	colorSecondary = ColorList.COUNTER_TERRORIST,
}

--- @param fields NodeDefendBombCt
--- @return NodeDefendBombCt
function NodeDefendBombCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeDefendBombCt", NodeDefendBombCt, NodeTypeDefend)
--}}}
