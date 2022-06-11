--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Chat = require "gamesense/Nyx/v1/Api/Chat"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local NodeType = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeType"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
--}}}

--{{{ Nodegraph
--- @class NodegraphDataSerialized
--- @field iNodes number
--- @field nodes NodeTypeBase[]

--- @class Nodegraph : Class
--- @field freeIds number[]
--- @field iNodes number
--- @field isLoaded boolean
--- @field nodeClassMap table<string, NodeTypeBase[]>
--- @field nodes NodeTypeBase[]
--- @field nodesBombsiteA table<string, NodeTypeBase[]>
--- @field nodesBombsiteB table<string, NodeTypeBase[]>
--- @field nodesByClass table<string, NodeTypeBase[]>
--- @field nodesByType table<string, NodeTypeBase[]>
--- @field nodeTypes NodeTypeBase[]
--- @field pathableNodes NodeTypeBase[]
local Nodegraph = {}

--- @return void
function Nodegraph.__setup()
    Nodegraph.initFields()
    Nodegraph.initEvents()

    Logger.console(0, "Nodegraph is ready.")
end

--- @return void
function Nodegraph.initFields()
    Nodegraph.freeIds = {}
    Nodegraph.iNodes = 0
    Nodegraph.nodes = {}
    Nodegraph.nodesByType = {}
    Nodegraph.nodesByClass = {}
    Nodegraph.nodeClassMap = {}
    Nodegraph.nodesBombsiteA = {}
    Nodegraph.nodesBombsiteB = {}
    Nodegraph.pathableNodes = {}
    Nodegraph.isLoaded = false

    --- @type NodeTypeBase[]
    local classes = Node

    --- @param node NodeTypeBase
    for _, node in pairs(classes) do
        Nodegraph.nodesByClass[node.__classname] = {}
        Nodegraph.nodeClassMap[node.__classname] = node

        if node.isLinkedToBombsite then
            Nodegraph.nodesBombsiteA[node.__classname] = {}
            Nodegraph.nodesBombsiteB[node.__classname] = {}
        end

        node:setupCustomizers(MenuGroup)
    end

    --- @param node NodeTypeBase
    for _, node in pairs(NodeType) do
        Nodegraph.nodesByType[node.type] = {}
    end
end

--- @return void
function Nodegraph.initEvents()
    Callbacks.init(function()
        if not Server.isIngame() then
            return
        end

        local filename = Nodegraph.getFilename()

        if not filename then
            return
        end

        Nodegraph.load(filename)
    end)

    Callbacks.frame(function()
        for _, node in pairs(Nodegraph.nodes) do
            node:onThink(Nodegraph)
        end
    end)
end

--- @vararg string
--- @return void
function Nodegraph.log(...)
    local message = string.format(...)

    if not message then
        return
    end

    client.color_log(240, 50, 50, "[Dominion] \0")
    client.color_log(200, 200, 200, message)

    Chat.message(string.format("%s[Dominion]%s %s", Chat.LIGHT_RED, Chat.WHITE, message))
end

--- @return void
function Nodegraph.reset()
    Nodegraph.nodes = {}
    Nodegraph.iNodes = 0
end

--- @param node NodeTypeBase
--- @param isInvokingOnSetup boolean
--- @return void
function Nodegraph.add(node, isInvokingOnSetup)
    local id

    if not Table.isEmpty(Nodegraph.freeIds) then
        id = table.remove(Nodegraph.freeIds)
    else
        id = Nodegraph.iNodes + 1

        Nodegraph.iNodes = id
    end

    node.id = id

    Nodegraph.nodesByClass[node.__classname][id] = node
    Nodegraph.nodesByType[node.type][id] = node
    Nodegraph.nodes[id] = node

    if node.isPathable then
        Nodegraph.pathableNodes[node.id] = node
    end

    node:onCreatePost(Nodegraph)

    if node.isLinkedToBombsite then
        if node.bombsite == "A" then
            table.insert(Nodegraph.nodesBombsiteA[node.__classname], node)
        elseif node.bombsite == "B" then
            table.insert(Nodegraph.nodesBombsiteB[node.__classname], node)
        end
    end

    if not isInvokingOnSetup then
        return
    end

    for _, search in pairs(Nodegraph.nodes) do
        search:onSetup(Nodegraph)
    end
end

--- @param nodes NodeTypeBase[]
--- @param isInvokingOnSetup boolean
--- @return void
function Nodegraph.addMany(nodes, isInvokingOnSetup)
    for _, node in pairs(nodes) do
        Nodegraph.add(node, isInvokingOnSetup)
    end
end

--- @param node NodeTypeBase
--- @return void
function Nodegraph.remove(node)
    Nodegraph.nodesByClass[node.__classname][node.id] = nil
    Nodegraph.nodesByType[node.type][node.id] = nil
    Nodegraph.nodes[node.id] = nil
    Nodegraph.pathableNodes[node.id] = nil

    table.insert(Nodegraph.freeIds, node.id)

    node:onRemove(Nodegraph)
end

--- @param node NodeTypeBase
--- @return boolean
function Nodegraph.isNodeAvailable(node)
    return not Table.isEmpty(Nodegraph.nodesByClass[node.__classname])
end

--- Warning: never directly edit the table this function returns as it returns a field from the graph by reference.
---
--- @generic T
--- @param node T
--- @return T[]
function Nodegraph.get(node)
    return Nodegraph.nodesByClass[node.__classname]
end

--- @generic T
--- @param id number
--- @param inferType T
--- @return T|NodeTypeBase
function Nodegraph.getById(id, inferType)
    return Nodegraph.nodes[id]
end

--- @generic T
--- @param node T
--- @return T|nil
function Nodegraph.getOne(node)
    local nodes = Nodegraph.get(node)

    if not nodes then
        return nil
    end

    return select(2, next(nodes))
end

--- Warning: never directly edit the table this function returns as it returns a field from the graph by reference.
---
--- @generic T
--- @param node T
--- @return T[]
function Nodegraph.getOfType(node)
    return Nodegraph.nodesByType[node.type] or {}
end

--- @param bombsite string
--- @return NodeTypeObjective
function Nodegraph.getBombsite(bombsite)
    bombsite = bombsite:upper()

    if bombsite == "A" then
        return Nodegraph.getOne(Node.objectiveBombsiteA)
    elseif bombsite == "B" then
        return Nodegraph.getOne(Node.objectiveBombsiteB)
    end
end

--- @param spawn string
--- @return NodeTypeObjective
function Nodegraph.getSpawn(spawn)
    spawn = spawn:upper()

    if spawn == "T" then
        return Nodegraph.getOne(Node.objectiveTSpawn)
    elseif spawn == "C" then
        return Nodegraph.getOne(Node.objectiveCtSpawn)
    end
end

--- @param origin Vector3
--- @return NodeTypeObjective
function Nodegraph.getClosestBombsite(origin)
    --- @type NodeTypeObjective[]
    local bombsites = {
        Nodegraph.getOne(Node.objectiveBombsiteA),
        Nodegraph.getOne(Node.objectiveBombsiteB),
    }

    --- @type NodeTypeObjective
    local closestBombsite
    local closestDistance = math.huge

    for _, bombsite in pairs(bombsites) do
        local distance = origin:getDistance(bombsite.origin)

        if distance < closestDistance then
            closestDistance = distance
            closestBombsite = bombsite
        end
    end

    return closestBombsite
end

--- @param origin Vector3
--- @return string
function Nodegraph.getClosestBombsiteName(origin)
    local bombsite = Nodegraph.getClosestBombsite(origin)

    return bombsite.bombsite
end

--- @generic T
--- @param node T
--- @param bombsite string
--- @return T[]
function Nodegraph.getForBombsite(node, bombsite)
    bombsite = bombsite:upper()

    if bombsite == "A" then
        return Nodegraph.nodesBombsiteA[node.__classname]
    elseif bombsite == "B" then
        return Nodegraph.nodesBombsiteB[node.__classname]
    end
end

--- @generic T
--- @param node T
--- @param bombsite string
--- @return T[]
function Nodegraph.getForBombsiteOfType(node, bombsite)
    -- todo
    local nodes = Nodegraph.getOfType(node)

    if not nodes then
        return nil
    end

    bombsite = bombsite:upper()

    --- @type NodeTypeBase[]
    local result = {}

    for _, search in pairs(nodes) do
        if search.bombsite == bombsite then
            table.insert(result, search)
        end
    end

    return result
end

--- @generic T
--- @param node T
--- @param bombsite string
--- @return T
function Nodegraph.getRandomForBombsite(node, bombsite)
    if type(bombsite) ~= "string" then
        error("no bombsite", 2)
    end
    return Table.getRandom(Nodegraph.getForBombsite(node, bombsite:upper()))
end

--- @generic T
--- @param node T
--- @param bombsite string
--- @return T
function Nodegraph.getRandomForBombsiteOfType(node, bombsite)
    return Table.getRandom(Nodegraph.getForBombsite(Nodegraph.nodesByType[node.type], bombsite:upper()))
end

--- @generic T
--- @param node T
--- @param origin Vector3
--- @field radius number
--- @return T
function Nodegraph.getVisible(node, origin, radius)
    --- @type NodeTypeBase[]
    local filter = {}

    if node then
        if not Nodegraph.nodesByClass[node.__classname] then
            return nil
        end

        filter = Nodegraph.nodesByClass[node.__classname]
    else
        filter = Nodegraph.nodes
    end

    radius = radius or math.huge

    --- @type NodeTypeBase[]
    local nodes = {}
    local iNodes = 0

    for _, search in pairs(filter) do
        if node and node.id and node.id == search.id then
            break
        end

        local distance = origin:getDistance(search.origin)

        if distance < radius then
            local trace = Trace.getLineToPosition(origin, search.origin, AiUtility.traceOptionsAttacking)

            if not trace.isIntersectingGeometry then
                iNodes = iNodes + 1
                nodes[iNodes] = search
            end
        end
    end

    return nodes
end

--- @generic T
--- @param node T
--- @param origin Vector3
--- @param radius number
--- @return T
function Nodegraph.getVisibleOfType(node, origin, radius)
    if not Nodegraph.nodesByType[node.type] then
        return {}
    end

    radius = radius or math.huge

    --- @type NodeTypeBase[]
    local nodes = {}
    local iNodes = 0

    for _, search in pairs(Nodegraph.nodesByType[node.type]) do
        if node.id and node.id == search.id then
            break
        end

        local distance = origin:getDistance(search.origin)

        if distance < radius then
            local trace = Trace.getLineToPosition(origin, search.origin, AiUtility.traceOptionsAttacking)

            if not trace.isIntersectingGeometry then
                iNodes = iNodes + 1
                nodes[iNodes] = search
            end
        end
    end

    return nodes
end

--- @generic T
--- @param origin Vector3
--- @param node T
--- @return T, number
function Nodegraph.getClosest(origin, node)
    --- @type NodeTypeBase[]
    local filter = {}

    if node then
        if not Nodegraph.nodesByClass[node.__classname] then
            return nil
        end

        filter = Nodegraph.nodesByClass[node.__classname]
    else
        filter = Nodegraph.nodes
    end

    --- @type NodeTypeBase
    local closest
    local closestDistance = math.huge

    for _, search in pairs(filter) do repeat
        if node and node.id and node.id == search.id then
            break
        end

        local distance = origin:getDistance(search.origin)

        if distance < closestDistance then
            closestDistance = distance
            closest = search
        end
    until true end

    return closest, closestDistance
end

--- @generic T
--- @param node T
--- @param origin Vector3
--- @return T, number
function Nodegraph.getClosestOfType(origin, node)
    if not Nodegraph.nodesByType[node.type] then
        return nil
    end

    --- @type NodeTypeBase
    local closest
    local closestDistance = math.huge

    for _, search in pairs(Nodegraph.nodesByType[node.type]) do
        if node.id and node.id == search.id then
            break
        end

        local distance = origin:getDistance(search.origin)

        if distance < closestDistance then
            closestDistance = distance
            closest = search
        end
    end

    return closest, closestDistance
end

--- @generic T
--- @param origin Vector3
--- @param radius number
--- @param node T
--- @return NodeTypeBase[]|T[]
function Nodegraph.getWithin(origin, radius, node)
    --- @type NodeTypeBase[]
    local filter = {}

    if node then
        if not Nodegraph.nodesByClass[node.__classname] then
            return nil
        end

        filter = Nodegraph.nodesByClass[node.__classname]
    else
        filter = Nodegraph.nodes
    end

    --- @type NodeTypeBase[]
    local result = {}

    for _, search in pairs(filter) do repeat
        if node and node.id and node.id == search.id then
            break
        end

        if origin:getDistance(search.origin) < radius then
            table.insert(result, search)
        end
    until true end

    return result
end

--- @generic T
--- @param node T
--- @param radius number
--- @param origin Vector3
--- @return T[]
function Nodegraph.getWithinOfType(origin, radius, node)
    if not Nodegraph.nodesByType[node.type] then
        return nil
    end

    --- @type NodeTypeBase[]
    local result = {}

    for _, search in pairs(Nodegraph.nodesByType[node.type]) do
        if node.id and node.id == search.id then
            break
        end

        if origin:getDistance(search.origin) < radius then
            table.insert(result, search)
        end
    end

    return result
end

--- @generic T
--- @param node T
--- @param origin Vector3
--- @param radius number
--- @return T
function Nodegraph.getRandom(node, origin, radius)
    radius = radius or Vector3.MAX_DISTANCE

    --- @type NodeTypeBase[]
    local filter = {}

    if not Nodegraph.nodesByClass[node.__classname] then
        return nil
    end

    filter = Nodegraph.nodesByClass[node.__classname]

    --- @type NodeTypeBase[]
    local nodes = {}

    for _, search in pairs(filter) do
        if not origin or origin:getDistance(search.origin) < radius then
            table.insert(nodes, search)
        end
    end

    if Table.isEmpty(nodes) then
        return nil
    end

    return Table.getRandom(nodes)
end

--- @generic T
--- @param node T
--- @param origin Vector3
--- @param radius number
--- @return T
function Nodegraph.getRandomOfType(node, origin, radius)
    radius = radius or Vector3.MAX_DISTANCE

    if not Nodegraph.nodesByType[node.type] then
        return nil
    end

    --- @type NodeTypeBase[]
    local nodes = {}
    local iNodes = 0

    for _, search in pairs(Nodegraph.nodesByType[node.type]) do
        if node.id and node.id == search.id then
            break
        end

        if not origin or origin:getDistance(search.origin) < radius then
            iNodes = iNodes + 1
            nodes[iNodes] = search
        end
    end

    if iNodes > 0 then
        return Table.getRandom(nodes)
    else
        return nil
    end
end

--- @param node NodeTypeBase
--- @return void
function Nodegraph.clear(node)
    if not Nodegraph.nodesByClass[node.__classname] then
        return
    end

    for _, search in pairs(Nodegraph.nodesByClass[node.__classname]) do
        Nodegraph.remove(search)
    end
end

--- @param node NodeTypeBase
--- @return void
function Nodegraph.clearType(node)
    if not Nodegraph.nodesByType[node.type] then
        return
    end

    for _, search in pairs(Nodegraph.nodesByType[node.type]) do
        Nodegraph.remove(search)
    end
end

--- @return void
function Nodegraph.reactivateAllNodes()
    for _, node in pairs(Nodegraph.nodes) do
        node:activate()
    end
end

--- @return string
function Nodegraph.getFilename()
    return string.format("lua/gamesense/Nyx/v1/Dominion/Traversal/Nodegraphs/%s.json", Server.getMapName())
end

--- @return void
function Nodegraph.create()
    Nodegraph.initFields()
end

--- @param filename string
--- @return void
function Nodegraph.load(filename)
    local filedata = readfile(filename)

    if not filedata then
        Logger.message(1, "Cannot load graph from '%s'. File does not exist.", filename)

        return
    end

    --- @type NodegraphDataSerialized
    local data = json.parse(filedata)

    --- @type NodeTypeBase[]
    local nodes = {}

    for _, datum in pairs(data.nodes) do
        --- @type NodeTypeBase
        local node = {}

        node.id = datum.id
        node.origin = Vector3:newFromTable(datum.origin)

        -- We cannot call Nyx.new before declaring the node's origin as __init expects the origin to exist.
        -- Connections is set to {} in __init, so the expression must remain here.
        -- This could technically be a bug, but deserialization isn't covered under the Nyx API.
        node = Nyx.new(Nodegraph.nodeClassMap[datum.__classname], node)

        node.connections = datum.connections

        if node.isDirectional then
            node.direction = Angle:newFromTable(datum.direction)
        end

        if node.customizers then
            for _, field in pairs(node.customizers) do
                node[field] = datum[field]
            end
        end

        if datum.userdata then
            node.userdata = datum.userdata
        end

        nodes[node.id] = node
    end

    for _, node in pairs(nodes) do
        local connections = {}

        for _, connection in pairs(node.connections) do
            connections[connection] = nodes[connection]
        end

        node.connections = connections

        Nodegraph.nodesByClass[node.__classname][node.id] = node
        Nodegraph.nodesByType[node.type][node.id] = node

        if node.isLinkedToBombsite then
            if node.bombsite == "A" then
                table.insert(Nodegraph.nodesBombsiteA[node.__classname], node)
            elseif node.bombsite == "B" then
                table.insert(Nodegraph.nodesBombsiteB[node.__classname], node)
            end
        end

        if node.isPathable then
            Nodegraph.pathableNodes[node.id] = node
        end
    end

    Nodegraph.freeIds = {}

    for i = 1, data.iNodes do
        if not nodes[i] then
            table.insert(Nodegraph.freeIds, i)
        end
    end

    Nodegraph.nodes = nodes
    Nodegraph.iNodes = data.iNodes

    -- Must be done last.
    for _, node in pairs(nodes) do
        if node.userdata then
            node:deserialize(Nodegraph, node.userdata)

            node.userdata = nil
        end

        node:onSetup(Nodegraph)
    end

    Nodegraph.isLoaded = true

    Logger.console(0, "Loaded nodegraph from '%s'.", filename)
end

--- @param filename string
--- @return void
function Nodegraph.save(filename)
    --- @type NodegraphDataSerialized
    local data = {
        nodes = {},
        iNodes = Nodegraph.iNodes
    }

    local iDataNodes = 0

    for _, node in pairs(Nodegraph.nodes) do repeat
        if node.isTransient then
            break
        end

        --- @type NodeTypeBase
        local datum = {}

        datum.__classname = node.__classname
        datum.id = node.id
        datum.connections = {}

        local iConnections = 0

        for _, connection in pairs(node.connections) do
            iConnections = iConnections + 1

            datum.connections[iConnections] = connection.id
        end

        datum.origin = node.origin:round(0):__serialize()

        if node.isDirectional then
            datum.direction = node.direction:round(0):__serialize()
        end

        if node.customizers then
            for _, field in pairs(node.customizers) do
                datum[field] = node[field]
            end
        end

        local serialized = node:serialize()

        if serialized then
            local userdata = {}

            for field, value in pairs(serialized) do
                userdata[field] = value
            end

            datum.userdata = userdata
        end

        iDataNodes = iDataNodes + 1
        data.nodes[iDataNodes] = datum
    until true end

    writefile(filename, json.stringify(data))

    Logger.message(0, "Saved nodegraph to '%s'.", filename)
end

return Nyx.class("Nodegraph", Nodegraph)
--}}}
