--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeExplosiveRetakeCt
--- @class NodeGrenadeExplosiveRetakeCt : NodeTypeGrenade
local NodeGrenadeExplosiveRetakeCt = {
    name = "Retake HE Grenade (CT)",
    description = {
        "HE spot for the CT AI when retaking the bombsite."
    },
    colorPrimary = Color:hsla(0, 0.9, 0.85),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeGrenadeExplosiveRetakeCt
--- @return NodeGrenadeExplosiveRetakeCt
function NodeGrenadeExplosiveRetakeCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeExplosiveRetakeCt", NodeGrenadeExplosiveRetakeCt, NodeTypeGrenade)
--}}}
