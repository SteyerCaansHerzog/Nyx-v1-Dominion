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

--{{{ AiStateAvoidInfernos
--- @class AiStateAvoidInfernos : AiStateBase
--- @field inferno Entity
--- @field isInsideInferno boolean
local AiStateAvoidInfernos = {
    name = "Avoid Infernos",
    isLockable = false
}

--- @param fields AiStateAvoidInfernos
--- @return AiStateAvoidInfernos
function AiStateAvoidInfernos:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateAvoidInfernos:__init() end

--- @return void
function AiStateAvoidInfernos:assess()
    if self.ai.routines.handleOccluderTraversal.infernoInsideOf then
        return AiPriority.AVOID_INFERNO
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateAvoidInfernos:activate()
    self:move()
end

--- @return void
function AiStateAvoidInfernos:deactivate() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateAvoidInfernos:think(cmd)
    self.activity = "Avoiding inferno"

    if Pathfinder.isIdle() then
        self:move()
    end
end

--- @return void
function AiStateAvoidInfernos:move()
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

    local infernoOrigin = self.ai.routines.handleOccluderTraversal.infernoInsideOf:m_vecOrigin()
    local clientDistance = clientOrigin:getDistance(testOrigin)
    local infernoDistance = infernoOrigin:getDistance(testOrigin)
    --- @type NodeTraverseGeneric
    local node

    if clientDistance < infernoDistance then
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
function AiStateAvoidInfernos:moveToRandom()
    local infernoOrigin = self.ai.routines.handleOccluderTraversal.infernoInsideOf:m_vecOrigin()
    local clientOrigin = LocalPlayer:getOrigin()

    Pathfinder.moveToNode(Nodegraph.findRandom(Node.traverseGeneric, function(n)
        local distanceToClient = clientOrigin:getDistance(n.origin)
        local distanceToInferno = infernoOrigin:getDistance(n.origin)

        return distanceToClient > 400 and distanceToClient < distanceToInferno
    end), {
        task = "Get out of inferno (random node)",
        isAllowedToTraverseInfernos = true,
        isAllowedToTraverseInactives = true,
        isPathfindingFromNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true,
    })
end

return Nyx.class("AiStateAvoidInfernos", AiStateAvoidInfernos, AiStateBase)
--}}}
