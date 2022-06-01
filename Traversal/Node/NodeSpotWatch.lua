--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotWatch
--- @class NodeSpotWatch : NodeTypeSpot
--- @field weapons string
--- @field weaponsSnipers string
--- @field weaponsOthers string
local NodeSpotWatch = {
    name = "Watch",
    description = {
        "Informs the T AI of random map angles it can hold.",
        "",
        "- The AI will use these randomly to hold down map angles."
    },
    colorSecondary = Color:hsla(25, 0.8, 0.5),
    isDirectional = true,
    weaponsSnipers = "Snipers Only",
    weaponsOthers = "Other Weapons",
    lookZOffset = 28
}

--- @param fields NodeSpotWatch
--- @return NodeSpotWatch
function NodeSpotWatch:new(fields)
	return Nyx.new(self, fields)
end

--- @param menu MenuGroup
--- @return void
function NodeSpotWatch:setCustomizers(menu)
    NodeTypeSpot.setCustomizers(self, menu)

    self:addCustomizer("weapons", function()
        return menu.group:addDropdown("    > Weapons", {
            self.weaponsSnipers,
            self.weaponsOthers
        })
    end)
end

return Nyx.class("NodeSpotWatch", NodeSpotWatch, NodeTypeSpot)
--}}}
