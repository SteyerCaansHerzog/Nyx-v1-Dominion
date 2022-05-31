--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeInfernoExecuteT
--- @class NodeGrenadeInfernoExecuteT : NodeTypeGrenade
local NodeGrenadeInfernoExecuteT = {
    name = "Execute Inferno (T)",
    description = {
        "Inferno spot for the T AI when executing the bombsite."
    },
    colorPrimary = Color:hsla(50, 0.9, 0.85),
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeGrenadeInfernoExecuteT
--- @return NodeGrenadeInfernoExecuteT
function NodeGrenadeInfernoExecuteT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeInfernoExecuteT", NodeGrenadeInfernoExecuteT, NodeTypeGrenade)
--}}}
