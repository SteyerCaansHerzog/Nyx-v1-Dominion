--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeExplosiveDefendT
--- @class NodeGrenadeExplosiveDefendT : NodeTypeGrenade
local NodeGrenadeExplosiveDefendT = {
    name = "Hold HE Grenade (T)",
    description = {
        "HE spot for the T AI when defending the bombsite."
    },
    colorPrimary = Color:hsla(0, 0.9, 0.85),
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeGrenadeExplosiveDefendT
--- @return NodeGrenadeExplosiveDefendT
function NodeGrenadeExplosiveDefendT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeExplosiveDefendT", NodeGrenadeExplosiveDefendT, NodeTypeGrenade)
--}}}
