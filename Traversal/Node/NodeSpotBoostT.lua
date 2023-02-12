--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBoost"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeSpotBoostT
--- @class NodeSpotBoostT : NodeTypeBoost
--- @field chance number
--- @field isStandingHeight boolean
--- @field waitNode NodeSpotWaitOnBoost
local NodeSpotBoostT = {
    name = "Boost (T)",
    description = {
        "Informs the T AI of boost spots.",
        "",
        "- The AI will use these to ask for boosts."
    },
    colorSecondary = ColorList.TERRORIST
}

--- @param fields NodeSpotBoostT
--- @return NodeSpotBoostT
function NodeSpotBoostT:new(fields)
	return Nyx.new(self, fields)
end

--- @param menu MenuGroup
--- @return void
function NodeSpotBoostT:setupCustomizers(menu)
    NodeTypeBoost.setupCustomizers(self, menu)

    self:addCustomizer("isStandingHeight", function()
        return menu.group:addCheckbox("    > Standing Height")
    end)
end

return Nyx.class("NodeSpotBoostT", NodeSpotBoostT, NodeTypeBoost)
--}}}
