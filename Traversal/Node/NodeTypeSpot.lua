--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
--}}}

--{{{ NodeTypeSpot
--- @class NodeTypeSpot : NodeTypeBase
local NodeTypeSpot = {
	type = "Spot",
	colorPrimary = Color:hsla(220, 0.8, 0.7)
}

--- @param fields NodeTypeSpot
--- @return NodeTypeSpot
function NodeTypeSpot:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeTypeSpot", NodeTypeSpot, NodeTypeBase)
--}}}

