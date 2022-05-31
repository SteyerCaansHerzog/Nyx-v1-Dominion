--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeInfernoRetakeCt
--- @class NodeGrenadeInfernoRetakeCt : NodeTypeGrenade
local NodeGrenadeInfernoRetakeCt = {
    name = "Retake Inferno (CT)",
    description = {
        "Inferno spot for the CT AI when retaking the bombsite."
    },
    colorPrimary = Color:hsla(50, 0.9, 0.85),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeGrenadeInfernoRetakeCt
--- @return NodeGrenadeInfernoRetakeCt
function NodeGrenadeInfernoRetakeCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeInfernoRetakeCt", NodeGrenadeInfernoRetakeCt, NodeTypeGrenade)
--}}}
