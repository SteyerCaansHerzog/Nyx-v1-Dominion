--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateWait
--- @class AiStateWait : AiState
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
        return AiState.priority.FOLLOW
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateWait:activate(ai)
    self:move(ai.nodegraph)
end

--- @return void
function AiStateWait:reset()
    self.isWaiting = false
    self.waitingOnPlayer = nil
end

--- @param ai AiOptions
--- @return void
function AiStateWait:think(ai)
    self.activity = "Waiting on teammate"

    local clientOrigin = AiUtility.client:getOrigin()
    local distanceToPlayer = clientOrigin:getDistance(self.waitingOnPlayer:getOrigin())
    local distanceToNode = clientOrigin:getDistance(self.node.origin)

    if distanceToNode < 128 and ai.nodegraph.path then
        ai.nodegraph:clearPath("Wait stop")
    end

    if distanceToNode < 256 and distanceToPlayer < 1024 then
        ai.view:lookAtLocation(self.waitingOnPlayer:getHitboxPosition(Player.hitbox.HEAD), 5, ai.view.noiseType.IDLE, "Wait look at player")
    end
end

--- @param nodegraph Nodegraph
--- @return void
function AiStateWait:move(nodegraph)
    --- @type Node[]
    local nodes = {}
    --- @type Node[]
    local closestNode
    local closestNodeDistance = math.huge

    for _, node in pairs(nodegraph.nodes) do
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

    nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid()
    })
end

return Nyx.class("AiStateWait", AiStateWait, AiState)
--}}}
