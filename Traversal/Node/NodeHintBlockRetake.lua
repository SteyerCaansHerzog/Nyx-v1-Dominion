--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeHint = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeHint"
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeHintBlockRetake
--- @class NodeHintBlockRetake : NodeTypeHint
--- @field isActivatedByChance boolean
local NodeHintBlockRetake = {
    name = "Block (Retake)",
    description = {
        "Is sometimes activated when the bomb is planted,",
        "and prevents the CT AI from taking this route to the bombsite.",
        "",
        "- Use to randomize CT AI retake routes."
    },
    colorPrimary = Color:hsla(0, 1, 0.6),
    colorSecondary = ColorList.COUNTER_TERRORIST,
    isLinkedToBombsite = true
}

--- @param fields NodeHintBlockRetake
--- @return NodeHintBlockRetake
function NodeHintBlockRetake:new(fields)
	return Nyx.new(self, fields)
end

--- @param menu MenuGroup
--- @return void
function NodeHintBlockRetake:setupCustomizers(menu)
    NodeTypeHint.setupCustomizers(self, menu)

    self:addCustomizer("isActivatedByChance", function()
    	return menu.group:addCheckbox("    > Is activated by chance")
    end)
end

--- @param nodegraph Nodegraph
--- @return void
function NodeHintBlockRetake:block(nodegraph)
    if self.isActivatedByChance and not Math.getChance(2) then
        return
    end

    local traverseNodes = nodegraph.getOfType(NodeTypeTraverse)

    for _, traverse in pairs(traverseNodes) do repeat
        if self.origin:getDistance(traverse.origin) > self.radius then
            break
        end

        table.insert(self.blockedNodes, traverse)

        traverse:deactivate()
    until true end
end

return Nyx.class("NodeHintBlockRetake", NodeHintBlockRetake, NodeTypeHint)
--}}}
