--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseRecorderEnd
--- @class NodeTraverseRecorderEnd : NodeTypeTraverse
--- @field startPoint NodeTraverseRecorderStart
local NodeTraverseRecorderEnd = {
    name = "Recorder (End)",
    description = {
        "Informs the AI of how to traverse the map with a recorder."
    },
    colorPrimary = Color:hsla(260, 0.8, 0.65),
    colorSecondary = Color:hsla(260, 0.8, 0.75),
    traversalCost = 25,
    isDragMovable = false,
    isHiddenFromEditor = true,
    isRecorder = true
}

--- @param fields NodeTraverseRecorderEnd
--- @return NodeTraverseRecorderEnd
function NodeTraverseRecorderEnd:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTraverseRecorderEnd:getError(nodegraph)
    if not self.startPoint then
        return "No recorder start point"
    end

    return NodeTypeTraverse.getError(self, nodegraph)
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTraverseRecorderEnd:onRemove(nodegraph)
    if self.startPoint then
        self.startPoint.endPoint = nil
    end

    NodeTypeTraverse.onRemove(self, nodegraph)
end

return Nyx.class("NodeTraverseRecorderEnd", NodeTraverseRecorderEnd, NodeTypeTraverse)
--}}}
