--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeObjective = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeObjective"
--}}}

--{{{ NodeObjectiveCtSpawn
--- @class NodeObjectiveCtSpawn : NodeTypeObjective
local NodeObjectiveCtSpawn = {
    name = "CT Spawn",
    description = {
        "This node represents Counter-Terrorist spawn.",
    },
    colorPrimary = Color:hsla(0, 1, 1),
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeObjectiveCtSpawn
--- @return NodeObjectiveCtSpawn
function NodeObjectiveCtSpawn:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeObjectiveCtSpawn", NodeObjectiveCtSpawn, NodeTypeObjective)
--}}}
