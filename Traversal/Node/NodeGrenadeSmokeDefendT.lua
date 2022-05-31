--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeSmokeDefendT
--- @class NodeGrenadeSmokeDefendT : NodeTypeGrenade
local NodeGrenadeSmokeDefendT = {
    name = "Defensive Smoke (T)",
    description = {
        "Smoke spot for the T AI when defending the bombsite."
    },
    colorPrimary = Color:hsla(200, 0, 0.85),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeGrenadeSmokeDefendT
--- @return NodeGrenadeSmokeDefendT
function NodeGrenadeSmokeDefendT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeSmokeDefendT", NodeGrenadeSmokeDefendT, NodeTypeGrenade)
--}}}
