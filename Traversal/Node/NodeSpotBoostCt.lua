--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBoost"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotBoostCt
--- @class NodeSpotBoostCt : NodeTypeBoost
local NodeSpotBoostCt = {
    name = "Boost (CT)",
    description = {
        "Informs the CT AI of boost spots.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorSecondary = ColorList.COUNTER_TERRORIST
}

--- @param fields NodeSpotBoostCt
--- @return NodeSpotBoostCt
function NodeSpotBoostCt:new(fields)
	return Nyx.new(self, fields)
end

--- @param menu MenuGroup
--- @return void
function NodeSpotBoostCt:setupCustomizers(menu)
    NodeTypeBoost.setupCustomizers(self, menu)

    self:addCustomizer("isStandingHeight", function()
        return menu.group:addCheckbox("    > Standing Height")
    end)
end

return Nyx.class("NodeSpotBoostCt", NodeSpotBoostCt, NodeTypeBoost)
--}}}
