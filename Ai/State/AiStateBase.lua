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
local AiThreats = require "gamesense/Nyx/v1/Dominion/Ai/AiThreats"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
--}}}

--{{{ AiStateBase
--- @class AiStateBase : Class
--- @field abuseLockTimer Timer
--- @field activate fun(self: AiStateBase): void
--- @field activity string
--- @field ai Ai
--- @field getAssessment fun(self: AiStateBase): number
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
    if self.requiredGamemodes and AiUtility.mapInfo then
        local isValidGamemode = false

        for _, gamemode in pairs(self.requiredGamemodes) do
            if AiUtility.mapInfo.gamemode == gamemode then
                isValidGamemode = true

                break
            end
        end

        if not isValidGamemode then
            return string.format(
                Localization.aiStateGamemodesRequired,
                Table.getStringFromTableWithDelimiter(self.requiredGamemodes, ", ")
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
                Table.getStringFromTableWithDelimiter(unavailableNodes, ", ")
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
--- @return NodeTypeTraverse
function AiStateBase:getCoverNode(range, target, fov)
    --- @type Angle
    local coverAngle
    local clientOrigin = LocalPlayer:getOrigin()

    if target then
        coverAngle = clientOrigin:getAngle(target:getOrigin())
    else
        coverAngle = LocalPlayer.getCameraAngles()
    end

    local nodes = Nodegraph.find(Node.traverseGeneric, function(node)
        if AiThreats.threatVisgraph[node.id] then
            return false
        end

        if clientOrigin:getDistance(node.floorOrigin) > range then
            return false
        end

        if coverAngle:getFov(clientOrigin, node.floorOrigin) > fov then
            return false
        end

        return true
    end)

    return Table.getRandom(nodes)
end

return Nyx.class("AiStateBase", AiStateBase)
--}}}
