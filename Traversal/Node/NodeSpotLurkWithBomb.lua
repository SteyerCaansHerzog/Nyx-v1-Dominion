--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeSpot = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeSpot"
--}}}

--{{{ NodeSpotLurkWithBomb
--- @class NodeSpotLurkWithBomb : NodeTypeSpot
local NodeSpotLurkWithBomb = {
    name = "Lurk (Bomb)",
    description = {
        "Informs the AI of lurk spots when carrying the bomb.",
        "",
        "- The AI will use these to wait with bomb."
    },
    colorSecondary = Color:hsla(300, 0.8, 0.7),
    isDirectional = true,
    isLinkedToBombsite = true
}

--- @param fields NodeSpotLurkWithBomb
--- @return NodeSpotLurkWithBomb
function NodeSpotLurkWithBomb:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeSpotLurkWithBomb", NodeSpotLurkWithBomb, NodeTypeSpot)
--}}}
