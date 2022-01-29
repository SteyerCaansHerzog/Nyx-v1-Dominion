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
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateWait
--- @class AiStateWait : AiState
--- @field isWaiting boolean
--- @field waitingOnPlayer Player
--- @field waitingOrigin Vector3
local AiStateWait = {
    name = "Follow"
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
--- @return void
function AiStateWait:wait(player, origin)
    self.isWaiting = true
    self.waitingOnPlayer = player
    self.waitingOrigin = origin
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
    self:move(ai)
end

--- @return void
function AiStateWait:reset()
    self.isWaiting = false
    self.waitingOnPlayer = nil
end

--- @param ai AiOptions
--- @return void
function AiStateWait:think(ai) end

--- @param ai AiOptions
--- @return void
function AiStateWait:move(ai)
    --- @type Node[]
    local nodes = {}
    --- @type Node[]
    local closestNode
    local closestNodeDistance = math.huge

    for _, node in pairs(ai.nodegraph.nodes) do
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

    ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid()
    })
end

return Nyx.class("AiStateWait", AiStateWait, AiState)
--}}}
