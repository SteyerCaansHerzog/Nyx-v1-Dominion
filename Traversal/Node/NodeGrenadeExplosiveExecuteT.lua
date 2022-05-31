--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeExplosiveExecuteT
--- @class NodeGrenadeExplosiveExecuteT : NodeTypeGrenade
local NodeGrenadeExplosiveExecuteT = {
    name = "Execute HE Grenade (T)",
    description = {
        "HE spot for the T AI when executing the bombsite."
    },
    colorPrimary = Color:hsla(0, 0.9, 0.85),
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeGrenadeExplosiveExecuteT
--- @return NodeGrenadeExplosiveExecuteT
function NodeGrenadeExplosiveExecuteT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeExplosiveExecuteT", NodeGrenadeExplosiveExecuteT, NodeTypeGrenade)
--}}}
