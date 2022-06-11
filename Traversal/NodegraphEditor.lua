--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Menu = require "gamesense/Nyx/v1/Api/Menu"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local VKey = require "gamesense/Nyx/v1/Api/VKey"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local NodeType = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeType"
local NodeTypeBase = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeTypeBase"
local UserInterface = require "gamesense/Nyx/v1/Dominion/Utility/UserInterface"
--}}}

--{{{ NodegraphEditor
--- @class NodegraphEditor : Class
--- @field blockInputs boolean
--- @field highlightNode NodeTypeBase
--- @field highlightNodeColor Color
--- @field iNode number
--- @field isRecordingMovement boolean
--- @field keyAdd VKey
--- @field keyEnableEditing VKey
--- @field keyIgnoreSelection VKey
--- @field keyNext VKey
--- @field keyPrevious VKey
--- @field keyRemove VKey
--- @field keySaveNodegraph VKey
--- @field keySetConnections VKey
--- @field keyStartMovementRecorder VKey
--- @field keyTestLineOfSight VKey
--- @field keyUnsetConnections VKey
--- @field movementRecorderEndOrigin Vector3
--- @field movementRecorderParams string[]
--- @field movementRecorderStartOrigin Vector3
--- @field movementRecorderStartAngles Angle
--- @field movementRecording SetupCommandEvent[]
--- @field moveNode NodeTypeBase
--- @field moveNodeDelay Timer
--- @field moveNodeResetDelay Timer
--- @field nextNodeTimer Timer
--- @field node NodeTypeBase
--- @field nodes NodeTypeBase[]
--- @field selectedNode NodeTypeBase
--- @field spawnError string|nil
--- @field spawnNode NodeTypeBase
--- @field visibleGroups boolean[]
local NodegraphEditor = {
    movementRecorderParams = {
        "forwardmove",
        "in_attack",
        "in_attack",
        "in_attack2",
        "in_back",
        "in_cancel",
        "in_duck",
        "in_forward",
        "in_jump",
        "in_left",
        "in_moveleft",
        "in_moveright",
        "in_right",
        "in_run",
        "in_speed",
        "in_use",
        "move_yaw",
        "pitch",
        "sidemove",
        "yaw",
    }
}

--- @param fields NodegraphEditor
--- @return NodegraphEditor
function NodegraphEditor:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function NodegraphEditor:__init()
    self:initFields()
    self:initEvents()

    Logger.console(0, "Nodegraph Editor is ready.")
end

--- @return void
function NodegraphEditor:initFields()
    self.nodes = {}

    local iNodes = 0

    --- @param node NodeTypeBase
    for _, node in Table.sortedPairs(Node, function(a, b)
        return string.format("%s%s", a.type:lower(), a.name:lower()) < string.format("%s%s", b.type:lower(), b.name:lower())
    end) do
        repeat
            if node.isHiddenFromEditor then
                break
            end

            iNodes = iNodes + 1

            self.nodes[iNodes] = node
        until true
    end

    self.iNode = 1
    self.node = self.nodes[self.iNode]
    self.keyAdd = VKey:new(VKey.LEFT_MOUSE)
    self.keyEnableEditing = VKey:new(VKey.R):activate()
    self.keyIgnoreSelection = VKey:new(VKey.E)
    self.keyNext = VKey:new(VKey.V)
    self.keyPrevious = VKey:new(VKey.C)
    self.keyRemove = VKey:new(VKey.RIGHT_MOUSE)
    self.keySaveNodegraph = VKey:new(VKey.X)
    self.keySetConnections = VKey:new(VKey.F)
    self.keyTestLineOfSight  = VKey:new(VKey.G):activate()
    self.keyUnsetConnections = VKey:new(VKey.MIDDLE_MOUSE)
    self.keyStartMovementRecorder = VKey:new(VKey.Z)
    self.moveNodeDelay = Timer:new()
    self.moveNodeResetDelay = Timer:new():startThenElapse()
    self.nextNodeTimer = Timer:new():startThenElapse()

    MenuGroup.group:addLabel("----------------------------------------"):setParent(MenuGroup.master)
    MenuGroup.enableEditor = MenuGroup.group:addCheckbox("> Enable Nodegraph Editor"):setParent(MenuGroup.master)

    MenuGroup.drawDistance = MenuGroup.group:addSlider("> Draw distance", 10, 100, {
        scale = 100
    }):addCallback(function(item)
        NodeTypeBase.drawDistance = item:get() * 100
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.maxNodeConnections = MenuGroup.group:addSlider("    > Max Node Connections", 1, 4, {
        default = 2
    }):setParent(MenuGroup.enableEditor)

    MenuGroup.nodeHeight = MenuGroup.group:addSlider("    > Node Spawn Height", 18, 32, {}):setParent(MenuGroup.enableEditor)

    MenuGroup.group:addLabel("------------------------------------------------"):setParent(MenuGroup.enableEditor)
    MenuGroup.group:addLabel("Node Custom Metadata"):setParent(MenuGroup.enableEditor)

    for field, cachedItem in pairs(NodeTypeBase.customizerItems) do
        NodeTypeBase.customizerItems[field] = cachedItem()
    end

    for _, item in pairs(NodeTypeBase.customizerItems) do
        item:setVisibility(false)
    end

    MenuGroup.group:addLabel("------------------------------------------------"):setParent(MenuGroup.enableEditor)

    local nodeGroupNames = {}
    --- @type NodeTypeBase[]
    local types = NodeType

    for _, node in pairs(types) do
        table.insert(nodeGroupNames, node.type)
    end

    table.sort(nodeGroupNames)

    MenuGroup.visibleGroups = MenuGroup.group:addMultiDropdown("    > Visible Groups", nodeGroupNames):addCallback(function(item)
        self.visibleGroups = Table.getMap(item:get())
    end):setParent(MenuGroup.enableEditor):set(nodeGroupNames)

    MenuGroup.debugMode = MenuGroup.group:addDropdown("    > Debug Mode", {"None", "Collisions", "Gaps"}):addCallback(function(item)
        local modeToggle = item:get()

        if modeToggle == "Collisions" then
            Debug.isDisplayingConnectionCollisions = true
            Debug.isDisplayingGapCollisions = false
        elseif modeToggle == "Gaps" then
            Debug.isDisplayingConnectionCollisions = false
            Debug.isDisplayingGapCollisions = true
        else
            Debug.isDisplayingConnectionCollisions = false
            Debug.isDisplayingGapCollisions = false

            Pathfinder.clearActivePathAndLastRequest()
        end
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.group:addLabel("    > Find Node by ID"):setParent(MenuGroup.enableEditor)
    MenuGroup.findNode = MenuGroup.group:addTextBox("DominionNodegraphEditorFindNode"):setParent(MenuGroup.enableEditor)

    MenuGroup.group:addButton("Load nodegraph", function()
        Nodegraph.load(Nodegraph.getFilename())
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.group:addButton("Save nodegraph", function()
        Nodegraph.save(Nodegraph.getFilename())
    end):setParent(MenuGroup.enableEditor)

    MenuGroup.group:addButton("Create nodegraph", function()
    	Nodegraph.create(Nodegraph.getFilename())
    end):setParent(MenuGroup.enableEditor)
end

--- @return void
function NodegraphEditor:initEvents()
    Callbacks.frame(function()
        if not MenuGroup.master:get() or not MenuGroup.enableEditor:get() then
            return
        end

        self:processKeys()
        self:render()
    end)

    Callbacks.setupCommand(function(cmd)
        if not MenuGroup.master:get() or not MenuGroup.enableEditor:get() then
            return
        end

        if self.blockInputs then
            cmd.in_attack = false
            cmd.in_attack2 = false
        end

        self:processMovementRecorder(cmd)
    end)
end

--- @return void
function NodegraphEditor:processKeys()
    self.spawnError = nil

    if not self.keyEnableEditing:isToggled() then
        self.blockInputs = false

        return
    end

    self.blockInputs = true

    if Menu.isOpen() then
        self.keyAdd:reset()
        self.keyRemove:reset()
        self.keyNext:reset()
        self.keyPrevious:reset()
        self.keyUnsetConnections:reset()
    end

    if self.keySaveNodegraph:wasPressed() then
        Nodegraph.save(Nodegraph.getFilename())
    end

    if self.keySetConnections:wasPressed() then
        self.selectedNode = nil
    end

    if self.keySetConnections:isToggled() then
        self:processSetConnections()
    else
        self:processAdd()
        self:processRemove()
    end

    self:processSwitchNodeType()
    self:renderHighlight()
end

--- @param recording SetupCommandEvent[]
--- @return void
function NodegraphEditor:getTrimmedRecording(recording)
    local beginForward = recording[1].forwardmove
    local beginSide = recording[1].sidemove

    -- Trim the start.
    for k, v in pairs(recording) do
        if v.forwardmove == beginForward and v.sidemove == beginSide then
            recording[k] = nil
        else
            break
        end
    end

    -- Fix missing keys.
    recording = Table.getArray(recording)

    local j = #recording
    local endForward = recording[j].forwardmove
    local endSide = recording[j].sidemove

    -- Trim the end.
    for k = j, 1, -1 do
        local v = recording[k]

        if v and v.forwardmove == endForward and v.sidemove == endSide then
            recording[k] = nil
        else
            break
        end
    end

    return recording
end

--- @param cmd SetupCommandEvent
--- @return void
function NodegraphEditor:processMovementRecorder(cmd)
    if self.keyStartMovementRecorder:wasPressed() then
        if self.isRecordingMovement then
            self.movementRecorderEndOrigin = LocalPlayer:getOrigin():offset(0, 0, 18)

            local recorderStart = Node.traverseRecorderStart:new({
                origin = self.movementRecorderStartOrigin,
                direction = self.movementRecorderStartAngles,
                recording = self:getTrimmedRecording(self.movementRecording)
            })

            local recorderEnd = Node.traverseRecorderEnd:new({
                origin = self.movementRecorderEndOrigin
            })

            recorderStart.endPoint = recorderEnd
            recorderEnd.startPoint = recorderStart

            Nodegraph.addMany({
                recorderStart,
                recorderEnd
            }, true)

            recorderStart:setConnections(Nodegraph)
            recorderEnd:setConnections(Nodegraph)
            recorderStart:setConnection(recorderEnd)

            self.movementRecording = {}
            self.isRecordingMovement = false
            self.movementRecorderStartOrigin = nil
            self.movementRecorderStartAngles = nil
            self.movementRecorderEndOrigin = nil
        else
            self.movementRecording = {}
            self.isRecordingMovement = true
            self.movementRecorderStartAngles = LocalPlayer.getCameraAngles()
            self.movementRecorderStartOrigin = LocalPlayer:getOrigin():offset(0, 0, 18)
        end
    end

    if self.isRecordingMovement then
        local tick = {}

        for _, field in pairs(self.movementRecorderParams) do
            tick[field] = cmd[field]
        end

        table.insert(self.movementRecording, tick)
    end
end

--- @return void
function NodegraphEditor:processSetConnections()
    if Menu.isOpen() then
        return
    end

    local node = self:getSelectedNode()

    if self.keyAdd:wasPressed() then
        if not node then
            self.selectedNode = nil
        elseif self.selectedNode and self.selectedNode.id == node.id then
            self.selectedNode = nil
        elseif node.isConnectable then
            self.selectedNode = node
        end
    end

    if not self.selectedNode then
        return
    end

    if self.keyUnsetConnections:wasPressed() then
        self.selectedNode:unsetConnections()
    end

    if self.keyRemove:wasPressed() and node then
        if node.id == self.selectedNode.id then
            return
        end

        if not node.isConnectable then
            return
        end

        if not node.isTraversal and not self.selectedNode.isTraversal then
            return
        end

        if self.selectedNode.connections[node.id] then
            self.selectedNode.connections[node.id] = nil
            node.connections[self.selectedNode.id] = nil
        else
            self.selectedNode.connections[node.id] = node
            node.connections[self.selectedNode.id] = self.selectedNode
        end
    end
end

--- @return void
function NodegraphEditor:processAdd()
    local selectedNode = self:getSelectedNode()
    local nodeBounds = Vector3:newBounds(Vector3.align.CENTER, 18)

    self.spawnNode = nil

    if Menu.isOpen() then
        return
    end

    -- Test drag-move.
    if selectedNode and selectedNode.isDragMovable and self.keyAdd:isHeld() then
        self.moveNodeDelay:ifPausedThenStart()

        if not self.moveNode and selectedNode and self.moveNodeDelay:isElapsed(0.15) then
            self.moveNode = selectedNode
        end
    else
        self.moveNode = nil

        self.moveNodeDelay:stop()
    end

    -- Drag-move is active.
    if self.moveNode then
        self.moveNodeResetDelay:restart()

        local trace = Trace.getHullAlongCrosshair(nodeBounds, AiUtility.traceOptionsPathfinding)

        self.highlightNode, self.highlightNodeColor = self.moveNode, Color:hsla(210, 0.8, 0.6, 50)
        self.moveNode.origin = trace.endPosition

        return
    end

    -- Reset drag-move.
    if self.moveNodeResetDelay:isStarted() and not self.moveNodeResetDelay:isElapsed(0.1) then
        self.keyAdd:reset()

        return
    end

    -- Set up node customizers when clicking on a node.
    if selectedNode and self.keyAdd:wasPressed() and self.node:is(selectedNode) then
        selectedNode:executeCustomizers()

        return
    end

    if selectedNode then
        return
    end

    -- Place the node in the map.
    --- @type Vector3
    local origin

    if self.node.isDirectional then
        origin = Client.getOrigin():offset(0, 0, 18)
    else
        local trace = Trace.getHullAlongCrosshair(nodeBounds, AiUtility.traceOptionsPathfinding)

        origin = trace.endPosition
    end

    -- Test planar collisions.
    if self.node.isPlanar then
        local trace = Trace.getHullAtPosition(
            origin,
            Vector3:newBounds(Vector3.align.CENTER, 20, 20, 16),
            AiUtility.traceOptionsPathfinding
        )

        if trace.isIntersectingGeometry then
            self.spawnError = "Node is inside geometry"
        end
    end

    -- Test node height to floor.
    local trace = Trace.getHullToPosition(
        origin,
        origin + Vector3:new(0, 0, -18),
        nodeBounds,
        AiUtility.traceOptionsPathfinding
    )

    if not trace.isIntersectingGeometry then
        self.spawnError = "Node is not on the floor"
    end

    -- Test node distance.
    if Client.getOrigin():getDistance(origin) > 750 then
        self.spawnError = "Node is too far away"
    end

    -- Create new node.
    local node = self.node:new({
        origin = origin
    })

    node:executeCustomizers()

    node:setConnections(Nodegraph, {
        maxConnections = MenuGroup.maxNodeConnections:get(),
        isInversingConnections = false
    })

    node:render(Nodegraph, true)

    self.spawnNode = node

    -- Spawn the node or highlight it.
    if not self.spawnError then
        self.highlightNode, self.highlightNodeColor = node, Color:hsla(120, 0.8, 0.6, 50)

        if self.keyAdd:wasPressed() then
            node:onCreatePre(Nodegraph)

            Nodegraph.add(node, true)
        end
    else
        self.keyAdd:reset()
        self.highlightNode, self.highlightNodeColor = node, Color:hsla(0, 0.8, 0.6, 50)
    end
end

--- @return void
function NodegraphEditor:processRemove()
    local node = self:getSelectedNode()

    if not node then
        return
    end

    if not Menu.isOpen() and self.keyRemove:wasPressed() then
        Nodegraph.remove(node)
    end
end

--- @return void
function NodegraphEditor:processSwitchNodeType()
    if self.keyPrevious:isHeld() then
        self.nextNodeTimer:ifPausedThenStart()

        if self.nextNodeTimer:isElapsedThenRestart(0.08) then
            local iNode = self.iNode - 1

            if iNode == 0 then
                iNode = #self.nodes
            end

            self.node:setCustomizersVisibility(false)

            self.node = self.nodes[iNode]
            self.iNode = iNode

            self.node:setCustomizersVisibility(true)
        end
    end

    if self.keyNext:isHeld() then
        self.nextNodeTimer:ifPausedThenStart()

        if self.nextNodeTimer:isElapsedThenRestart(0.08) then
            local iNode = self.iNode + 1

            if iNode > #self.nodes then
                iNode = 1
            end

            self.node:setCustomizersVisibility(false)

            self.node = self.nodes[iNode]
            self.iNode = iNode

            self.node:setCustomizersVisibility(true)
        end
    end
end

--- @return NodeTypeBase
function NodegraphEditor:getSelectedNode()
    local cameraOrigin = Client.getCameraOrigin()
    local cameraAngles = Client.getCameraAngles()
    local isTestingLos = self.keyTestLineOfSight:isToggled()

    --- @type NodeTypeBase
    local closest
    local closestFov = math.huge

    for _, node in pairs(Nodegraph.nodes) do repeat
        if not self.visibleGroups[node.type] then
            break
        end

        local distance = cameraOrigin:getDistance(node.origin)

        if distance > 512 then
            break
        end

        local fov = cameraAngles:getFov(cameraOrigin, node.origin)

        if fov > 4 then
            break
        end

        if isTestingLos then
            local trace = Trace.getLineToPosition(cameraOrigin, node.origin, AiUtility.traceOptionsPathfinding)

            if not trace.isIntersectingGeometry and fov < closestFov then
                closestFov = fov
                closest = node
            end
        elseif fov < closestFov then
            closestFov = fov
            closest = node
        end
    until true end

    if closest then
        local color = ColorList.INFO

        if self.keySetConnections:isToggled() then
            color = ColorList.WARNING
        end

        self.highlightNode, self.highlightNodeColor = closest, color:clone():setAlpha(100)
    end

    return closest
end

--- @return void
function NodegraphEditor:renderHighlight()
    if self.highlightNode then
        self.highlightNode.origin:drawScaledCircle(60, self.highlightNodeColor)

        self.highlightNode = nil
    end

    if self.selectedNode then
        self.selectedNode.origin:drawScaledCircle(80, self.highlightNodeColor)
    end
end

--- @return void
function NodegraphEditor:render()
    local padding = 10
    local tabWidth = 290
    local screenDims = Client.getScreenDimensions()
    local drawPos = Vector2:new(screenDims.x - (450 + padding), padding)
    local margin = 5
    local height = 0
    local lineHeight = 20

    -- Nodes
    local iProblems = 0
    local iNodes = 0

    for _, node in pairs(Nodegraph.nodes) do
        if node:getError(Nodegraph) then
            iProblems = iProblems + 1
        end

        if self.visibleGroups[node.type] then
            node:render(Nodegraph, true)
        end

        iNodes = iNodes + 1
    end

    if self.keySetConnections:isToggled() and self.selectedNode then
        for _, connection in pairs(self.selectedNode.connections) do
            connection.origin:drawScaledCircle(50, self.highlightNodeColor:setAlpha(75))
        end
    end

    --- @type NodeTypeBase
    local findNode
    local findNodeId = tonumber(MenuGroup.findNode:get())

    if findNodeId then
        findNode = Nodegraph.getById(findNodeId)
    end

    if findNode then
        findNode:renderTopText(ColorList.ERROR, "FIND %i", findNodeId)
        findNode.origin:drawScaledCircleOutline(90, 10, ColorList.ERROR)
    end

    if Debug.isDisplayingConnectionCollisions or Debug.isDisplayingGapCollisions then
        if MenuGroup.enableAi:get() then
            local drawErrPos = Client.getScreenDimensionsCenter():set(nil, 200)
            local bgDims = Vector2:new(500, 50)

            drawErrPos:drawBlur(bgDims, true)
            drawErrPos:drawSurfaceRectangleOutline(4, 2, bgDims, ColorList.ERROR, true)
            drawErrPos:drawSurfaceRectangle(bgDims, ColorList.BACKGROUND_1, true)
            drawErrPos:clone():offset(0, -20):drawSurfaceText(Font.LARGE, ColorList.ERROR, "c", "Debug mode is enabled")
        end

        Pathfinder.isEnabled =  true

        Pathfinder.moveToNode(Nodegraph.getRandom(Node.traverseGeneric), {
            task = "Display collision hulls",
            onFoundPath = function()
            	Client.fireAfter(1, function()
                    Pathfinder.retryLastRequest()

                    for _, node in pairs(Nodegraph.getOfType(NodeType.traverse)) do repeat
                        node.connectionCollisions = {}
                    until true end
            	end)
            end
        })

        if Debug.isDisplayingConnectionCollisions then
            for _, collisions in pairs(Pathfinder.goalConnectionCollisions) do
                for _, collision in pairs(collisions) do
                    local color

                    if collision.isClose then
                        color = Color:rgba(0, 0, 255)
                    elseif collision.isOutOfReach then
                        color = Color:rgba(200, 200, 200)
                    elseif collision.isIntersectingGeometry then
                        color = Color:rgba(255, 0, 0)
                    else
                        color = Color:rgba(0, 255, 0)
                    end

                    collision.origin:clone():offset(0, 0, -18):drawCube(collision.bounds, color)
                end
            end
        end

        if Debug.isDisplayingGapCollisions then
            for _, collisions in pairs(Pathfinder.goalGapCollisions) do
                for _, collision in pairs(collisions) do
                    local color

                    if not collision.isIntersectingGeometry then
                        color = Color:rgba(255, 150, 0)
                    else
                        color = Color:rgba(0, 255, 150)
                    end

                    collision.origin:clone():offset(0, 0, -18):drawCube(collision.bounds, color)
                end
            end
        end
    end

    -- Node count.
    height = 30

    UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_1, ColorList.FONT_NORMAL, height)
    UserInterface.drawText(drawPos, Font.SMALL, ColorList.FONT_NORMAL, "Total Nodes: %i", iNodes)

    drawPos:offset(0, height + margin)

    -- Information.
    height = 30

    local text = "[R] Nodegraph Editing (ENABLED)"
    local color = ColorList.INFO

    if not self.keyEnableEditing:isToggled() then
        text = "[R] Nodegraph Editing (DISABLED)"
        color = ColorList.FONT_MUTED
    end

    UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_1, color, height)
    UserInterface.drawText(drawPos, Font.SMALL, color, text)

    drawPos:offset(0, height)


    local text = "[G] Test LOS for Selection (ENABLED)"
    local color = ColorList.INFO

    if not self.keyTestLineOfSight:isToggled() then
        text = "[G] Test LOS for Selection (DISABLED)"
        color = ColorList.FONT_MUTED
    end

    UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_1, color, height)
    UserInterface.drawText(drawPos, Font.SMALL, color, text)

    drawPos:offset(0, height)


    local text = "[F] Select Nodes"
    local color = ColorList.INFO

    if self.keySetConnections:isToggled() then
        text = "[F] Edit Node Connections"
        color = ColorList.WARNING
    end

    UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_1, color, height)
    UserInterface.drawText(drawPos, Font.SMALL, color, text)

    drawPos:offset(0, height)


    local text = "[Z] Begin Movement Recorder"
    local color = ColorList.INFO

    if self.keyStartMovementRecorder:isToggled() then
        text = "[Z] STOP MOVEMENT RECORDER"
        color = ColorList.ERROR
    end

    UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_1, color, height)
    UserInterface.drawText(drawPos, Font.SMALL, color, text)

    drawPos:offset(0, height)


    -- Selected node information.
    height = 10 + #self.node.description * lineHeight

    UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_2, ColorList.BACKGROUND_3, height)

    for _, line in pairs(self.node.description) do
        UserInterface.drawText(drawPos, Font.SMALL, ColorList.FONT_MUTED, line)

        drawPos:offset(0, lineHeight)
    end

    drawPos:offset(0, 15)


    -- Node information
    height = 30

    if self.node.isDirectional then
        UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_2, ColorList.BACKGROUND_3, height)
        UserInterface.drawText(drawPos, Font.SMALL, ColorList.FONT_NORMAL, "This node has a direction based on the camera.")

        drawPos:offset(0, height)
    end

    if self.node.isPlanar then
        UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_2, ColorList.BACKGROUND_3, height)
        UserInterface.drawText(drawPos, Font.SMALL, ColorList.FONT_NORMAL, "This node is planar and has volume.")

        drawPos:offset(0, height)
    end


    -- Warning.
    if iProblems > 0 then
        drawPos:offset(0, margin)

        UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_1, ColorList.WARNING, height)
        UserInterface.drawText(drawPos, Font.SMALL, ColorList.WARNING, "[WARNING] %i node(s) have problems (please fix them)", iProblems)

        drawPos:offset(0, height)
    end


    -- Error.
    if self.spawnError then
        drawPos:offset(0, margin)

        UserInterface.drawBackground(drawPos, ColorList.BACKGROUND_1, ColorList.ERROR, height)
        UserInterface.drawText(drawPos, Font.SMALL, ColorList.ERROR, "[ERROR] %s", self.spawnError)

        drawPos:offset(0, height)
    end

    -- Node list.
    local drawListPos = Vector2:new(padding, padding)
    local count = 4
    local iStart = self.iNode - count
    local iEnd = self.iNode + count
    local min = 1
    local max = #self.nodes

    for i = iStart, iEnd do repeat
    	local node = self.nodes[i]

        if not node then
            if i < min then
                node = self.nodes[max + i]
            end

            if i > max then
                node = self.nodes[i - max]
            end

            if not node then
                break
            end
        end

        drawListPos:clone():offset(-2, 0):drawBlur(Vector2:new(tabWidth + 22, 30))
        drawListPos:clone():offset(-2, 0):drawSurfaceRectangle(Vector2:new(tabWidth + 22, 30), ColorList.BACKGROUND_1)

        local color

        if i == self.iNode then
            color = Color:hsla(0, 1, 1, 255)

            drawListPos:clone():offset(8, 6):drawSurfaceRectangle(Vector2:new(tabWidth, 22), ColorList.BACKGROUND_3)
            drawListPos:clone():offset(8, 6):drawSurfaceRectangleOutline(2, 2, Vector2:new(tabWidth, 22), ColorList.FONT_MUTED)
        else
            color  = node.colorPrimary:clone()

            local delta = math.abs(i - self.iNode)
            local alpha = Math.getClampedInversedFloat(delta, count + 1, 0, count + 1) * 250

            color.a = alpha
        end

        drawListPos:clone():offset(20, 17):drawCircle(6, node.colorPrimary):drawCircleOutline(10, 2, node.colorSecondary)
        drawListPos:clone():offset(34, 5):drawSurfaceText(Font.SMALL, color, "l", string.format("%s | %s", node.type, node.name))

        drawListPos:offset(0, height)
    until true end

    if self.spawnNode and self.spawnNode.customizers then
        local drawMetaPos = Client.getScreenDimensionsCenter():offset(-(tabWidth / 2), 300)
        drawListPos:offset(0, 5)

        for _, name in pairs(self.spawnNode.customizers) do
            local metadata = NodeTypeBase.customizerItems[name]:get()

            drawMetaPos:clone():offset(-2, 0):drawBlur(Vector2:new(tabWidth + 22, 30))
            drawMetaPos:clone():offset(-2, 0):drawSurfaceRectangle(Vector2:new(tabWidth + 22, 30), ColorList.BACKGROUND_1)
            drawMetaPos:clone():offset(tabWidth / 2, 5):drawSurfaceText(Font.SMALL_BOLD, ColorList.FONT_NORMAL, "c", string.format("%s:    %s", name, metadata))
            drawMetaPos:offset(0, 30)

        end
    end
end

return Nyx.class("NodegraphEditor", NodegraphEditor)
--}}}
