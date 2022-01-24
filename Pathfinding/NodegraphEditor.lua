--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Menu = require "gamesense/Nyx/v1/Api/Menu"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Render = require "gamesense/Nyx/v1/Api/Render"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local VKey = require "gamesense/Nyx/v1/Api/VKey"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ NodegraphEditor
--- @class NodegraphEditor : Class
--- @field nodeMaxConnections number
--- @field nodeMaxDistance number
--- @field nodegraph Nodegraph
--- @field keyAddNode VKey
--- @field keyAddSpotNode VKey
--- @field keyRemoveNode VKey
--- @field keyPreviousType VKey
--- @field keyNextType VKey
--- @field keySelectNode VKey
--- @field nodeTypeCombo number
--- @field selectedNode Node
local NodegraphEditor = {}

--- @param fields NodegraphEditor
--- @return NodegraphEditor
function NodegraphEditor:new(fields)
    return Nyx.new(self, fields)
end

--- @return nil
function NodegraphEditor:__init()
    self:initFields()
    self:initEvents()
end

--- @return nil
function NodegraphEditor:initFields()
    MenuGroup.enableEditor = MenuGroup.group:checkbox("> Dominion Editor"):setParent(MenuGroup.master)

    MenuGroup.maxNodeConnections = MenuGroup.group:slider("    > Max Node Connections", 1, 4, {
        default = 2
    }):setParent(MenuGroup.enableEditor)

    MenuGroup.nodeHeight = MenuGroup.group:slider("    > Node Height", 18, 64, {
        defalt = 18,
        unit = "u"
    }):setParent(MenuGroup.enableEditor)

    MenuGroup.nodeType = MenuGroup.group:listbox("    > Node Type", Node.typesName):addCallback(function(item)
    	self.nodeTypeCombo = item:get() + 1
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.group:button("Create nodegraph", function()
        self.nodegraph:clearNodegraph()
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.group:button("Load Nodegraph", function()
        self.nodegraph:loadFromDisk(self.nodegraph:getFilename())
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.group:button("Save nodegraph", function()
        self.nodegraph:saveToDisk(self.nodegraph:getFilename())
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.group:button("Delete Objective Nodes", function()
        local nodeTypes = {
            [Node.types.DEFEND] = true,
            [Node.types.HOLD] = true,
        }

        for _, node in pairs(self.nodegraph.nodes) do
            if nodeTypes[node.type] then
                self.nodegraph:removeNode(node)
            end
        end
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.group:button("Delete Grenade Nodes", function()
    	local nodeTypes = {
            [Node.types.SMOKE_DEFEND] = true,
            [Node.types.SMOKE_EXECUTE] = true,
            [Node.types.SMOKE_HOLD] = true,
            [Node.types.FLASHBANG_DEFEND] = true,
            [Node.types.FLASHBANG_EXECUTE] = true,
            [Node.types.FLASHBANG_HOLD] = true,
            [Node.types.MOLOTOV_DEFEND] = true,
            [Node.types.MOLOTOV_EXECUTE] = true,
            [Node.types.MOLOTOV_HOLD] = true,
            [Node.types.HE_GRENADE_DEFEND] = true,
            [Node.types.HE_GRENADE_EXECUTE] = true,
            [Node.types.HE_GRENADE_HOLD] = true,
        }

        for _, node in pairs(self.nodegraph.nodes) do
            if nodeTypes[node.type] then
                self.nodegraph:removeNode(node)
            end
        end
    end):setParent(MenuGroup.enableEditor)
end

--- @return nil
function NodegraphEditor:initEvents()
    Callbacks.init(function()
        self.nodeMaxDistance = 300
        self.keyAddNode = VKey:new(VKey.LEFT_MOUSE)
        self.keyAddSpotNode = VKey:new(VKey.E)
        self.keyRemoveNode = VKey:new(VKey.RIGHT_MOUSE)
        self.keyPreviousType = VKey:new(VKey.C)
        self.keyNextType = VKey:new(VKey.V)
        self.keySelectNode = VKey:new(VKey.F)
        self.nodeTypeCombo = 1
    end)

    Callbacks.frame(function()
        if not MenuGroup.master:get() or not MenuGroup.enableEditor:get() then
            return
        end

        self:createNodes()
        self:renderUi()
    end)
end

--- @return Node
function NodegraphEditor:selectNode()
    --- @type Node
    local selectedNode
    local closestFov = math.huge
    local cameraAngles = Client.getCameraAngles()
    local cameraOrigin = Client.getCameraOrigin()

    for _, node in pairs(self.nodegraph.nodes) do
        if cameraOrigin:getDistance(node.origin) < 750 then
            local trace = Trace.getLineToPosition(cameraOrigin, node.origin, AiUtility.traceOptions)

            if not trace.isIntersectingGeometry then
                local fov = cameraAngles:getFov(cameraOrigin, node.origin)

                if fov < closestFov and fov < 5 then
                    closestFov = fov
                    selectedNode = node
                end
            end
        end
    end

    return selectedNode
end

--- @return nil
function NodegraphEditor:createNodes()
    if Menu.isOpen() then
        return
    end

    if self.keySelectNode:wasPressed() then
        if self.selectedNode then
            self.selectedNode = nil
        else
            self.selectedNode = self:selectNode()
        end
    end

    if self.selectedNode then
        local radius = Render.scaleCircle(self.selectedNode.origin, 40)

        self.selectedNode.origin:drawCircle(radius, Color:hsla(200, 0.8, 0.6, 80))

        if self.keyAddNode:wasPressed() then
            local connectNode = self:selectNode()

            if connectNode and connectNode.id ~= self.selectedNode.id then
                if not self.selectedNode.connections[connectNode.id] then
                    self.selectedNode.connections[connectNode.id] = connectNode
                    connectNode.connections[self.selectedNode.id] = self.selectedNode
                else
                    self.selectedNode.connections[connectNode.id] = nil
                    connectNode.connections[self.selectedNode.id] = nil
                end
            end
        end

        return
    end

    if self.keyPreviousType:wasPressed() then
        self.nodeTypeCombo = self.nodeTypeCombo - 1

        if self.nodeTypeCombo < 1 then
            self.nodeTypeCombo = #Node.typesName

            MenuGroup.nodeType:set(self.nodeTypeCombo)
        end
    end

    if self.keyNextType:wasPressed() then
        self.nodeTypeCombo = self.nodeTypeCombo + 1

        if self.nodeTypeCombo > #Node.typesName then
            self.nodeTypeCombo = 1

            MenuGroup.nodeType:set(self.nodeTypeCombo)
        end
    end

    if self.keyAddNode:wasPressed() then
        local origin = Client.getCameraTraceLine()

        origin = origin + Vector3:new(0, 0, MenuGroup.nodeHeight:get())

        self:createNode(origin, false)
    end

    if self.keyAddSpotNode:wasPressed() then
        local origin = AiUtility.client:getOrigin():offset(0, 0, 18)

        self:createNode(origin, true)
    end

    if self.keyRemoveNode:wasPressed() then
        local selectedNode = self:selectNode()

        if selectedNode then
            self.nodegraph:removeNode(selectedNode)
        end
    end
end

--- @param origin Vector3
--- @param isSpot boolean
--- @return nil
function NodegraphEditor:createNode(origin, isSpot)
    local node = Node:new({
        origin = origin,
        type = self.nodeTypeCombo
    })

    if Node.typesDirectional[node.type] then
        node.direction = Client.getCameraAngles()

        if not isSpot then
            node.direction.p = 0
        end
    end

    local connections = {}
    local iConnections = 0

    for _, potentialConnection in Nyx.sortedPairs(self.nodegraph.nodes, function(a, b)
        return origin:getDistance(a.origin) < origin:getDistance(b.origin)
    end) do
        if iConnections == MenuGroup.maxNodeConnections:get() then
            break
        end

        if origin:getDistance(potentialConnection.origin) < self.nodeMaxDistance then
            local _, fraction = origin:getTraceLine(potentialConnection.origin, Client.getEid())

            if fraction == 1 then
                iConnections = iConnections + 1
                connections[potentialConnection.id] = potentialConnection
                potentialConnection.connections[self.nodegraph.currentNode + 1] = node
            end
        end
    end

    node.connections = connections

    self.nodegraph:addNode(node)
end

--- @return nil
function NodegraphEditor:renderUi()
    Client.drawIndicatorGs(Node.typesColor[self.nodeTypeCombo], Node.typesName[self.nodeTypeCombo])
end

return Nyx.class("NodegraphEditor", NodegraphEditor)
--}}}
