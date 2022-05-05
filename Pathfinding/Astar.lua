--{{{ Dependencies
--}}}

--{{{ Astar
local AStar = {}

local cachedPaths

local function isValidNode(node, neighbour)
    return true
end

local function getLowestFScore(set, f_score)
    local lowest, bestNode = math.huge, nil
    for _, node in pairs(set) do
        local score = f_score[node]
        if score < lowest then
            lowest, bestNode = score, node
        end
    end
    return bestNode
end

local function getNeighborNodes(theNode, nodes)
    local neighbors = {}
    for _, node in pairs(nodes) do
        if theNode ~= node and isValidNode(theNode, node) then
            table.insert(neighbors, node)
        end
    end
    return neighbors
end

local function isNotIn(set, theNode)
    for _, node in pairs(set) do
        if node == theNode then
            return false
        end
    end
    return true
end

local function removeNode(set, theNode)
    for i, node in pairs(set) do
        if node == theNode then
            set[i] = set[#set]
            set[#set] = nil
            break
        end
    end
end

local function unwindPath(flat_path, map, current_node)
    if map[current_node] then
        table.insert(flat_path, 1, map[current_node])
        return unwindPath(flat_path, map, map[current_node])
    else
        return flat_path
    end
end

local function getPath(start, goal, nodes, valid_node_func)
    local closedset = {}
    local openset = { start }
    local cameFrom = {}

    if valid_node_func then
        isValidNode = valid_node_func
    end

    local gScore, fScore = {}, {}

    gScore[start] = 0
    fScore[start] = gScore[start] + start.origin:getDistance(goal.origin)

    while #openset > 0 do
        local current = getLowestFScore(openset, fScore)

        if current == goal then
            local path = unwindPath({}, cameFrom, goal)

            table.insert(path, goal)

            return path
        end

        removeNode(openset, current)

        table.insert(closedset, current)

        local neighbors = getNeighborNodes(current, nodes)

        for _, neighbor in pairs(neighbors) do
            if isNotIn(closedset, neighbor) then
                local tentativeGScore = gScore[current] + current.origin:getDistance(neighbor.origin)

                if isNotIn(openset, neighbor) or tentativeGScore < gScore[neighbor] then
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeGScore
                    fScore[neighbor] = gScore[neighbor] + neighbor.origin:getDistance(goal.origin)

                    if isNotIn(openset, neighbor) then
                        table.insert(openset, neighbor)
                    end
                end
            end
        end
    end

    return nil
end

--- @param start Node
--- @param goal Node
--- @param nodes Node[]
--- @param ignoreCache boolean
--- @param validNodeFunc fun(node: Node, neighbour: Node): boolean
--- @return Node[]
function AStar.find(start, goal, nodes, ignoreCache, validNodeFunc)
    if nodes then
        if not cachedPaths then
            cachedPaths = {}
        end

        if not cachedPaths[start] then
            cachedPaths[start] = {}
        elseif cachedPaths[start][goal] and not ignoreCache then
            return cachedPaths[start][goal]
        end

        local resPath = getPath(start, goal, nodes, validNodeFunc)
        if not cachedPaths[start][goal] and not ignoreCache then
            cachedPaths[start][goal] = resPath
        end

        return resPath
    end
    return nil
end

return AStar
--}}}
