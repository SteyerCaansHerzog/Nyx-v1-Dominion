--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseBreakObstacle
--- @class NodeTraverseBreakObstacle : NodeTypeTraverse
--- @field customStuff boolean
local NodeTraverseBreakObstacle = {
    name = "Break Obstacle",
    description = {
        "Informs the AI of how to traverse the map when breaking",
        "obstacles."
    },
    colorSecondary = Color:hsla(0, 0.8, 0.6),
    isDirectional = true
}

--- @param fields NodeTraverseBreakObstacle
--- @return NodeTraverseBreakObstacle
function NodeTraverseBreakObstacle:new(fields)
	return Nyx.new(self, fields)
end

--- @param menu MenuGroup
--- @return void
function NodeTraverseBreakObstacle:setCustomizers(menu)
    NodeTypeTraverse.setCustomizers(self, menu)

    self:addCustomizer("isDuck", function()
        return menu.group:addCheckbox("    > Duck when passing")
    end)
end

return Nyx.class("NodeTraverseBreakObstacle", NodeTraverseBreakObstacle, NodeTypeTraverse)
--}}}
