--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local NodeType = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeType"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
--}}}

--{{{ AiStateBase
--- @class AiStateBase : Class
--- @field activate fun(self: AiStateBase): void
--- @field activity string
--- @field ai AiController
--- @field assess fun(self: AiStateBase): number
--- @field delayedMouseMax number
--- @field delayedMouseMin number
--- @field isBlocked boolean
--- @field lastPriority number
--- @field name string
--- @field priority AiPriority
--- @field priorityMap string[]
--- @field requiredNodes NodeTypeBase[]
--- @field think fun(self: AiStateBase, cmd: SetupCommandEvent): void
local AiStateBase = {
    priorityMap = Table.getInverted(AiPriority),
    delayedMouseMin = 0.33,
    delayedMouseMax = 0.66
}

--- @param fields AiStateBase
--- @return AiStateBase
function AiStateBase:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateBase:block()
    self.isBlocked = true
end

--- @param range number
--- @param target Player
--- @return Node
function AiStateBase:getCoverNode(range, target)
    local player = AiUtility.client
    local clientOrigin = player:getOrigin()
    --- @type Angle
    local coverAngle

    if target then
        coverAngle = clientOrigin:getAngle(target:getOrigin())
    else
        coverAngle = Client.getCameraAngles()
    end

    --- @type Vector3[]
    local enemyEyeOrigins = {}

    for _, enemy in pairs(AiUtility.enemies) do
        table.insert(enemyEyeOrigins, enemy:getOrigin():offset(0, 0, 64))
    end

    --- @type NodeTypeTraverse
    local farthestNode
    local farthestDistance = -1
    local closestOrigin
    local i = 0

    if AiUtility.closestEnemy then
        closestOrigin = AiUtility.closestEnemy:getOrigin()
    else
        closestOrigin = clientOrigin
    end

    for _, node in pairs(Nodegraph.getOfType(NodeType.traverse)) do
        local distance = closestOrigin:getDistance(node.origin)

        if distance > farthestDistance and clientOrigin:getDistance(node.origin) < range and coverAngle:getFov(clientOrigin, node.origin) > 75 then
            i = i + 1

            if i > 50 then
                break
            end

            farthestDistance = distance
            farthestNode = node

            local isVisibleToEnemy = false

            for _, eyeOrigin in pairs(enemyEyeOrigins) do
                local trace = Trace.getLineToPosition(eyeOrigin, node.origin, AiUtility.traceOptionsAttacking, "AiStateBase.getCoverNode<FindNodeVisibleToEnemy>")

                if not trace.isIntersectingGeometry then
                    isVisibleToEnemy = true

                    break
                end
            end

            if not isVisibleToEnemy then
                farthestNode = node
            end
        end
    end

    return farthestNode
end

return Nyx.class("AiStateBase", AiStateBase)
--}}}
