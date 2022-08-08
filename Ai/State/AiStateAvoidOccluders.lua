--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
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
    self:move()
end

--- @return void
function AiStateAvoidOccluders:deactivate() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateAvoidOccluders:think(cmd)
    self.activity = "Avoiding occluder"

    if Pathfinder.isIdle() then
        self:move()
    end
end

--- @return void
function AiStateAvoidOccluders:move()
    local clientOrigin = LocalPlayer:getOrigin()
    local testOrigin

    if AiUtility.closestEnemy then
        testOrigin = AiUtility.closestEnemy:getOrigin()
    else
        testOrigin = clientOrigin + LocalPlayer.getCameraAngles():getForward() * 100
    end

    if not testOrigin then
        self:moveToRandom()

        return
    end

    local origin

    if self.ai.routines.handleOccluderTraversal.infernoInsideOf then
        origin = self.ai.routines.handleOccluderTraversal.infernoInsideOf:m_vecOrigin()
    elseif self.ai.routines.handleOccluderTraversal.smokeInsideOf then
        origin = self.ai.routines.handleOccluderTraversal.smokeInsideOf:m_vecOrigin()
    end

    local clientDistance = clientOrigin:getDistance(testOrigin)
    local occluderDistance = origin:getDistance(testOrigin)
    --- @type NodeTraverseGeneric
    local node

    if clientDistance < occluderDistance then
        local angleToTest = clientOrigin:getAngle(testOrigin)

        node = Nodegraph.findOne(Node.traverseGeneric, function(n)
        	local fov = angleToTest:getFov(clientOrigin, n.origin)

            if fov < 80 then
                return n
            end
        end)
    else
        local angleAway = clientOrigin:getAngle(testOrigin):zeroPitch():getInversed()

        node = Nodegraph.findOne(Node.traverseGeneric, function(n)
            local fov = angleAway:getFov(clientOrigin, n.origin)

            if fov < 80 then
                return n
            end
        end)
    end

    if not node then
        self:moveToRandom()

        return
    end

    Pathfinder.moveToNode(node, {
        task = "Get out of inferno",
        isAllowedToTraverseInfernos = true,
        isAllowedToTraverseInactives = true,
        isPathfindingFromNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true,
    })
end

--- @return void
function AiStateAvoidOccluders:moveToRandom()
    local origin

    if self.ai.routines.handleOccluderTraversal.infernoInsideOf then
        origin = self.ai.routines.handleOccluderTraversal.infernoInsideOf:m_vecOrigin()
    elseif self.ai.routines.handleOccluderTraversal.smokeInsideOf then
        origin = self.ai.routines.handleOccluderTraversal.smokeInsideOf:m_vecOrigin()
    end

    local clientOrigin = LocalPlayer:getOrigin()

    Pathfinder.moveToNode(Nodegraph.findRandom(Node.traverseGeneric, function(n)
        local distanceToClient = clientOrigin:getDistance(n.origin)
        local distanceToOccluder = origin:getDistance(n.origin)

        return distanceToClient > 400 and distanceToClient < distanceToOccluder
    end), {
        task = "Get out of inferno (random node)",
        isAllowedToTraverseInfernos = true,
        isAllowedToTraverseInactives = true,
        isPathfindingFromNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true,
    })
end

return Nyx.class("AiStateAvoidOccluders", AiStateAvoidOccluders, AiStateBase)
--}}}
