--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
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
--- @field deactivate fun(self: AiStateBase): void
--- @field delayedMouseMax number
--- @field delayedMouseMin number
--- @field isBlocked boolean
--- @field isCurrentState boolean
--- @field isQueuedForReactivation boolean
--- @field name string
--- @field priority number
--- @field priorityMap string[]
--- @field requiredGamemodes string[]
--- @field requiredNodes NodeTypeBase[]
--- @field think fun(self: AiStateBase, cmd: SetupCommandEvent): void
--- @field abuseLockTimer Timer
local AiStateBase = {
    priorityMap = Table.getInverted(AiPriority),
    delayedMouseMin = 0.25,
    delayedMouseMax = 0.55
}

--- @param fields AiStateBase
--- @return AiStateBase
function AiStateBase:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateBase:__setup()
    self.abuseLockTimer = Timer:new()
end

--- @return string
function AiStateBase:getError()
    if self.requiredNodes then
        local isNodeAvailable = true
        local unavailableNodes = {}

        for _, node in pairs(self.requiredNodes) do
            if not Nodegraph.isNodeAvailable(node) then
                isNodeAvailable = false

                table.insert(unavailableNodes, node.name)
            end
        end

        if not isNodeAvailable then
            return string.format(
                "The following nodes are required on the map: '%s'",
                Table.getImploded(unavailableNodes, ", ")
            )
        end
    end

    if self.requiredGamemodes then
        local isValidGamemode = false

        for _, gamemode in pairs(self.requiredGamemodes) do
            if AiUtility.gamemode == gamemode then
                isValidGamemode = true

                break
            end
        end

        if not isValidGamemode then
            return string.format(
                "The following gamemodes are required: '%s'",
                Table.getImploded(self.requiredGamemodes, ", ")
            )
        end
    end

    return nil
end

--- @return void
function AiStateBase:block()
    self.isBlocked = true
end

--- @return void
function AiStateBase:queueForReactivation()
    self.isQueuedForReactivation = true
end

--- @param range number
--- @param target Player
--- @return Node
function AiStateBase:getCoverNode(range, target)
    local clientOrigin = LocalPlayer:getOrigin()
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
