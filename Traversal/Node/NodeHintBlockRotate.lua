--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeHint = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeHint"
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeHintBlockRotate
--- @class NodeHintBlockRotate : NodeTypeHint
--- @field isActivatedByChance boolean
--- @field blockedNodes NodeTypeTraverse[]
--- @field isActivatedForBombsiteA boolean
--- @field isActivatedForBombsiteB boolean
local NodeHintBlockRotate = {
    name = "Block (Rotate)",
    description = {
        "Is sometimes activated when the bomb is planted,",
        "or when the /rot command is invoked",
        "and prevents the CT AI from taking this route to the bombsite.",
        "",
        "- Use to randomize CT AI rotate routes."
    },
    colorPrimary = Color:hsla(0, 1, 0.6),
    colorSecondary = ColorList.COUNTER_TERRORIST,
    isLinkedToBombsite = true
}

--- @param fields NodeHintBlockRotate
--- @return NodeHintBlockRotate
function NodeHintBlockRotate:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function NodeHintBlockRotate:__init()
    NodeTypeHint.__init(self)

    self.blockedNodes = {}

    Callbacks.roundPrestart(function()
    	NodeHintBlockRotate.isActivatedForBombsiteA = false
    	NodeHintBlockRotate.isActivatedForBombsiteB = false
    end)
end

--- @param menu MenuGroup
--- @return void
function NodeHintBlockRotate:setupCustomizers(menu)
    NodeTypeHint.setupCustomizers(self, menu)

    self:addCustomizer("isActivatedByChance", function()
    	return menu.group:addCheckbox("    > Is activated by chance")
    end)
end

--- @param nodegraph Nodegraph
--- @param bombsite string
--- @return void
function NodeHintBlockRotate.block(nodegraph, bombsite)
    if AiUtility.gameRules:m_bFreezePeriod() == 1 then
        return
    end

    if AiUtility.timeData.roundtime_elapsed < 10 then
        return
    end

    if bombsite == "A" and NodeHintBlockRotate.isActivatedForBombsiteA then
        return
    else
        NodeHintBlockRotate.isActivatedForBombsiteA = true
    end

    if bombsite == "B" and NodeHintBlockRotate.isActivatedForBombsiteB then
        return
    else
        NodeHintBlockRotate.isActivatedForBombsiteB = true
    end

    local nodes = nodegraph.getForBombsite(NodeHintBlockRotate, bombsite)
    --- @type NodeHintBlockRotate[]
    local randoms = {}
    local count = 0

    for _, node in pairs(nodes) do repeat
        if LocalPlayer:getOrigin():getDistance(node.origin) < 600 then
            break
        end

        if not node.isActivatedByChance then
            node:setBlockedNodes(nodegraph)

            break
        end

        count = count + 1
        randoms[count] = node
    until true end

    if count == 1 then
        if Math.getChance(2) then
            randoms[1]:setBlockedNodes(nodegraph)
        end

        return
    end

    for _ = 1, count do
        if count == 1 then
            return
        end

        local node = table.remove(randoms, Math.getRandomInt(1, count))

        count = count - 1

        node:setBlockedNodes(nodegraph)
    end
end

--- @param nodegraph Nodegraph
--- @return void
function NodeHintBlockRotate:setBlockedNodes(nodegraph)
    local traverseNodes = nodegraph.getOfType(NodeTypeTraverse)

    for _, traverse in pairs(traverseNodes) do repeat
        if self.origin:getDistance(traverse.origin) > self.radius then
            break
        end

        table.insert(self.blockedNodes, traverse)

        traverse:deactivate()
    until true end
end

return Nyx.class("NodeHintBlockRotate", NodeHintBlockRotate, NodeTypeHint)
--}}}
