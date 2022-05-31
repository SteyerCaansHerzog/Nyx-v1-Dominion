--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeFlashbangDefendCt
--- @class NodeGrenadeFlashbangDefendCt : NodeTypeGrenade
local NodeGrenadeFlashbangDefendCt = {
    name = "Defensive Flashbang (CT)",
    description = {
        "Flashbang spot for the CT AI when defending the map."
    },
    colorPrimary = Color:hsla(200, 0.9, 0.85),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeGrenadeFlashbangDefendCt
--- @return NodeGrenadeFlashbangDefendCt
function NodeGrenadeFlashbangDefendCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeFlashbangDefendCt", NodeGrenadeFlashbangDefendCt, NodeTypeGrenade)
--}}}
