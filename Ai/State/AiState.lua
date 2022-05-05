--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiState
--- @class AiState : Class
--- @field activate fun(self: AiState): void
--- @field activity string
--- @field ai AiController
--- @field assess fun(self: AiState): number
--- @field lastPriority number
--- @field name string
--- @field priority AiPriority
--- @field priorityMap string[]
--- @field think fun(self: AiState, cmd: SetupCommandEvent): void
local AiState = {
    priorityMap = Table.getInverted(AiPriority)
}

--- @param fields AiState
--- @return AiState
function AiState:new(fields)
    return Nyx.new(self, fields)
end

--- @param range number
--- @param target Player
--- @return Node
function AiState:getCoverNode(range, target)
    local player = AiUtility.client
    local playerOrigin = player:getOrigin()
    local coverAngle

    if target then
        coverAngle = -(playerOrigin:getAngle(target:getOrigin()))
    else
        coverAngle = -(Client.getCameraAngles())
    end

    --- @type Node[]
    local possibleNodes = {}
    local i = 0

    for _, node in pairs(self.ai.nodegraph.nodes) do
        if playerOrigin:getDistance(node.origin) < range and coverAngle:getFov(playerOrigin, node.origin) < 90 then
            i = i + 1

            if i > 50 then
                break
            end

            local isVisibleToEnemy = false

            for _, enemy in pairs(AiUtility.enemies) do
                local enemyPos = enemy:getOrigin():offset(0, 0, 64)
                local trace = Trace.getLineToPosition(enemyPos, node.origin, AiUtility.traceOptionsAttacking, "AiState.getCoverNode<FindNodeVisibleToEnemy>")

                if not trace.isIntersectingGeometry then
                    isVisibleToEnemy = true

                    break
                end
            end

            if not isVisibleToEnemy then
                table.insert(possibleNodes, node)
            end
        end
    end

    if not next(possibleNodes) then
        -- If we ever reach this, we've graphed the map badly, or the AI is literally surrounded.
        self.ai.nodegraph:log("No cover to move to")

        return nil
    end

    --- @type Node
    local farthestNode
    local farthestDistance = -1
    local closestOrigin

    if AiUtility.closestEnemy then
        closestOrigin = AiUtility.closestEnemy:getOrigin()
    else
        closestOrigin = playerOrigin
    end

    for _, node in pairs(possibleNodes) do
        local distance = closestOrigin:getDistance(node.origin)

        if distance > farthestDistance then
            farthestDistance = distance
            farthestNode = node
        end
    end

    return farthestNode
end

return Nyx.class("AiState", AiState)
--}}}
