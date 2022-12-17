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
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local NodeType = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeType"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
--}}}

--{{{ AiStateBase
--- @class AiStateBase : Class
--- @field abuseLockTimer Timer
--- @field activate fun(self: AiStateBase): void
--- @field activity string
--- @field ai Ai
--- @field assess fun(self: AiStateBase): number
--- @field deactivate fun(self: AiStateBase): void
--- @field delayedMouseMax number
--- @field delayedMouseMin number
--- @field isBlocked boolean
--- @field isCurrentState boolean
--- @field isEnabled boolean
--- @field isLockable boolean
--- @field isMouseDelayAllowed boolean
--- @field isQueuedForReactivation boolean
--- @field name string
--- @field priority number
--- @field priorityMap string[]
--- @field requiredGamemodes string[]
--- @field requiredNodes NodeTypeBase[]
--- @field reset fun(self: AiStateBase): void
--- @field think fun(self: AiStateBase, cmd: SetupCommandEvent): void
local AiStateBase = {
    priorityMap = Table.getInverted(AiPriority),
    delayedMouseMin = 0.1,
    delayedMouseMax = 0.3,
    isEnabled = false,
    isLockable = true,
    isMouseDelayAllowed = true,
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
                Localization.aiStateGamemodesRequired,
                Table.getImplodedTable(self.requiredGamemodes, ", ")
            )
        end
    end

    if self.requiredNodes then
        local unavailableNodes = {}
        local totalRequiredNodes  = #self.requiredNodes

        for _, node in pairs(self.requiredNodes) do
            if not Nodegraph.isNodeAvailable(node) then
                table.insert(unavailableNodes, node.name)
            end
        end

        if #unavailableNodes == totalRequiredNodes then
            return string.format(
                Localization.aiStateNodesRequired,
                Table.getImplodedTable(unavailableNodes, ", ")
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
--- @return NodeTypeBase
function AiStateBase:getCoverNode(range, target)
    local clientOrigin = LocalPlayer:getOrigin()
    --- @type Angle
    local coverAngle

    if target then
        coverAngle = clientOrigin:getAngle(target:getOrigin())
    else
        coverAngle = LocalPlayer.getCameraAngles()
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

    if AiUtility.closestThreat then
        closestOrigin = AiUtility.closestThreat:getOrigin()
    elseif AiUtility.closestEnemy then
        closestOrigin = AiUtility.closestEnemy:getOrigin()
    else
        closestOrigin = clientOrigin
    end

    for _, node in pairs(Nodegraph.getOfType(NodeType.traverse)) do
        local distance = closestOrigin:getDistance(node.origin)

        if not node.isOccludedByInferno and distance > farthestDistance and clientOrigin:getDistance(node.origin) < range and coverAngle:getFov(clientOrigin, node.origin) > 60 then
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
