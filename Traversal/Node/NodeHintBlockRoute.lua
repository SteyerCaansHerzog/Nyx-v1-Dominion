--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Color = require "gamesense/Nyx/v1/Api/Color"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local NodeTypeHint = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeHint"
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeHintBlockRoute
--- @class NodeHintBlockRoute : NodeTypeHint
--- @field isActivatedByChance boolean
--- @field blockedNodes NodeTypeTraverse[]
--- @field isActivatedForBombsiteA boolean
--- @field isActivatedForBombsiteB boolean
--- @field weight number
local NodeHintBlockRoute = {
    name = "Block (Route)",
    description = {
        "Is activated when the bomb is planted,",
        "when the /rot command is invoked,",
        "or when the hostage is picked up.",
        "",
        "- Use to randomize CT AI rotate routes.",
        "- Use weight to make the nodes randomly selected,",
        "   where lower weights are more likely to activate and disable",
        "   nearby traversal nodes. One node with weight will",
        "   always be left, allowing at least one viable rotate route."
    },
    colorPrimary = Color:hsla(0, 1, 0.6),
    colorSecondary = ColorList.COUNTER_TERRORIST,
    isLinkedToBombsite = true
}

--- @param fields NodeHintBlockRoute
--- @return NodeHintBlockRoute
function NodeHintBlockRoute:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function NodeHintBlockRoute:__init()
    NodeTypeHint.__init(self)

    self.blockedNodes = {}

    Callbacks.roundPrestart(function()
    	NodeHintBlockRoute.isActivatedForBombsiteA = false
    	NodeHintBlockRoute.isActivatedForBombsiteB = false
    end)
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeHintBlockRoute:render(nodegraph, isRenderingMetaData)
    NodeTypeHint.render(self, nodegraph, isRenderingMetaData)

    if self.weight and self.weight > 0 then
        local totalWeight = 0

        for _, node in pairs(nodegraph.get(NodeHintBlockRoute)) do repeat
            if self.bombsite ~= node.bombsite then
                break
            end

            totalWeight = totalWeight + node.weight
        until true end

        local weight = self.weight / totalWeight * 100

        self:renderTopText(self.renderColorFovSecondary, "%.1f%% weight", weight)
    end
end

--- @param menu MenuGroup
--- @return void
function NodeHintBlockRoute:setupCustomizers(menu)
    NodeTypeHint.setupCustomizers(self, menu)

    self:addCustomizer("weight", function()
    	return menu.group:addSlider("    > Activation Weight", 0, 32, {
            default = 0,
            tooltips = {
                [0] = "Not Random"
            }
        })
    end)
end

--- @param nodegraph Nodegraph
--- @param bombsite string
--- @return void
function NodeHintBlockRoute.block(nodegraph, bombsite)
    if AiUtility.gameRules:m_bFreezePeriod() == 1 then
        return
    end

    if AiUtility.timeData.roundtime_elapsed < 10 then
        return
    end

    --- @type NodeHintBlockRoute[]
    local nodes = {}

    -- Handle demolition, otherwise assume hostage mode.
    if bombsite then
        if bombsite == "A" and NodeHintBlockRoute.isActivatedForBombsiteA then
            return
        else
            NodeHintBlockRoute.isActivatedForBombsiteA = true
        end

        if bombsite == "B" and NodeHintBlockRoute.isActivatedForBombsiteB then
            return
        else
            NodeHintBlockRoute.isActivatedForBombsiteB = true
        end

        nodes = nodegraph.getForBombsite(NodeHintBlockRoute, bombsite)
    else
        nodes = nodegraph.get(NodeHintBlockRoute)
    end

    --- @type NodeHintBlockRoute[]
    local weighted = {}
    local count = 0
    local clientOrigin = LocalPlayer:getOrigin()

    for _, node in pairs(nodes) do repeat
        -- We shouldn't block a route that's directly ahead of us.
        if clientOrigin:getDistance(node.origin) < 600 then
            break
        end

        -- Always block non-weighted routes.
        if node.weight == 0 then
            node:setBlockedNodes(nodegraph)

            break
        end

        count = count + 1
        weighted[count] = node
    until true end

    -- If there's only one weighted node, we may as well flip a coin.
    if count == 1 then
        if Math.getChance(2) then
            weighted[1]:setBlockedNodes(nodegraph)
        end

        return
    end

    --- @type NodeHintBlockRoute[]
    local sorted = {}
    local highestWeight = 0

    for _, item in Table.sortedPairs(weighted, function(a, b)
        return a.weight < b.weight
    end) do
        if item.weight > highestWeight then
            highestWeight = item.weight
        end

        table.insert(sorted, item)
    end

    local rng = Math.getRandomInt(1, highestWeight)
    local idxToIgnore

    for idx, item in pairs(sorted) do
        if rng <= item.weight then
            idxToIgnore = idx

            break
        end
    end

    -- Remove the node we're ignoring and then activate the block on all other weighted nodes.
    if idxToIgnore then
        table.remove(sorted, idxToIgnore)

        for _, node in pairs(sorted) do
            node:setBlockedNodes(nodegraph)
        end
    end
end

--- @param nodegraph Nodegraph
--- @return void
function NodeHintBlockRoute:setBlockedNodes(nodegraph)
    local traverseNodes = nodegraph.getOfType(NodeTypeTraverse)

    for _, traverse in pairs(traverseNodes) do repeat
        if self.origin:getDistance(traverse.origin) > self.radius then
            break
        end

        table.insert(self.blockedNodes, traverse)

        traverse:deactivate()
    until true end
end

return Nyx.class("NodeHintBlockRoute", NodeHintBlockRoute, NodeTypeHint)
--}}}
