--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeHint = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeHint"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeHintWallbang
--- @class NodeHintWallbang : NodeTypeHint
local NodeHintWallbang = {
    name = "Wallbang",
    description = {
        "Forces T AI to accurately wallbang enemies",
        "who are inside of the radius."
    },
    colorPrimary = Color:hsla(300, 0.8, 0.6),
    colorSecondary = Color:hsla(300, 1, 1)
}

--- @param fields NodeHintWallbang
--- @return NodeHintWallbang
function NodeHintWallbang:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeHintWallbang", NodeHintWallbang, NodeTypeHint)
--}}}
