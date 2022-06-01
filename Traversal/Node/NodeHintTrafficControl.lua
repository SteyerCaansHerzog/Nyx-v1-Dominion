--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
local NodeTypeHint = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeHint"
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
local NodeSpotTrafficQueue = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeSpotTrafficQueue"
--}}}

--{{{ NodeHintTrafficControl
--- @class NodeHintTrafficControl : NodeTypeHint
--- @field occupancyRadius number
--- @field queueLinkRadius number
--- @field queueNodes NodeSpotTrafficQueue[]
--- @field traversalNodes NodeTypeTraverse[]
local NodeHintTrafficControl = {
    name = "Traffic Control",
    description = {
        "Watches for teammates occupying this zone.",
        "",
        "- Used with NodeSpotTrafficQueue to tell the AI where to wait",
        "    when the zone is occupied.",
        "- It is only triggered if the AI's path enters the zone. At least",
        "   one traversal node must be  within the occupancy radius."
    },
    colorPrimary = Color:hsla(15, 0.8, 0.45)
}

--- @param fields NodeHintTrafficControl
--- @return NodeHintTrafficControl
function NodeHintTrafficControl:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function NodeHintTrafficControl:__init()
    NodeTypeHint.__init(self)

    self.queueNodes = {}
    self.traversalNodes = {}
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeHintTrafficControl:render(nodegraph, isRenderingMetaData)
    NodeTypeBase.render(self, nodegraph, isRenderingMetaData)

    if not self:isRenderable() then
        return
    end

    if self.occupancyRadius then
        self.origin:clone():offset(0, 0, -18):drawCircle3D(self.occupancyRadius, self.renderColorFovPrimary)
    end

    if self.queueLinkRadius then
        self.origin:clone():offset(0, 0, -18):drawCircle3D(self.queueLinkRadius, self.renderColorFovPrimary:setLightness(0.65))
    end
end

--- @param menu MenuGroup
--- @return void
function NodeHintTrafficControl:setupCustomizers(menu)
    NodeTypeBase.setupCustomizers(self, menu)

    self:addCustomizer("occupancyRadius", function()
        return menu.group:addSlider("    > Occupancy check radius", 1, 15, {
            default = 2,
            scale = 10
        }):onGet(function(value)
            return value * 10
        end)
    end)

    self:addCustomizer("queueLinkRadius", function()
        return menu.group:addSlider("    > Queue node link radius", 1, 40, {
            default = 4,
            scale = 10
        }):onGet(function(value)
            return value * 10
        end)
    end)
end

--- @param nodegraph Nodegraph
--- @return void
function NodeHintTrafficControl:onSetup(nodegraph)
    NodeTypeHint.onSetup(self, nodegraph)

    for _, node in pairs(nodegraph.getOfType(NodeTypeTraverse)) do
        local distance = self.origin:getDistance(node.origin)

        if distance < self.occupancyRadius then
            self:addTraversalNode(node)
        end
    end

    for _, node in pairs(nodegraph.get(NodeSpotTrafficQueue)) do
        local distance = self.origin:getDistance(node.origin)

        if distance < self.queueLinkRadius then
            node.trafficControl = self

            self:addQueueNode(node)
        end
    end
end

--- @param node NodeSpotTrafficQueue
--- @return void
function NodeHintTrafficControl:addQueueNode(node)
    self.queueNodes[node.id] = node
end

--- @param node NodeSpotTrafficQueue
--- @return void
function NodeHintTrafficControl:addTraversalNode(node)
    self.traversalNodes[node.id] = node
end

return Nyx.class("NodeHintTrafficControl", NodeHintTrafficControl, NodeTypeHint)
--}}}
