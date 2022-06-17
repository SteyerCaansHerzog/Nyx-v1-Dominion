--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local NodeTypeTraverse = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeTraverse"
--}}}

--{{{ NodeTraverseRecorderStart
--- @class NodeTraverseRecorderStart : NodeTypeTraverse
--- @field endPoint NodeTraverseRecorderEnd
--- @field recording SetupCommandEvent[]
--- @field activeRecording SetupCommandEvent[]
local NodeTraverseRecorderStart = {
    name = "Recorder (Start)",
    description = {
        "Informs the AI of how to traverse the map with a recorder."
    },
    colorPrimary = Color:hsla(260, 0.8, 0.65),
    colorSecondary = Color:hsla(260, 0.8, 0.75),
    traversalCost = 25,
    isDirectional = true,
    isDragMovable = false,
    isHiddenFromEditor = true,
    isRecorder = true,
}

--- @param fields NodeTraverseRecorderStart
--- @return NodeTraverseRecorderStart
function NodeTraverseRecorderStart:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function NodeTraverseRecorderStart:setActiveRecording()
    self.activeRecording = Table.new(self.recording)
end

--- @return SetupCommandEvent
function NodeTraverseRecorderStart:getNextTick()
    return table.remove(self.activeRecording, 1)
end

--- @return NodeTraverseRecorderStart
function NodeTraverseRecorderStart:serialize()
    return {
        endPoint = self.endPoint and self.endPoint.id,
        recording = self.recording and json.stringify(self.recording)
    }
end

--- @param nodegraph Nodegraph
--- @param userdata NodeTraverseRecorderStart
--- @return void
function NodeTraverseRecorderStart:deserialize(nodegraph, userdata)
    if userdata.endPoint then
        self.endPoint = nodegraph.getById(userdata.endPoint)

        if self.endPoint then
            self.endPoint.startPoint = self
        end
    end

    if userdata.recording then
        self.recording = json.parse(userdata.recording)
    end
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTraverseRecorderStart:getError(nodegraph)
    if not self.endPoint then
        return "No recorder end point"
    end

    return NodeTypeTraverse.getError(self, nodegraph)
end

--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeTraverseRecorderStart:render(nodegraph, isRenderingMetaData)
    NodeTypeTraverse.render(self, nodegraph, isRenderingMetaData)

    if self.endPoint then
        self.origin:drawLine(self.endPoint.origin, self.renderColorSecondary)
    end
end

--- Executed when this node is the current node in the AI's path.
---
--- @param nodegraph Nodegraph
--- @param path PathfinderPath
--- @return void
function NodeTraverseRecorderStart:onIsNext(nodegraph, path)
    NodeTypeTraverse.onIsNext(self, nodegraph, path)

    self:setActiveRecording()
end

--- @param nodegraph Nodegraph
--- @return void
function NodeTraverseRecorderStart:onRemove(nodegraph)
    if self.endPoint then
        self.endPoint.startPoint = nil
    end

    NodeTypeTraverse.onRemove(self, nodegraph)
end

return Nyx.class("NodeTraverseRecorderStart", NodeTraverseRecorderStart, NodeTypeTraverse)
--}}}
