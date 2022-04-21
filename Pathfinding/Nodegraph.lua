--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Chat = require "gamesense/Nyx/v1/Api/Chat"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Render = require "gamesense/Nyx/v1/Api/Render"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AStar = require "gamesense/Nyx/v1/Dominion/Pathfinding/AStar"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ Nodegraph
--- @class Nodegraph : Class
--- @field canJump boolean
--- @field closestNode Node
--- @field crouchTimer Timer
--- @field ctSpawn Node
--- @field currentNode number
--- @field jumpCooldown Timer
--- @field lastPathfindTimer Timer
--- @field mapMiddle Node
--- @field moveSpeed number
--- @field moveYaw number
--- @field nodes Node[]
--- @field objectiveA Node
--- @field objectiveAChoke Node[]
--- @field objectiveADefend Node[]
--- @field objectiveADefendDefuser Node[]
--- @field objectiveAHold Node[]
--- @field objectiveAHide Node[]
--- @field objectiveAPlant Node[]
--- @field objectiveAPush Node[]
--- @field objectiveB Node
--- @field objectiveBChoke Node[]
--- @field objectiveBDefend Node[]
--- @field objectiveBDefendDefuser Node[]
--- @field objectiveBHold Node[]
--- @field objectiveBHide Node[]
--- @field objectiveBlock Node[]
--- @field objectiveBPlant Node[]
--- @field objectiveBPush Node[]
--- @field objectiveFlashbangDefend Node[]
--- @field objectiveFlashbangExecute Node[]
--- @field objectiveFlashbangHold Node[]
--- @field objectiveHeGrenadeDefend Node[]
--- @field objectiveHeGrenadeExecute Node[]
--- @field objectiveHeGrenadeHold Node[]
--- @field objectiveMolotovDefend Node[]
--- @field objectiveMolotovExecute Node[]
--- @field objectiveMolotovHold Node[]
--- @field objectiveRush Node[]
--- @field objectiveShoot Node[]
--- @field objectiveSmokeDefend Node[]
--- @field objectiveSmokeExecute Node[]
--- @field objectiveSmokeHold Node[]
--- @field objectiveWatchRifle Node[]
--- @field objectiveWatchSniper Node[]
--- @field path Node[]
--- @field pathCurrent number
--- @field pathEnd Node
--- @field pathfindFails number
--- @field pathfindOptions NodegraphPathfindOptions
--- @field pathMap Node[]
--- @field pathStart Node
--- @field moveTargetOrigin Vector3
--- @field stuckTimer Timer
--- @field task string
--- @field tSpawn Node
--- @field unstuckAngles Angle
--- @field unstuckTimer Timer
--- @field cachedPathfindMoveAngle Angle
--- @field moveAngle Angle
--- @field isAllowedToMove boolean
--- @field unblockTimer Timer
--- @field unblockDuration number
--- @field unblockLookAngles Angle
--- @field isDebugging boolean
--- @field isTraversingUpLadder boolean
--- @field isTraversingDownLadder boolean
--- @field isWantingToAttachLadder boolean
local Nodegraph = {
    isDebugging = false
}

--- @return Nodegraph
function Nodegraph:new()
    return Nyx.new(self)
end

--- @return void
function Nodegraph:__init()
    self:initFields()
    self:initEvents()
end

--- @return void
function Nodegraph:initFields()
    self.nodes = {}
    self.currentNode = 0
    self.task = "No task given"
    self.moveSpeed = 450
    self.pathfindFails = 0
    self.unstuckAngles = Client.getCameraAngles()
    self.isAllowedToMove = true
    self.unblockTimer = Timer:new()
    self.unblockDirection = "Left"
    self.unblockDuration = 0.6

    Menu.enableNodegraph = Menu.group:checkbox("> Dominion Nodegraph"):setParent(Menu.master)
    Menu.enableMovement = Menu.group:checkbox("    > Enable Movement"):setParent(Menu.enableNodegraph)
    Menu.visualiseNodegraph = Menu.group:checkbox("    > Visualise Nodegraph"):setParent(Menu.enableNodegraph)
    Menu.visualiseDirectPathing = Menu.group:checkbox("    > Visualise Direct Pathing"):setParent(Menu.visualiseNodegraph)
end

--- @return void
function Nodegraph:initEvents()
    Callbacks.init(function()
        if not globals.mapname() then
            return
        end

        self.jumpCooldown = Timer:new():startThenElapse()
        self.crouchTimer = Timer:new()
        self.stuckTimer = Timer:new()
        self.unstuckTimer = Timer:new()

        self:loadFromDisk(self:getFilename())
        self:setupNodegraph()
    end)

    Callbacks.roundStart(function()
        for _, node in pairs(self.nodes) do
            node.active = true
        end
    end)

    Callbacks.frame(function()
        if not Menu.master:get() or not Menu.enableNodegraph:get()then
            return
        end

        self:renderNodegraph()
    end)

    Callbacks.runCommand(function()
        local playerOrigin = AiUtility.client:getOrigin()
        --- @type Node
        local closestNode
        local closestDistance = math.huge

        for _, node in pairs(self.nodes) do repeat
            if node.type == Node.types.START then
                break
            end

            local distance = playerOrigin:getDistance(node.origin)

            if distance < closestDistance then
                closestDistance = distance
                closestNode = node
            end
        until true end

        self.closestNode = closestNode

        if self.pathfindFails > 0 and not self.path and self.pathfindOptions and self:canPathfind() then
            self:rePathfind()
        end
    end)
end

--- @param origin Vector3
--- @return string
function Nodegraph:getNearestSiteName(origin)
    local aDistance = origin:getDistance(self.objectiveA.origin)
    local bDistance = origin:getDistance(self.objectiveB.origin)

    if aDistance < bDistance then
        return "a"
    else
        return "b"
    end
end

--- @param site string
--- @return Node
function Nodegraph:getSiteNode(site)
    if site == "a" then
        return self.objectiveA
    elseif site == "b" then
        return self.objectiveB
    end
end

--- @param origin Vector3
--- @return Node
function Nodegraph:getNearestSiteNode(origin)
    return self:getSiteNode(self:getNearestSiteName(origin))
end

--- @vararg string
--- @return void
function Nodegraph:log(...)
    if not self.isDebugging then
        return
    end

    local message = string.format(...)

    if not message then
        return
    end

    client.color_log(56, 242, 159, "[Nyx] \0")
    client.color_log(200, 200, 200, message)

    Chat.sendMessage(string.format("%s[Nyx]%s %s", Chat.LIGHT_GREEN, Chat.WHITE, message))
end

--- @return void
function Nodegraph:setupNodegraph()
    if not next(self.nodes) then
        return
    end

    local objectives = {
        [Node.types.OBJECTIVE_A] = "objectiveA",
        [Node.types.OBJECTIVE_B] = "objectiveB",
        [Node.types.MAP_MIDDLE] = "mapMiddle",
        [Node.types.CT_SPAWN] = "ctSpawn",
        [Node.types.T_SPAWN] = "tSpawn",
    }

    -- Unset all objectives.
    for _, v in pairs(objectives) do
        self[v] = nil
    end

    local traces = {
        {
            offset = 10,
            validation = function(nodeTestOrigin)
                local trace = Trace.getHullAtPosition(nodeTestOrigin, Vector3:newBounds(Vector3.align.BOTTOM, 15, 15, 9), AiUtility.traceOptionsPathfinding)

                return not trace.isIntersectingGeometry
            end
        },
        {
            offset = 20,
            validation = function(nodeTestOrigin)
                local trace = Trace.getHullAtPosition(nodeTestOrigin, Vector3:newBounds(Vector3.align.BOTTOM, 30, 30, 9), AiUtility.traceOptionsPathfinding)

                return not trace.isIntersectingGeometry
            end
        },
        {
            offset = 40,
            validation = function(nodeTestOrigin)
                local trace = Trace.getHullAtPosition(nodeTestOrigin, Vector3:newBounds(Vector3.align.BOTTOM, 60, 60, 9), AiUtility.traceOptionsPathfinding)

                return not trace.isIntersectingGeometry
            end
        },
        {
            offset = 60,
            validation = function(nodeTestOrigin)
                local trace = Trace.getHullAtPosition(nodeTestOrigin, Vector3:newBounds(Vector3.align.BOTTOM, 90, 90, 9), AiUtility.traceOptionsPathfinding)

                return not trace.isIntersectingGeometry
            end
        }
    }

    for _, node in pairs(self.nodes) do repeat
        -- Set objectives.
        if objectives[node.type] then
            self[objectives[node.type]] = node
        end

        -- Set max planar ideal offsets.
        if node.type == Node.types.RUN then
            local nodeTestOrigin = node.origin:clone():offset(0, 0, 18)
            local offset = 5
            local isValid = true

            if not isValid then
                break
            end

            for _, trace in pairs(traces) do
                if trace.validation(nodeTestOrigin) then
                    offset = trace.offset
                else
                    isValid = false

                    break
                end
            end

            node.offset = offset
        end
    until true end

    local objectives = {
        a = "objectiveA",
        b = "objectiveB",
    }

    local map = {
        [Node.types.PLANT] = "Plant",
        [Node.types.DEFEND] = "Defend",
        [Node.types.DEFEND_DEFUSER] = "DefendDefuser",
        [Node.types.HIDE] = "Hide",
        [Node.types.HOLD] = "Hold",
        [Node.types.PUSH] = "Push",
        [Node.types.SMOKE_DEFEND] = "SmokeDefend",
        [Node.types.SMOKE_EXECUTE] = "SmokeExecute",
        [Node.types.SMOKE_HOLD] = "SmokeHold",
        [Node.types.FLASHBANG_DEFEND] = "FlashbangDefend",
        [Node.types.FLASHBANG_EXECUTE] = "FlashbangExecute",
        [Node.types.FLASHBANG_HOLD] = "FlashbangHold",
        [Node.types.MOLOTOV_DEFEND] = "MolotovDefend",
        [Node.types.MOLOTOV_EXECUTE] = "MolotovExecute",
        [Node.types.MOLOTOV_HOLD] = "MolotovHold",
        [Node.types.HE_GRENADE_DEFEND] = "HeGrenadeDefend",
        [Node.types.HE_GRENADE_EXECUTE] = "HeGrenadeExecute",
        [Node.types.HE_GRENADE_HOLD] = "HeGrenadeHold",
        [Node.types.RUSH] = "Rush",
        [Node.types.CHOKE] = "Choke",
        [Node.types.SHOOT] = "Shoot",
        [Node.types.CROUCH_SHOOT] = "Shoot",
        [Node.types.BLOCK] = "Block",
        [Node.types.WATCH_RIFLE] = "WatchRifle",
        [Node.types.WATCH_SNIPER] = "WatchSniper",
    }

    local linkToObjective = {
        [Node.types.PLANT] = true,
        [Node.types.DEFEND] = true,
        [Node.types.DEFEND_DEFUSER] = true,
        [Node.types.HIDE] = true,
        [Node.types.HOLD] = true,
        [Node.types.PUSH] = true,
        [Node.types.CHOKE] = true,
    }

    local isTraversalNode = {
        [Node.types.RUN] = true,
        [Node.types.CROUCH] = true,
        [Node.types.JUMP] = true,
        [Node.types.SHOOT] = true,
        [Node.types.CROUCH_SHOOT] = true,
        [Node.types.DOOR] = true,
        [Node.types.GAP] = true
    }

    --- @type Node[]
    local siteNodes = {}

    if self.objectiveA then
        siteNodes.a = self.objectiveA
    end

    if self.objectiveB then
        siteNodes.b = self.objectiveB
    end

    -- Set arrays.
    for id, nodeType in pairs(map) do
        for _, objective in pairs(objectives) do
            if linkToObjective[id] then
                self[string.format("%s%s", objective, nodeType)] = {}
            else
                self[string.format("objective%s", nodeType)] = {}
            end
        end
    end

    local radius = 4000

    -- Set activity nodes.
    for _, node in pairs(self.nodes) do
        if map[node.type] and not linkToObjective[node.type] then
            table.insert(self[string.format("objective%s", map[node.type])], node)
        elseif map[node.type] and linkToObjective[node.type] then
            local closestSite
            local closestDistance = math.huge

            for site, siteNode in pairs(siteNodes) do
                local distance = node.origin:getDistance(siteNode.origin)

                if distance < closestDistance and distance < radius then
                    closestDistance = distance
                    closestSite = site
                end
            end

            if closestSite then
                local field = string.format("%s%s", objectives[closestSite], map[node.type])

                node.site = closestSite

                table.insert(self[field], node)
            end
        end
    end
end

--- @return void
function Nodegraph:clearNodegraph()
    self.nodes = {}
    self.currentNode = 0

    self:setupNodegraph()
end

--- @return void
function Nodegraph:renderNodegraph()
    if not Menu.visualiseNodegraph:get() then
        return
    end

    if Menu.visualiseDirectPathing:get() then
        local playerOrigin = Player.getClient():getOrigin():offset(0, 0, 16)
        local bounds = Vector3:newBounds(Vector3.align.BOTTOM, 14, 14, 18)

        for _, searchNode in pairs(self.nodes) do
            if playerOrigin:getDistance(searchNode.origin) < 256 then
                local isPathable = self:isJumpNodeValid(playerOrigin, searchNode)
                local trace = Trace.getHullToPosition(playerOrigin, searchNode.origin, bounds, AiUtility.traceOptionsPathfinding)

                isPathable = not trace.isIntersectingGeometry

                local color

                if isPathable then
                    color = Color:hsla(100, 0.8, 0.6)

                    playerOrigin:drawLine(searchNode.origin, Color:hsla(100, 0.8, 0.6, 100), 0.25)
                else
                    color = Color:hsla(0, 0.8, 0.6)

                    playerOrigin:drawLine(searchNode.origin, Color:hsla(0, 0.8, 0.6, 100), 0.25)
                end

                searchNode.origin:drawScaledCircleOutline(searchNode.origin, 60, 10, color)

                trace.endPosition:drawScaledCircle(14, color)
            end
        end
    end

    local cameraOrigin = Client.getCameraOrigin()

    for _, node in pairs(self.nodes) do
        local alpha = Math.getInversedFloat(cameraOrigin:getDistance(node.origin), 1000) * 255

        if alpha > 0 then
            local color = Node.typesColor[node.type]:clone()
            local colorFont = color:clone()

            color.a = alpha

            colorFont.a = Math.getInversedFloat(cameraOrigin:getDistance(node.origin), 256) * 255

            for _, connection in pairs(node.connections) do
                local lineColor = Color:rgba(150, 150, 150, math.min(35, alpha))

                if self.pathMap and self.pathMap[node.id] and self.pathMap[connection.id] then
                    lineColor = color
                end

                node.origin:drawLine(connection.origin, lineColor, 0.25)
            end

            local radius, thickness = 33, (node.active and 15 or 6)

            node.origin:drawScaledCircleOutline(radius, thickness, color)

            if self.pathMap and self.pathMap[node.id] then
                node.origin:drawScaledCircle(radius + 16, color:clone():setAlpha(math.min(150, alpha)))
            end

            local site = ""

            if node.site then
                site = string.format(" (%s)", node.site:upper())
            end

            local text = string.format("[%s] %s%s", node.id, Node.typesCode[node.type], site)

            if colorFont.a > 0 then
                node.origin:clone():offset(0, 0, 14):drawSurfaceText(Font.TINY, colorFont, "c", text)
            end

            if node.direction then
                local directionOffset = node.origin + node.direction:getForward() * 16

                directionOffset:drawScaledCircle(8, color)
            end
        end
    end
end

--- @return void
function Nodegraph:reactivateAllNodes()
    for _, node in pairs(self.nodes) do
        node.active = true
    end
end

--- @param reason string
--- @return void
function Nodegraph:clearPath(reason)
    self.path = nil
    self.pathCurrent = 0

    if self.pathStart then
        self:removeNode(self.pathStart)
    end

    if self.pathEnd then
        self:removeNode(self.pathEnd)
    end

    self.pathStart = nil
    self.pathEnd = nil
    self.pathMap = nil

    self.jumpCooldown = Timer:new():startThenElapse()
    self.crouchTimer = Timer:new()
    self.useCooldown = Timer:new():startThenElapse()
    self.stuckTimer = Timer:new()
    self.lastPathfindTimer = Timer:new()

    self:log("Cleared path (%s)", reason)
end

--- @param filename string
--- @return void
function Nodegraph:loadFromDisk(filename)
    local filedata = readfile(filename)

    if not filedata then
        print(string.format("Cannot load nodegraph. Missing file '%s'.", filename))

        return
    end

    local json = json.parse(filedata)

    if not json then
        print(string.format("Cannot load nodegraph. Invalid JSON in file '%s'.", filename))

        return
    end

    --- @type Node[]
    local nodes = {}

    for _, nodeData in pairs(json.nodes) do
        nodes[nodeData.id] = Node:new({
            id = nodeData.id,
            origin = Vector3:new(nodeData.origin.x, nodeData.origin.y, nodeData.origin.z),
            connections = nodeData.connections,
            type = nodeData.type
        })

        if nodeData.direction then
            nodes[nodeData.id].direction = Angle:new(nodeData.direction.p, nodeData.direction.y)
        end
    end

    for _, node in pairs(nodes) do
        local connections = node.connections

        node.connections = {}

        for _, connection in pairs(connections) do
            node.connections[connection] = nodes[connection]
        end

        if Node.typesPaired[node.type] then
            --- @type Node
            local closestNode
            local closestDistance = math.huge

            for _, testNode in pairs(nodes) do
                if node.id ~= testNode.id and testNode.type == node.type then
                    local distance = node.origin:getDistance(testNode.origin)

                    if distance < closestDistance then
                        closestDistance = distance
                        closestNode = testNode
                    end
                end
            end

            node.pair = closestNode
        end
    end

    self.nodes = nodes
    self.currentNode = json.currentNode
end

--- @param filename string
--- @return void
function Nodegraph:saveToDisk(filename)
    local nodeData = {}
    local iNodeData = 0
    local invalidNodes = {
        [Node.types.GOAL] = true,
        [Node.types.START] = true,
        [Node.types.ENEMY] = true,
        [Node.types.BOMB] = true,
    }

    -- Remove nodes that must not be accidentally saved
    for _, node in pairs(self.nodes) do
        if invalidNodes[node.type] then
            self:removeNode(node)
        end
    end

    for _, node in pairs(self.nodes) do
        iNodeData = iNodeData + 1

        local connections = {}

        for _, connection in pairs(node.connections) do
            table.insert(connections, connection.id)
        end

        nodeData[iNodeData] = {
            id = node.id,
            origin = {
                x = math.floor(node.origin.x),
                y = math.floor(node.origin.y),
                z = math.floor(node.origin.z)
            },
            connections = connections,
            type = node.type
        }

        if node.direction then
            nodeData[iNodeData].direction = {
                p = node.direction.p,
                y = node.direction.y
            }
        end
    end

    writefile(filename, json.stringify({
        nodes = nodeData,
        currentNode = self.currentNode
    }))
end

--- @return string
function Nodegraph:getFilename()
    local map = globals.mapname()

    map = map:gsub("/", "_")

    return string.format("lua/gamesense/Nyx/v1/Dominion/Pathfinding/Nodegraphs/%s.json", map)
end

--- @param origin Vector3
--- @param connections Node[]
--- @param types number[]
--- @return void
function Nodegraph:createNode(origin, connections, types)
    self:addNode(Node:new({
        origin = origin,
        connections = connections or {},
        types = types or {1}
    }))
end

--- @param node Node
--- @return void
function Nodegraph:addNode(node)
    local latestId = self.currentNode + 1

    node.id = latestId
    self.currentNode = latestId
    self.nodes[latestId] = node
end

--- @param node Node
--- @return void
function Nodegraph:removeNode(node)
    self.nodes[node.id] = nil

    for _, connection in pairs(node.connections) do
        connection.connections[node.id] = nil
    end
end

--- @param origin Vector3
--- @return Node
function Nodegraph:getClosestNode(origin)
    local closestNode
    local closestDistance = math.huge

    for _, node in pairs(self.nodes) do
        local distance = origin:getDistance(node.origin)

        if distance < closestDistance then
            closestDistance = distance
            closestNode = node
        end
    end

    return closestNode
end

--- @param origin Vector3
--- @param nodeType number
--- @return Node
function Nodegraph:getClosestNodeOf(origin, nodeType)
    local closestNode
    local closestDistance = math.huge
    local isTable = type(nodeType) == "table"

    if isTable then
        local map = {}

        for _, value in pairs(nodeType) do
            table.insert(map, value, true)
        end

        for _, node in pairs(self.nodes) do repeat
            if not map[node.type] then
                break
            end

            local distance = origin:getDistance(node.origin)

            if distance < closestDistance then
                closestDistance = distance
                closestNode = node
            end
        until true end
    else
        for _, node in pairs(self.nodes) do repeat
            if node.type ~= nodeType then
                break
            end

            local distance = origin:getDistance(node.origin)

            if distance < closestDistance then
                closestDistance = distance
                closestNode = node
            end
        until true end
    end

    return closestNode
end

--- @param origin Vector3
--- @param distance number
--- @return Node
function Nodegraph:getRandomNodeWithin(origin, distance)
    local nodes = {}

    for _, node in pairs(self.nodes) do
        if origin:getDistance(node.origin) <= distance then
            table.insert(nodes, node)
        end
    end

    return Table.getRandom(nodes)
end

--- @param origin Vector3
--- @param ignoreEid number
--- @return Node[]
function Nodegraph:getVisibleNodesFrom(origin, ignoreEid)
    local nodes = {}

    for _, node in pairs(self.nodes) do
        local _, fraction = origin:getTraceLine(node.origin, ignoreEid)

        if fraction == 1 then
            table.insert(nodes, node)
        end
    end

    return nodes
end

--- @param origin Vector3
--- @param node Node
--- @return boolean
function Nodegraph:isJumpNodeValid(origin, node)
    if math.abs(node.origin.z - origin.z) > 32 then
        return false
    end

    return true
end

--- @return void
function Nodegraph:rePathfind()
    if not self.pathEnd then
        return
    end

    self:pathfind(self.pathEnd.origin:clone():offset(0, 0, -18), self.pathfindOptions)
end

--- @class NodegraphPathfindOptions
--- @field objective number
--- @field task string
--- @field onComplete function
--- @field onFail function
--- @field canUseInactive boolean
---
--- @param origin Vector3
--- @param options NodegraphPathfindOptions
--- @return void
function Nodegraph:pathfind(origin, options)
    if not Menu.master:get() or not Menu.enableNodegraph:get() then
        return
    end

    self:clearPath("Begin new path")

    self.lastPathfindTimer:start()

    options = options or {}

    Table.setMissing(options, {
        canUseInactive = false
    })

    local player = AiUtility.client
    local playerOrigin = player:getOrigin():offset(0, 0, 16)

    local pathStart = Node:new({
        origin = playerOrigin,
        connections = {},
        type = Node.types.START
    })

    local pathEnd = Node:new({
        origin = origin + Vector3:new(0, 0, 18),
        connections = {},
        type = options.objective or Node.types.GOAL
    })

    self.pathStart = pathStart
    self.pathEnd = pathEnd

    self:addNode(pathStart)
    self:addNode(pathEnd)

    self:setConnections(pathStart, false)

    if not next(pathStart.connections) then
        self:setConnections(pathStart, false)
    end

    self:setConnections(pathEnd, true)

    local reachCheckNodes = {
        [Node.types.JUMP] = true,
        [Node.types.GAP] = true,
    }

    local path = AStar.find(pathStart, pathEnd, self.nodes, true, function(node, neighbor)
        local canReach = true

        if reachCheckNodes[neighbor.type] and (neighbor.origin.z - node.origin.z > 64) then
            canReach = false
        end

        if options.canUseInactive then
            return node.connections[neighbor.id] and canReach
        else
            return node.connections[neighbor.id] and node.active and canReach
        end
    end)

    if not path then
        self:log("Pathfind failed")

        if options.onFail then
            options.onFail()
        end

        self.pathfindFails = self.pathfindFails + 1

        return
    end

    self.pathfindOptions = options
    self.path = path
    self.pathCurrent = 1
    self.task = options.task or "Unnamed task"
    self.pathMap = {}
    self.pathfindFails = 0

    for _, node in pairs(path) do
        self.pathMap[node.id] = node
    end

    self:generateMoveTargetOrigin()

    self:log("Begin new path (%s)", self.task)
end

--- @return boolean
function Nodegraph:canPathfind()
    return not self.lastPathfindTimer:isStarted() or self.lastPathfindTimer:isElapsed(0.2)
end

--- @param node Node
--- @param pathLine boolean
--- @return void
function Nodegraph:setConnections(node, pathLine)
    node.connections = {}

    local bounds = Vector3:newBounds(Vector3.align.BOTTOM, 14, 14, 18)

    for _, searchNode in pairs(self.nodes) do
        if searchNode.id ~= node.id and node.origin:getDistance(searchNode.origin) < 256 then
            local isPathable = true

            isPathable = self:isJumpNodeValid(node.origin, searchNode)

            if pathLine then
                local trace = Trace.getLineToPosition(node.origin, searchNode.origin, AiUtility.traceOptionsPathfinding)

                if trace.isIntersectingGeometry then
                    isPathable = false
                end
            else
                local trace = Trace.getHullToPosition(node.origin, searchNode.origin, bounds, AiUtility.traceOptionsPathfinding)

                isPathable = not trace.isIntersectingGeometry
            end

            if isPathable then
                node.connections[searchNode.id] = searchNode
                searchNode.connections[node.id] = node
            end
        end
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function Nodegraph:processMovement(cmd)
    if not Menu.master:get() or not Menu.enableNodegraph:get() or not Menu.enableMovement:get() then
        return
    end

    local player = AiUtility.client
    local origin = player:getOrigin()
    local isAllowedToMove = self.isAllowedToMove

    self.isAllowedToMove = true

    -- We're blocked from moving.
    if not isAllowedToMove then
        return
    end

    -- Deal with moving.
    if self.pathfindFails > 0 then
        self.unstuckTimer:ifPausedThenStart()

        self:executeMovementForward(cmd)
    else
        self.unstuckTimer:stop()
        self.unstuckAngles = Client.getCameraAngles()
    end

    if self.moveAngle then
        self:executeMovement(cmd, self.moveAngle)

        self.cachedPathfindMoveAngle = self.moveAngle
    end

    if not self.path then
        self.task = "Idle"

        return
    end

    local node = self.path[self.pathCurrent]

    if not node then
        if self.pathfindOptions.onComplete then
            self.pathfindOptions.onComplete()
        end

        self:clearPath("Path completed")

        return
    end

    -- Node we're trying to pathfind over is inactive.
    if not self.pathfindOptions.canUseInactive and not node.active then
        self:rePathfind()
    end

    local angleToNode = origin:getAngle(self.moveTargetOrigin)

    self.cachedPathfindMoveAngle = angleToNode

    if not self.moveAngle then
        self:executeMovement(cmd, angleToNode)
    end

    self.moveAngle = nil

    self:avoidTeammates(cmd)
    self:avoidClipping(cmd)

    -- Deal with jumping and ducking.
    -- Auto-duck in-air, except when falling.
    if not player:getFlag(Player.flags.FL_ONGROUND) then
        local velocity = player:m_vecVelocity()

        if velocity.z > 0 then
            cmd.in_duck = 1
        end
    end

    local distance = origin:getDistance2(self.moveTargetOrigin)

    -- Crouch under cover
    local crouchNode = self:getClosestNodeOf(origin, {Node.types.CROUCH, Node.types.CROUCH_SHOOT})

    if crouchNode and origin:getDistance(crouchNode.origin) < 32 then
        self.crouchTimer:start()
    end

    self.crouchTimer:isElapsedThenStop(0.4)

    if self.crouchTimer:isStarted() then
        cmd.in_duck = 1
    end

    -- Setup can-jump.
    local canJump = self.canJump
    self.canJump = true

    if node.type == Node.types.JUMP then
        if canJump and distance < 32 and node.origin.z - origin.z > 18 then
            if self.jumpCooldown:isElapsedThenRestart(0.6) then
                cmd.in_jump = 1

                self.pathCurrent = self.pathCurrent + 1
            end
        elseif distance < 32 and node.origin.z - origin.z < 18 then
            if self.jumpCooldown:isElapsedThenRestart(0.6) then
                self:moveOntoNextNode()
            end
        end
    elseif node.type == Node.types.GAP then
        if distance < 16 then
            cmd.in_jump = 1

            self:moveOntoNextNode()
        end
    else
        if distance < 20 then
            self:moveOntoNextNode()
        end
    end

    -- Re-pathfind when stuck
    local gameRules = Entity.getGameRules()

    if gameRules:m_bFreezePeriod() ~= 1 and player:getFlag(Player.flags.FL_ONGROUND) then
        local speed = player:m_vecVelocity():set(nil, nil, 0):getMagnitude()

        if not self.stuckTimer:isStarted() and speed < 64 then
            self.stuckTimer:start()
        elseif self.stuckTimer:isStarted() and speed >= 64 then
            self.stuckTimer:stop()
        elseif self.stuckTimer:isElapsedThenRestart(1) then
            self:rePathfind()

            local closestJumpNode = self:getClosestNodeOf(origin, Node.types.JUMP)

            -- Jump over obstacles
            if closestJumpNode and origin:getDistance(closestJumpNode.origin) < 64 and self.canJump then
                cmd.in_jump = 1
            end
        end
    end
end

--- @return void
function Nodegraph:moveOntoNextNode()
    self.pathCurrent = self.pathCurrent + 1

    self:generateMoveTargetOrigin()
end

--- @return void
function Nodegraph:generateMoveTargetOrigin()
    local node = self.path[self.pathCurrent]

    if not node then
        self.moveTargetOrigin = nil

        return
    end

    if not node.offset then
        self.moveTargetOrigin = node.origin

        return
    end

    local idealOrigin = node.origin + Vector3:new(
        Client.getRandomFloat(-node.offset, node.offset),
        Client.getRandomFloat(-node.offset, node.offset),
        0
    )

    local trace = Trace.getHullToPosition(node.origin, idealOrigin, Vector3:newBounds(Vector3.align.UP, 32, 32, 16), AiUtility.traceOptionsPathfinding)

    -- Generate a random vector around the node's origin.
    self.moveTargetOrigin = trace.endPosition
end

--- @param cmd SetupCommandEvent
--- @return boolean
function Nodegraph:avoidTeammates(cmd)
    if not self.canAntiBlock then
        self.canAntiBlock = true

        return
    end

    if not self.cachedPathfindMoveAngle then
        return
    end

    if Entity.getGameRules():m_bFreezePeriod() == 1 then
        return
    end

    local player = AiUtility.client

    local isBlocked = false
    local origin = player:getOrigin()
    local collisionOrigin = origin:clone():offset(0, 0, 36) + (self.cachedPathfindMoveAngle:clone():set(0):getForward() * 60)
    local collisionBounds = collisionOrigin:getBounds(Vector3.align.CENTER, 32, 32, 40)
    --- @type Player
    local blockingTeammate

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():offset(0, 0, 32):isInBounds(collisionBounds) then
            isBlocked = true

            blockingTeammate = teammate

            break
        end
    end

    if not isBlocked then
        self.unblockLookAngles = nil

        return
    end

    if not self.unblockLookAngles then
        self.unblockLookAngles = Client.getEyeOrigin():getAngle(blockingTeammate:getEyeOrigin())
    end

    self.unblockTimer:ifPausedThenStart()

    if self.unblockTimer:isElapsedThenStop(self.unblockDuration) then
        self.unblockDirection = Client.getChance(2) and "Left" or "Right"
        self.unblockDuration = Client.getRandomFloat(0.66, 1)
    end

    local directionMethod = string.format("get%s", self.unblockDirection)
    local eyeOrigin = Client.getEyeOrigin()
    local movementAngles = self.cachedPathfindMoveAngle
    local directionOffset = eyeOrigin + movementAngles[directionMethod](movementAngles) * 150

    self:executeMovement(cmd, eyeOrigin:getAngle(directionOffset))
end

--- @param cmd SetupCommandEvent
--- @return boolean
function Nodegraph:avoidClipping(cmd)
    if not self.cachedPathfindMoveAngle then
        return false
    end

    local isDucking = AiUtility.client:getFlag(Player.flags.FL_DUCKING)
    local clientOrigin = Client.getOrigin()
    local origin = clientOrigin:offset(0, 0, 18)
    local boundsTraceOrigin = Client.getOrigin():offset(0, 0, 36)
    local moveAngle = self.cachedPathfindMoveAngle
    local moveAngleForward = moveAngle:getForward()
    local boundsOrigin = origin + moveAngleForward * 20
    local bounds = Vector3:newBounds(Vector3.align.UP, 6, 6, isDucking and 18 or 27)
    local directions = {
        Left = Angle.getLeft,
        Right = Angle.getRight
    }

    --- @type Angle
    local avoidAngle
    local clipCount = 0

    for _, direction in pairs(directions) do
        --- @type Vector3
        local checkDirection = direction(moveAngle)
        local boundsTraceOffset = boundsOrigin + checkDirection * 20
        local trace = Trace.getHullToPosition(boundsTraceOrigin, boundsTraceOffset, bounds, AiUtility.traceOptionsPathfinding)

        if trace.isIntersectingGeometry then
            local avoidDirection = clientOrigin - checkDirection * 8

            avoidAngle = clientOrigin:getAngle(avoidDirection)
            clipCount = clipCount + 1
        end
    end

    if avoidAngle and clipCount ~= 2 then
        self:executeMovement(cmd, avoidAngle)

        return true
    end

    return false
end

--- @param cmd SetupCommandEvent
--- @param moveAngle Angle
--- @return void
function Nodegraph:executeMovement(cmd, moveAngle)
    if not Config.isEmulatingRealUserInput then
        cmd.move_yaw = moveAngle.y
        cmd.forwardmove = 450

        return
    end

    local directions = {
        [0] = function()
            cmd.forwardmove = 450
            cmd.in_forward = true
        end,
        [-45] = function()
            cmd.forwardmove = 450
            cmd.sidemove = 450
            cmd.in_forward = true
            cmd.in_moveright = true
        end,
        [-90] = function()
            cmd.sidemove = 450
            cmd.in_right = true
        end,
        [-135] = function()
            cmd.forwardmove = -450
            cmd.sidemove = 450
            cmd.in_right = true
            cmd.in_back = true
        end,
        [180] = function()
            cmd.forwardmove = -450
            cmd.in_back = true
        end,
        [135] = function()
            cmd.forwardmove = -450
            cmd.sidemove = -450
            cmd.in_back = true
            cmd.in_left = true
        end,
        [90] = function()
            cmd.sidemove = -450
            cmd.in_left = true
        end,
        [45] = function()
            cmd.forwardmove = 450
            cmd.sidemove = -450
            cmd.in_forward = true
            cmd.in_left = true
        end
    }

    moveAngle:set(0)

    --- @type fun(): void
    local closestCallback
    local lowestDelta = math.huge

    for yaw, callback in pairs(directions) do
        local directionAngle = Angle:new(0, yaw + cmd.move_yaw):normalize()
        local deltaAngle = directionAngle:getAbsDiff(moveAngle)

        if deltaAngle.y < lowestDelta then
            lowestDelta = deltaAngle.y
            closestCallback = callback
        end
    end

    if closestCallback then
        closestCallback()
    end
end

--- @param e SetupCommandEvent
--- @return void
function Nodegraph:executeMovementForward(e)
    e.forwardmove = 450
    e.in_forward = 1
end

--- @return void
function Nodegraph:executeMovementStop() end

return Nyx.class("Nodegraph", Nodegraph)
--}}}
