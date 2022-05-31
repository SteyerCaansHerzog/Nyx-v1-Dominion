--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeInfernoDefendCt
--- @class NodeGrenadeInfernoDefendCt : NodeTypeGrenade
local NodeGrenadeInfernoDefendCt = {
    name = "Defensive Inferno (CT)",
    description = {
        "Inferno spot for the CT AI when defending the map."
    },
    colorPrimary = Color:hsla(50, 0.9, 0.85),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeGrenadeInfernoDefendCt
--- @return NodeGrenadeInfernoDefendCt
function NodeGrenadeInfernoDefendCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeInfernoDefendCt", NodeGrenadeInfernoDefendCt, NodeTypeGrenade)
--}}}
