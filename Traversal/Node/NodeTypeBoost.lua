--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeSpotWaitOnBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeSpotWaitOnBoost"
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeTypeBoost
--- @class NodeTypeBoost : NodeTypeSpot
--- @field chance number
--- @field isStandingHeight boolean
--- @field waitNode NodeSpotWaitOnBoost
local NodeTypeBoost = {
    colorPrimary = Color:hsla(20, 0.8, 0.6),
    isDirectional = true
}

--- @param fields NodeTypeBoost
--- @return NodeTypeBoost
function NodeTypeBoost:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @return string
function NodeTypeBoost:getError(nodegraph)
    if not self.waitNode then
        return "No wait node"
    end
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeTypeBoost:render(nodegraph, isRenderingMetaData)
    NodeTypeSpot.render(self, nodegraph, isRenderingMetaData)

    if self.waitNode then
        self.origin:drawLine(self.waitNode.origin, self.renderColorPrimary, 1)
    end
end

--- @param menu MenuGroup
--- @return void
function NodeTypeBoost:setupCustomizers(menu)
    NodeTypeSpot.setupCustomizers(self, menu)

    self:addCustomizer("chance", function()
        return menu.group:addSlider("    > Activation chance", 5, 50, {
            default = 25,
            tooltips = {
                [0] = "Not Random"
            },
        })
    end)
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTypeBoost:onSetup(nodegraph)
    NodeTypeSpot.onSetup(self, nodegraph)

    local node, distance = nodegraph.getClosest(self.origin, NodeSpotWaitOnBoost)

    if distance > 400 then
        return
    end

    self.waitNode = node
end

return Nyx.class("NodeTypeBoost", NodeTypeBoost, NodeTypeSpot)
--}}}
