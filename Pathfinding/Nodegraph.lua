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
--- @field objectiveAPlant Node[]
--- @field objectiveAPush Node[]
--- @field objectiveB Node
--- @field objectiveBChoke Node[]
--- @field objectiveBDefend Node[]
--- @field objectiveBDefendDefuser Node[]
--- @field objectiveBHold Node[]
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
--- @field path Node[]
--- @field pathCurrent number
--- @field pathEnd Node
--- @field pathfindFails number
--- @field pathfindOptions NodegraphPathfindOptions
--- @field pathMap Node[]
--- @field pathStart Node
--- @field stuckTimer Timer
--- @field task string
--- @field tSpawn Node
--- @field unstuckAngles Angle
--- @field unstuckTimer Timer
local Nodegraph = {}

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
function Nodegraph:getNearestBombSite(origin)
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

--- @vararg string
--- @return void
function Nodegraph:log(...)
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

    local map = {
        [Node.types.OBJECTIVE_A] = "objectiveA",
        [Node.types.OBJECTIVE_B] = "objectiveB",
        [Node.types.MAP_MIDDLE] = "mapMiddle",
        [Node.types.CT_SPAWN] = "ctSpawn",
        [Node.types.T_SPAWN] = "tSpawn",
    }

    -- Unset all objectives.
    for _, v in pairs(map) do
        self[v] = nil
    end

    -- Set all objectives.
    for _, node in pairs(self.nodes) do
        if map[node.type] then
            self[map[node.type]] = node
        end
    end

    local objectives = {
        a = "objectiveA",
        b = "objectiveB",
    }

    local map = {
        [Node.types.PLANT] = "Plant",
        [Node.types.DEFEND] = "Defend",
        [Node.types.DEFEND_DEFUSER] = "DefendDefuser",
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
        [Node.types.BLOCK] = "Block"
    }

    local linkToObjective = {
        [Node.types.PLANT] = true,
        [Node.types.DEFEND] = true,
        [Node.types.DEFEND_DEFUSER] = true,
        [Node.types.HOLD] = true,
        [Node.types.PUSH] = true,
        [Node.types.CHOKE] = true
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
function Nodegraph:renderNodegraph()
    if not Menu.visualiseNodegraph:get() then
        return
    end

    if Menu.visualiseDirectPathing:get() then
        local origin = AiUtility.client:getOrigin():offset(0, 0, 18)

        for _, searchNode in pairs(self.nodes) do
            if origin:getDistance(searchNode.origin) < 256 then
                local bounds = Vector3:newBounds(Vector3.align.CENTER, 16, 16, 4)

                local a = origin + bounds[1]
                local b = origin + bounds[2]

                a:drawCircle(4, Color:rgba())
                b:drawCircle(4, Color:rgba())

                local trace = Trace.getHullToPosition(origin, searchNode.origin, bounds, {
                    skip = function(eid)
                        local entity = Entity:create(eid)

                        if entity.classname ~= "CWorld" then
                            return true
                        end
                    end,
                    mask = Trace.mask.PLAYERSOLID,
                    contents = Trace.contents.SOLID,
                    type = Trace.type.EVERYTHING
                })

                local color

                if trace.isIntersectingGeometry then
                    origin:drawLine(searchNode.origin, Color:hsla(0, 0.8, 0.6, 100), 0.25)

                    color = Color:hsla(0, 0.8, 0.6)
                else
                    origin:drawLine(searchNode.origin, Color:hsla(100, 0.8, 0.6, 100), 0.25)

                    color = Color:hsla(100, 0.8, 0.6)
                end

                local radius, thickness = Render.scaleCircle(searchNode.origin, 60, 10)

                searchNode.origin:drawCircleOutline(radius, thickness, color)
            end
        end
    end

    local cameraOrigin = Client.getCameraOrigin()

    for _, node in pairs(self.nodes) do
        local alpha = Math.pcti(cameraOrigin:getDistance(node.origin), 1000) * 255

        if alpha > 0 then
            local color = Node.typesColor[node.type]:clone()

            color.a = alpha

            for _, connection in pairs(node.connections) do
                local lineColor = Color:rgba(150, 150, 150, math.min(35, alpha))

                if self.pathMap and self.pathMap[node.id] and self.pathMap[connection.id] then
                    lineColor = color
                end

                node.origin:drawLine(connection.origin, lineColor, 0.25)
            end

            local thickness = node.active and 15 or 6
            local radius, thickness = Render.scaleCircle(node.origin, 33, thickness)

            node.origin:drawCircleOutline(radius, thickness, color)

            if self.pathMap and self.pathMap[node.id] then
                node.origin:drawCircle(radius + 2, color:clone():setAlpha(math.min(150, alpha)))
            end

            local site = ""

            if node.site then
                site = string.format(" (%s)", node.site:upper())
            end

            local text = string.format("%s%s", Node.typesCode[node.type], site)

            node.origin:clone():offset(0, 0, 14):drawSurfaceText(Font.SMALL, color, "c", text)

            if node.direction then
                local directionOffset = node.origin + node.direction:getForward() * 16
                local radius = Render.scaleCircle(directionOffset, 8, 0)

                directionOffset:drawCircle(radius, color)
            end
        end
    end
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
--- @field ignore number
--- @field line boolean
--- @field task string
--- @field onComplete function
--- @field onFail function
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

    local player = AiUtility.client
    local playerOrigin = player:getOrigin()

    local pathStart = Node:new({
        origin = playerOrigin + Vector3:new(0, 0, 18),
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
        self:setConnections(pathStart, true)
    end

    self:setConnections(pathEnd, options.ignore, true)

    local path = AStar.find(pathStart, pathEnd, self.nodes, true, function(node, neighbor)
        local canReach = true

        if (neighbor.type == Node.types.JUMP or neighbor.type == Node.types.GAP) and (neighbor.origin.z - node.origin.z > 64) then
            canReach = false
        end

        return node.connections[neighbor.id] and node.active and canReach
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

    self:log("Begin new path (%s)", self.task)
end

--- @return boolean
function Nodegraph:canPathfind()
    return not self.lastPathfindTimer:isStarted() or self.lastPathfindTimer:isElapsed(1)
end

--- @param node Node
--- @param pathLine boolean
--- @return void
function Nodegraph:setConnections(node, pathLine)
    node.connections = {}

    for _, searchNode in pairs(self.nodes) do
        if searchNode.id ~= node.id and node.origin:getDistance(searchNode.origin) < 256 then
            local isPathable = true

            isPathable = self:isJumpNodeValid(node.origin, searchNode)

            if pathLine then
                local trace = Trace.getLineToPosition(node.origin, searchNode.origin, {
                    skip = function(eid)
                        local entity = Entity:create(eid)

                        if entity.classname ~= "CWorld" then
                            return true
                        end
                    end,
                    mask = Trace.mask.PLAYERSOLID,
                    contents = Trace.contents.SOLID,
                    type = Trace.type.EVERYTHING
                })

                if trace.isIntersectingGeometry then
                    isPathable = false
                end
            else
                local trace = Trace.getHullToPosition(node.origin, searchNode.origin, Vector3:newBounds(Vector3.align.CENTER, 8, 8, 4), {
                    skip = function(eid)
                        local entity = Entity:create(eid)

                        if entity.classname ~= "CWorld" then
                            return true
                        end
                    end,
                    mask = Trace.mask.PLAYERSOLID,
                    contents = Trace.contents.SOLID,
                    type = Trace.type.EVERYTHING
                })

                if trace.isIntersectingGeometry then
                    isPathable = false
                end
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
function Nodegraph:move(cmd)
    if not Menu.master:get() or not Menu.enableNodegraph:get() or not Menu.enableMovement:get() then
        return
    end

    -- Attempt to unstuck ourselves
    if self.pathfindFails > 0 then
        self.unstuckTimer:ifPausedThenStart()

        cmd.forwardmove = self.moveSpeed or 450
        --cmd.move_yaw = self.unstuckAngles.y

        self.unstuckAngles.y = self.unstuckAngles.y + 45 * Time.delta()
    else
        self.unstuckTimer:stop()
        self.unstuckAngles = Client.getCameraAngles()
    end

    -- No path to move along
    if not self.path then
        self.task = "Idle"

        if self.moveYaw then
            -- Move to next node
            cmd.forwardmove = self.moveSpeed
            cmd.move_yaw = self.moveYaw

            -- Reset move overrides
            self.moveYaw = nil
            self.moveSpeed = 450
        end

        return
    end

    local player = AiUtility.client
    local origin = player:getOrigin()
    local node = self.path[self.pathCurrent]

    -- Finished path
    if not node then
        -- On path completed
        if self.pathfindOptions.onComplete then
            self.pathfindOptions.onComplete()
        end

        self:clearPath("Path completed")

        return
    end

    -- Path is inactive
    if not node.active then
        self:rePathfind()
    end

    -- Movement direction
    local angleToNode = origin:getAngle(node.origin)

    -- Move to next node
    cmd.forwardmove = self.moveSpeed
    cmd.move_yaw = self.moveYaw and self.moveYaw or angleToNode.y

    -- Reset move overrides
    self.moveYaw = nil
    self.moveSpeed = 450

    local distance = origin:getDistance2(node.origin)

    -- Crouch under cover
    local crouchNode = self:getClosestNodeOf(origin, {Node.types.CROUCH, Node.types.CROUCH_SHOOT})

    if crouchNode and origin:getDistance(crouchNode.origin) < 32 then
        self.crouchTimer:start()
    end

    self.crouchTimer:isElapsedThenStop(0.33)

    if self.crouchTimer:isStarted() then
        cmd.in_duck = 1
    end

    -- Can jump
    local canJump = self.canJump
    local jumpNode = node

    self.canJump = true

    -- Jump over obstacles
    if canJump and self.jumpCooldown:isElapsedThenRestart(0.4) and distance < 54 and (jumpNode.type == Node.types.JUMP) then
        if jumpNode.origin.z - origin.z > 18 then
            cmd.in_jump = 1

            self.pathCurrent = self.pathCurrent + 1
        end
    end

    -- Jump gaps
    if canJump and jumpNode.type == Node.types.GAP and distance < 40 then
        cmd.in_jump = 1

        self.pathCurrent = self.pathCurrent + 1
    end

    -- Move onto next node
    if distance < 20 then
        self.pathCurrent = self.pathCurrent + 1
    end

    -- Re-pathfind when stuck
    local gameRules = Entity.getGameRules()

    if gameRules:m_bFreezePeriod() ~= 1 and player:getFlag(Player.flags.FL_ONGROUND) then
        local speed = player:m_vecVelocity():set(nil, nil, 0):getMagnitude()

        if not self.stuckTimer:isStarted() and speed < 100 then
            self.stuckTimer:start()
        elseif self.stuckTimer:isStarted() and speed >= 100 then
            self.stuckTimer:stop()
        elseif self.stuckTimer:isElapsedThenRestart(1.5) then
            self:rePathfind()

            local closestJumpNode = self:getClosestNodeOf(origin, Node.types.JUMP)

            -- Jump over obstacles
            if closestJumpNode and origin:getDistance(closestJumpNode.origin) < 64 then
                cmd.in_jump = 1
            end
        end
    end
end

return Nyx.class("Nodegraph", Nodegraph)
--}}}
