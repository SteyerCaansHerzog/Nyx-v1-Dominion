--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
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

--{{{ AiStateTrafficControl
--- @class AiStateTrafficControl : AiStateBase
--- @field trafficControlNode NodeHintTrafficControl
--- @field trafficQueueNode NodeSpotTrafficQueue
--- @field isWaiting boolean
local AiStateTrafficControl = {
    name = "Traffic Control",
    requiredNodes = {
        Node.hintTrafficControl,
        Node.spotTrafficQueue
    }
}

--- @param fields AiStateTrafficControl
--- @return AiStateTrafficControl
function AiStateTrafficControl:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateTrafficControl:__init() end

--- @return void
function AiStateTrafficControl:assess()
    if self.isWaiting then
        return AiPriority.TRAFFIC_CONTROL
    end

    -- No path to assess.
    if not Pathfinder.isOnValidPath() then
        return AiPriority.IGNORE
    end

    --- @type NodeHintTrafficControl
    local trafficControl
    local clientOrigin = LocalPlayer:getOrigin()

    -- Find a traffic control node.
    for _, node in pairs(Nodegraph.get(Node.hintTrafficControl)) do
        if clientOrigin:getDistance(node.origin) < node.queueLinkRadius then
            trafficControl = node

            break
        end
    end

    -- Not inside traffic control zone (or none in the map).
    if not trafficControl then
        return AiPriority.IGNORE
    end

    -- Our path is not within the traffic control zone.
    if not trafficControl.traversalNodes[Pathfinder.path.node.id] then
        return AiPriority.IGNORE
    end

    -- No teammates in the zone.
    if not self:isOccupied(trafficControl) then
        return AiPriority.IGNORE
    end

    --- @type NodeSpotTrafficQueue
    local closestQueueNode
    local closestDistance = math.huge

    -- Find closest queue node.
    for _, node in pairs(trafficControl.queueNodes) do repeat
        local distance = clientOrigin:getDistance(node.origin)

        if distance >= closestDistance then
            break
        end

        local trace = Trace.getLineToPosition(LocalPlayer.getEyeOrigin(), node.origin, AiUtility.traceOptionsPathfinding, "AiStateTrafficControl.assess<FindQueueNode>")

        if trace.isIntersectingGeometry then
            break
        end

        closestDistance = distance
        closestQueueNode = node
    until true end

    -- No queue nodes.
    if not closestQueueNode then
        return AiPriority.IGNORE
    end

    self.trafficControlNode = trafficControl
    self.trafficQueueNode = closestQueueNode

    return AiPriority.TRAFFIC_CONTROL
end

--- @param trafficControl NodeHintTrafficControl
--- @return boolean
function AiStateTrafficControl:isOccupied(trafficControl)
    -- Find any teammates occupying the zone.
    for _, teammate in pairs(AiUtility.teammates) do repeat
        local teammateOrigin = teammate:getOrigin()

        if teammateOrigin:getDistance(trafficControl.origin) > trafficControl.occupancyRadius then
            break
        end

        return true
    until true end

    return false
end

--- @return void
function AiStateTrafficControl:activate()
    self.isWaiting = true

    Pathfinder.moveToNode(self.trafficQueueNode, {
        goalReachedRadius = 50,
        task = "Wait in traffic"
    })
end

--- @return void
function AiStateTrafficControl:deactivate()
    self:reset()
end

--- @return void
function AiStateTrafficControl:reset()
    self.isWaiting = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateTrafficControl:think(cmd)
    self.activity = "Queuing in traffic"

    VirtualMouse.lookAtLocation(self.trafficQueueNode.lookAtOrigin, 4, VirtualMouse.noise.moving, "Traffic Control watch angle")
    Pathfinder.ifIdleThenRetryLastRequest()

    if not self:isOccupied(self.trafficControlNode) then
        self:reset()
    end
end

return Nyx.class("AiStateTrafficControl", AiStateTrafficControl, AiStateBase)
--}}}
