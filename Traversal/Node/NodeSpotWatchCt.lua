--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotWatchCt
--- @class NodeSpotWatchCt : NodeTypeSpot
--- @field chance number
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
end

return Nyx.class("NodeSpotWatchCt", NodeSpotWatchCt, NodeTypeSpot)
--}}}
