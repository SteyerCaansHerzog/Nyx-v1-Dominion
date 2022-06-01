--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateWait
--- @class AiStateWait : AiStateBase
--- @field isWaiting boolean
--- @field node Node
--- @field waitingOnPlayer Player
--- @field waitingOrigin Vector3
local AiStateWait = {
    name = "Wait"
}

--- @param fields AiStateWait
--- @return AiStateWait
function AiStateWait:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateWait:__init()
    Callbacks.roundStart(function()
    	self:reset()
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isClient() then
            self:reset()
        end

        if self.waitingOnPlayer and e.victim:is(self.waitingOnPlayer) then
            self:reset()
        end
    end)
end

--- @param player Player
--- @param origin Vector3
--- @param nodegraph Nodegraph
--- @return void
function AiStateWait:wait(player, origin, nodegraph)
    self.isWaiting = true
    self.waitingOnPlayer = player
    self.waitingOrigin = origin

    self:move(nodegraph)
end

--- @return void
function AiStateWait:assess()
    if self.isWaiting then
        return AiPriority.FOLLOW
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateWait:activate()
    self:move()
end

--- @return void
function AiStateWait:reset()
    self.isWaiting = false
    self.waitingOnPlayer = nil
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateWait:think(cmd)
    self.activity = "Waiting on teammate"

    local clientOrigin = LocalPlayer:getOrigin()
    local distanceToPlayer = clientOrigin:getDistance(self.waitingOnPlayer:getOrigin())
    local distanceToNode = clientOrigin:getDistance(self.node.origin)

    if distanceToNode < 128 and self.ai.nodegraph.path then
       self.ai.nodegraph:clearPath("Wait stop")
    end

    if distanceToNode < 250 and distanceToPlayer < 250 then
       View.lookAtLocation(self.waitingOnPlayer:getOrigin():offset(0, 0, 64), 5, View.noise.idle, "Wait look at player")
    end
end

--- @return void
function AiStateWait:move()
    --- @type Node[]
    local nodes = {}
    --- @type Node[]
    local closestNode
    local closestNodeDistance = math.huge

    for _, node in pairs(self.ai.nodegraph.nodes) do
        local distance = self.waitingOrigin:getDistance(node.origin)

        if distance < 256 then
            table.insert(nodes, node)
        end

        if distance < closestNodeDistance then
            closestNodeDistance = distance
            closestNode = node
        end
    end

    local node = not Table.isEmpty(nodes) and Table.getRandom(nodes) or closestNode

    self.node = node

    self.ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL
    })
end

return Nyx.class("AiStateWait", AiStateWait, AiStateBase)
--}}}
