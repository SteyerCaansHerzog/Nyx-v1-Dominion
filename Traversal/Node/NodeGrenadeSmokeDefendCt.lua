--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeSmokeDefendCt
--- @class NodeGrenadeSmokeDefendCt : NodeTypeGrenade
local NodeGrenadeSmokeDefendCt = {
    name = "Defensive Smoke (CT)",
    description = {
        "Smoke spot for the CT AI when defending the map."
    },
    colorPrimary = Color:hsla(200, 0, 0.85),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeGrenadeSmokeDefendCt
--- @return NodeGrenadeSmokeDefendCt
function NodeGrenadeSmokeDefendCt:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeSmokeDefendCt", NodeGrenadeSmokeDefendCt, NodeTypeGrenade)
--}}}
