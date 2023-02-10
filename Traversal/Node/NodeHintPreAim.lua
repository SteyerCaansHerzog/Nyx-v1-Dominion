--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeHint = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeHint"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeHintPreAim
--- @class NodeHintPreAim : NodeTypeHint
local NodeHintPreAim = {
    name = "Pre-Aim",
    description = {
        "Forces T AI to pre-aim common angles",
        "when executing sites."
    },
    colorPrimary = Color:hsla(300, 0.8, 0.6),
    colorSecondary = Color:hsla(300, 0.8, 0.6),
    isDirectional = true
}

--- @param fields NodeHintPreAim
--- @return NodeHintPreAim
function NodeHintPreAim:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("NodeHintPreAim", NodeHintPreAim, NodeTypeHint)
--}}}
