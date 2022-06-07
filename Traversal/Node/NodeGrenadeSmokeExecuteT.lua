--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeSmokeExecuteT
--- @class NodeGrenadeSmokeExecuteT : NodeTypeGrenade
local NodeGrenadeSmokeExecuteT = {
    name = "Execute Smoke (T)",
    description = {
        "Smoke spot for the T AI when defending the bombsite."
    },
    colorPrimary = Color:hsla(200, 0, 0.85),
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeGrenadeSmokeExecuteT
--- @return NodeGrenadeSmokeExecuteT
function NodeGrenadeSmokeExecuteT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeSmokeExecuteT", NodeGrenadeSmokeExecuteT, NodeTypeGrenade)
--}}}
