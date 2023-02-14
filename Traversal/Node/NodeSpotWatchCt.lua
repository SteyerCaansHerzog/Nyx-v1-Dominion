--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotWatchCt
--- @class NodeSpotWatchCt : NodeTypeSpot
--- @field chance number
--- @field maxLength number
--- @field watchOrigin Vector3
--- @field leftOffsetOrigin Vector3
--- @field rightOffsetOrigin Vector3
local NodeSpotWatchCt = {
    name = "Watch (CT)",
    description = {
        "Informs the CT AI of map pick angles it can hold.",
        "",
        "- The AI will use these randomly find picks."
    },
    colorPrimary = Color:hsla(5, 0.8, 0.6),
    colorSecondary = ColorList.COUNTER_TERRORIST,
    isDirectional = true,
}

--- @param fields NodeSpotWatchCt
--- @return NodeSpotWatchCt
function NodeSpotWatchCt:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeSpotWatchCt:render(nodegraph, isRenderingMetaData)
    NodeTypeSpot.render(self, nodegraph, isRenderingMetaData)

    if not self.watchOrigin or self.maxLength == 0 then
        return
    end

    self.leftOffsetOrigin:drawLine(self.rightOffsetOrigin, self.renderColorPrimary)
    self.leftOffsetOrigin:drawScaledCircleOutline(16, 8, self.renderColorPrimary)
    self.rightOffsetOrigin:drawScaledCircleOutline(16, 8, self.renderColorPrimary)
end

--- @param menu MenuGroup
--- @return void
function NodeSpotWatchCt:setupCustomizers(menu)
    NodeTypeSpot.setupCustomizers(self, menu)

    self:addCustomizer("chance", function()
        return menu.group:addSlider("    > Activation chance", 5, 50, {
            default = 25,
            tooltips = {
                [0] = "Not Random"
            },
        })
    end)

    self:addCustomizer("maxLength", function()
        return menu.group:addSlider("    > Length", 0, 100, {
            default = 32,
            tooltips = {
                [0] = "No Length"
            },
        })
    end)
end

--- @param nodegraph Nodegraph
--- @return void
function NodeSpotWatchCt:onSetup(nodegraph)
    NodeTypeSpot.onSetup(self, nodegraph)

    self:generateWatchOrigin()
end

--- @return void
function NodeSpotWatchCt:generateWatchOrigin()
    if not self.maxLength then
        return
    end

    self.leftOffsetOrigin = self.origin + (self.direction:getLeft() * self.maxLength)
    self.rightOffsetOrigin = self.origin + (self.direction:getRight() * self.maxLength)

    local leftTrace = Trace.getHullToPosition(self.origin, self.leftOffsetOrigin, self.collisionHullHumanStanding, AiUtility.traceOptionsPathfinding)
    local rightTrace = Trace.getHullToPosition(self.origin, self.rightOffsetOrigin, self.collisionHullHumanStanding, AiUtility.traceOptionsPathfinding)

    self.leftOffsetOrigin = leftTrace.endPosition
    self.rightOffsetOrigin = rightTrace.endPosition

    local offset = Math.getRandomFloat(0, 1)

    self.watchOrigin = self.leftOffsetOrigin:getLerp(self.rightOffsetOrigin, offset)
end

return Nyx.class("NodeSpotWatchCt", NodeSpotWatchCt, NodeTypeSpot)
--}}}
