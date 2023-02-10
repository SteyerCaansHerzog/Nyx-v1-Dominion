--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeSpotWaitOnBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeSpotWaitOnBoost"
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotBoost
--- @class NodeSpotBoost : NodeTypeSpot
--- @field chance number
--- @field isStandingHeight boolean
--- @field waitNode NodeSpotWaitOnBoost
local NodeSpotBoost = {
    name = "Boost (CT)",
    description = {
        "Informs the AI of boost spots when CT-side.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorSecondary = Color:hsla(0, 0.8, 0.6),
    isDirectional = true
}

--- @param fields NodeSpotBoost
--- @return NodeSpotBoost
function NodeSpotBoost:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @return string
function NodeSpotBoost:getError(nodegraph)
    if not self.waitNode then
        return "No wait node"
    end
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeSpotBoost:render(nodegraph, isRenderingMetaData)
    NodeTypeSpot.render(self, nodegraph, isRenderingMetaData)

    if self.waitNode then
        self.origin:drawLine(self.waitNode.origin, self.renderColorPrimary, 1)
    end
end

--- @param menu MenuGroup
--- @return void
function NodeSpotBoost:setupCustomizers(menu)
    NodeTypeSpot.setupCustomizers(self, menu)

    self:addCustomizer("isStandingHeight", function()
    	return menu.group:addCheckbox("    > Standing Height")
    end)

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
function NodeSpotBoost:onSetup(nodegraph)
    NodeTypeSpot.onSetup(self, nodegraph)

    local node, distance = nodegraph.getClosest(self.origin, NodeSpotWaitOnBoost)

    if distance > 400 then
        return
    end

    self.waitNode = node
end

return Nyx.class("NodeSpotBoost", NodeSpotBoost, NodeTypeSpot)
--}}}
