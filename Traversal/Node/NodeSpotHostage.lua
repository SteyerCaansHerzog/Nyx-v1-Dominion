--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotHostage
--- @class NodeSpotHostage : NodeTypeSpot
local NodeSpotHostage = {
    name = "Hostage Point",
    description = {
        "This node represents a potential hostage location.",
    },
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeSpotHostage
--- @return NodeSpotHostage
function NodeSpotHostage:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotHostage", NodeSpotHostage, NodeTypeSpot)
--}}}
