--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
local NodeTypeHint = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeHint"
--}}}

--{{{ NodeHintBlock
--- @class NodeHintBlock : NodeTypeHint
--- @field duration number
--- @field isActivatedByChance boolean
--- @field blockedNodes NodeTypeTraverse[]
local NodeHintBlock = {
    name = "Block",
    description = {
        "Deactivates all nodes around it at the start of the game and will",
        "reactive them after the given time.",
        "",
        "- Use to block dangerous paths from spawn areas."
    },
    colorPrimary = Color:hsla(0, 1, 0.6)
}

--- @param fields NodeHintBlock
--- @return NodeHintBlock
function NodeHintBlock:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function NodeHintBlock:__init()
    NodeTypeHint.__init(self)

    self.blockedNodes = {}
end

--- @param menu MenuGroup
--- @return void
function NodeHintBlock:setCustomizers(menu)
    NodeTypeHint.setCustomizers(self, menu)

    self:addCustomizer("isActivatedByChance", function()
    	return menu.group:addCheckbox("    > Is activated by chance")
    end)

    self:addCustomizer("duration", function()
    	return menu.group:addSlider("    > Block Duration", 1, 25, {
            default = 15
        })
    end)
end

--- @param nodegraph Nodegraph
--- @return void
function NodeHintBlock:block(nodegraph)
    if self.isActivatedByChance and not Client.getChance(2) then
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

    Client.fireAfter(self.duration, function()
        for _, traverse in pairs(self.blockedNodes) do
            traverse:activate()
        end

        self.blockedNodes = {}
    end)
end

return Nyx.class("NodeHintBlock", NodeHintBlock, NodeTypeHint)
--}}}
