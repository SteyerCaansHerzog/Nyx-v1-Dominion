--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotTrafficQueue
--- @class NodeSpotTrafficQueue : NodeTypeSpot
--- @field trafficControl NodeHintTrafficControl
local NodeSpotTrafficQueue = {
    name = "Traffic Queue",
    description = {
        "Informs the AI of where to wait when its",
        " corresponding traffic control is occupied.",
        "",
        "- The AI will use these to wait for ",
        "teammates to pass through the zone."
    },
    colorPrimary = Color:hsla(15, 0.8, 0.45),
    colorSecondary = Color:hsla(15, 0.8, 0.65),
    isDirectional = true
}

--- @param fields NodeSpotTrafficQueue
--- @return NodeSpotTrafficQueue
function NodeSpotTrafficQueue:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeSpotTrafficQueue:render(nodegraph, isRenderingMetaData)
    NodeTypeSpot.render(self, nodegraph, isRenderingMetaData)

    if not self:isRenderable() then
        return
    end

    if self.trafficControl then
        self.origin:drawLine(self.trafficControl.origin, self.renderColorPrimary)
    end
end

--- @param nodegraph Nodegraph
--- @return boolean
function NodeSpotTrafficQueue:getError(nodegraph)
    if not self.trafficControl then
        return "No linked traffic control"
    end

    return NodeTypeSpot.getError(self, nodegraph)
end

return Nyx.class("NodeSpotTrafficQueue", NodeSpotTrafficQueue, NodeTypeSpot)
--}}}
