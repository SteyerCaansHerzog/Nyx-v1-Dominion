--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeFlashbangRetakeCt
--- @class NodeGrenadeFlashbangRetakeCt : NodeTypeGrenade
local NodeGrenadeFlashbangRetakeCt = {
    name = "Retake Flashbang (CT)",
    description = {
        "Flashbang spot for the CT AI when retaking the bombsite."
    },
    colorPrimary = Color:hsla(200, 0.9, 0.85),
    colorSecondary = ColorList.COUNTER_TERRORIST,
    isUnused = true
}

--- @param fields NodeGrenadeFlashbangRetakeCt
--- @return NodeGrenadeFlashbangRetakeCt
function NodeGrenadeFlashbangRetakeCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeFlashbangRetakeCt", NodeGrenadeFlashbangRetakeCt, NodeTypeGrenade)
--}}}
