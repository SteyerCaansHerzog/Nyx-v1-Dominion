--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeGrenade = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeGrenade"
--}}}

--{{{ NodeGrenadeFlashbangExecuteT
--- @class NodeGrenadeFlashbangExecuteT : NodeTypeGrenade
local NodeGrenadeFlashbangExecuteT = {
    name = "Execute Flashbang (T)",
    description = {
        "Flashbang spot for the T AI when executing the bombsite."
    },
    colorPrimary = Color:hsla(200, 0.9, 0.85),
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeGrenadeFlashbangExecuteT
--- @return NodeGrenadeFlashbangExecuteT
function NodeGrenadeFlashbangExecuteT:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeGrenadeFlashbangExecuteT", NodeGrenadeFlashbangExecuteT, NodeTypeGrenade)
--}}}
