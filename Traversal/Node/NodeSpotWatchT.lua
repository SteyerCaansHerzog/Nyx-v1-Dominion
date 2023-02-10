--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotWatchT
--- @class NodeSpotWatchT : NodeTypeSpot
--- @field weapons string
--- @field weaponsSnipers string
--- @field weaponsOthers string
local NodeSpotWatchT = {
    name = "Watch (T)",
    description = {
        "Informs the T AI of random map angles it can hold.",
        "",
        "- The AI will use these randomly to hold down map angles."
    },
    colorPrimary = Color:hsla(5, 0.8, 0.6),
    colorSecondary = ColorList.TERRORIST,
    isDirectional = true,
    weaponsSnipers = "Snipers Only",
    weaponsOthers = "Other Weapons"
}

--- @param fields NodeSpotWatchT
--- @return NodeSpotWatchT
function NodeSpotWatchT:new(fields)
	return Nyx.new(self, fields)
end

--- @param menu MenuGroup
--- @return void
function NodeSpotWatchT:setupCustomizers(menu)
    NodeTypeSpot.setupCustomizers(self, menu)

    self:addCustomizer("weapons", function()
        return menu.group:addDropdown("    > Weapons", {
            self.weaponsSnipers,
            self.weaponsOthers
        })
    end)
end

return Nyx.class("NodeSpotWatchT", NodeSpotWatchT, NodeTypeSpot)
--}}}
