--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeBoost = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBoost"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
--}}}

--{{{ NodeTypeOntoPositionStartBoost
--- @class NodeTypeOntoPositionStartBoost : NodeTypeBoost
--- @field endNode NodeTypeOntoPositionStartBoost
--- @field endNodeClass NodeTypeOntoPositionStartBoost
local NodeTypeOntoPositionStartBoost = {
    isDirectional = true
}

--- @param fields NodeTypeOntoPositionStartBoost
--- @return NodeTypeOntoPositionStartBoost
function NodeTypeOntoPositionStartBoost:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @return string
function NodeTypeOntoPositionStartBoost:getError(nodegraph)
    if not self.endNode then
        return "No end node"
    end
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeTypeOntoPositionStartBoost:render(nodegraph, isRenderingMetaData)
    NodeTypeBoost.render(self, nodegraph, isRenderingMetaData)

    if self.endNode then
        self.origin:drawLine(self.endNode.origin, self.renderColorPrimary, 1)
    end
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeTypeOntoPositionStartBoost:render(nodegraph, isRenderingMetaData)
    NodeTypeBoost.render(self, nodegraph, isRenderingMetaData)

    if self.endNode then
        self.origin:drawLine(self.endNode.origin, self.renderColorPrimary, 1)
    end
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTypeOntoPositionStartBoost:onSetup(nodegraph)
    NodeTypeBoost.onSetup(self, nodegraph)

    local node, distance = nodegraph.getClosest(self.origin, self.endNodeClass)

    if distance > 400 then
        return
    end

    self.endNode = node
end

return Nyx.class("NodeTypeOntoPositionStartBoost", NodeTypeOntoPositionStartBoost, NodeTypeBoost)
--}}}
