--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateAvoidOccluders
--- @class AiStateAvoidOccluders : AiStateBase
--- @field inferno Entity
--- @field isInsideInferno boolean
local AiStateAvoidOccluders = {
    name = "Avoid Infernos",
    isLockable = false
}

--- @param fields AiStateAvoidOccluders
--- @return AiStateAvoidOccluders
function AiStateAvoidOccluders:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateAvoidOccluders:__init() end

--- @return void
function AiStateAvoidOccluders:assess()
    if self.ai.routines.handleOccluderTraversal.infernoInsideOf then
        return AiPriority.AVOID_INFERNO
    end

    if self.ai.routines.handleOccluderTraversal.smokeInsideOf then
        return AiPriority.AVOID_SMOKE
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateAvoidOccluders:activate()
    -- Nodes won't have always updated on this this tick.
    Client.onNextTick(function()
        if self.ai.routines.handleOccluderTraversal.infernoInsideOf then
            self:moveOutOfInferno()
        elseif self.ai.routines.handleOccluderTraversal.smokeInsideOf then
            self:moveOutOfSmoke()
        end
    end)
end

--- @return void
function AiStateAvoidOccluders:deactivate() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateAvoidOccluders:think(cmd)
    self.activity = "Avoiding occluder"

    -- Don't permit walking if we're in a fire.
    if self.ai.routines.handleOccluderTraversal.infernoInsideOf then
        self.ai.routines.walk:block()
    end
end

--- @return void
function AiStateAvoidOccluders:moveOutOfInferno()
    local clientOrigin = LocalPlayer:getOrigin()

    --- @type NodeTypeTraverse
    local targetNode
    local closestDistance = math.huge

    for _, node in pairs(Nodegraph.get(Node.traverseGeneric)) do repeat
        if node.isOccludedByInferno then
            break
        end

        local distance = clientOrigin:getDistance(node.floorOrigin)

        if distance < closestDistance then
            closestDistance = distance
            targetNode = node
        end
    until true end

    Pathfinder.moveToNode(targetNode, {
        task = "Get out of inferno",
        isAllowedToTraverseInactives = true,
        isPathfindingFromNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true,
    })
end

--- @return void
function AiStateAvoidOccluders:moveOutOfSmoke()
    local clientOrigin = LocalPlayer:getOrigin()

    --- @type NodeTypeTraverse
    local targetNode
    local closestDistance = math.huge

    for _, node in pairs(Nodegraph.get(Node.traverseGeneric)) do repeat
        if node.isOccludedBySmoke then
            break
        end

        local distance = clientOrigin:getDistance(node.floorOrigin)

        if distance < closestDistance then
            closestDistance = distance
            targetNode = node
        end
    until true end

    Pathfinder.moveToNode(targetNode, {
        task = "Get out of smoke",
        isAllowedToTraverseInactives = true,
        isPathfindingFromNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true,
    })
end

return Nyx.class("AiStateAvoidOccluders", AiStateAvoidOccluders, AiStateBase)
--}}}
