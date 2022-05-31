--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeObjective = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeObjective"
--}}}

--{{{ NodeObjectiveTSpawn
--- @class NodeObjectiveTSpawn : NodeTypeObjective
local NodeObjectiveTSpawn = {
    name = "T Spawn",
    description = {
        "This node represents Terrorist spawn.",
    },
    colorPrimary = Color:hsla(40, 0.8, 0.6),
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeObjectiveTSpawn
--- @return NodeObjectiveTSpawn
function NodeObjectiveTSpawn:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeObjectiveTSpawn", NodeObjectiveTSpawn, NodeTypeObjective)
--}}}
