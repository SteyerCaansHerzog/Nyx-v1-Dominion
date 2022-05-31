--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeSmokeRetakeCt
--- @class NodeGrenadeSmokeRetakeCt : NodeTypeGrenade
local NodeGrenadeSmokeRetakeCt = {
    name = "Retake Smoke (CT)",
    description = {
        "Smoke spot for the CT AI when retaking the bombsite."
    },
    colorPrimary = Color:hsla(200, 0, 0.85),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeGrenadeSmokeRetakeCt
--- @return NodeGrenadeSmokeRetakeCt
function NodeGrenadeSmokeRetakeCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeSmokeRetakeCt", NodeGrenadeSmokeRetakeCt, NodeTypeGrenade)
--}}}
