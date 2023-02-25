--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeFlashbangDefendT
--- @class NodeGrenadeFlashbangDefendT : NodeTypeGrenade
local NodeGrenadeFlashbangDefendT = {
    name = "Hold Flashbang (T)",
    description = {
        "Flashbang spot for the T AI when defending the bombsite."
    },
    colorPrimary = Color:hsla(200, 0.9, 0.85),
    colorSecondary = ColorList.TERRORIST,
    isUnused = true
}

--- @param fields NodeGrenadeFlashbangDefendT
--- @return NodeGrenadeFlashbangDefendT
function NodeGrenadeFlashbangDefendT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeFlashbangDefendT", NodeGrenadeFlashbangDefendT, NodeTypeGrenade)
--}}}
