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

--{{{ AiStateFollow
--- @class AiStateFollow : AiState
--- @field isFollowing boolean
--- @field followingPlayer Player
--- @field lastFollowingPlayOrigin Vector3
local AiStateFollow = {
    name = "Follow"
}

--- @param fields AiStateFollow
--- @return AiStateFollow
function AiStateFollow:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateFollow:__init()
    Callbacks.roundStart(function()
    	self:reset()
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isClient() then
            self:reset()
        end

        if self.followingPlayer and e.victim:is(self.followingPlayer) then
            self:reset()
        end
    end)
end

--- @param player Player
--- @return void
function AiStateFollow:follow(player)
    self.isFollowing = true
    self.followingPlayer = player
end

--- @return void
function AiStateFollow:assess()
    if self.isFollowing then
        return AiState.priority.FOLLOW
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateFollow:activate(ai)
    self.lastFollowingPlayOrigin = self.followingPlayer:getOrigin()

    self:move(ai)
end

--- @return void
function AiStateFollow:reset()
    self.isFollowing = false
    self.followingPlayer = nil
end

--- @param ai AiOptions
--- @return void
function AiStateFollow:think(ai)
    local followingPlayerOrigin = self.followingPlayer:getOrigin()
    local distance = followingPlayerOrigin:getDistance(self.lastFollowingPlayOrigin)

    if distance > 64 then
        self.lastFollowingPlayOrigin = followingPlayerOrigin

        self:move(ai)
    end

    if distance < 256 then
        ai.view:lookAtLocation(self.followingPlayer:getHitboxPosition(Player.hitbox.HEAD), 2, ai.view.noiseType.IDLE, "Follow look at player")
    end
end

--- @param ai AiOptions
--- @return void
function AiStateFollow:move(ai)
    --- @type Node[]
    local nodes = {}
    --- @type Node[]
    local closestNode
    local closestNodeDistance = math.huge

    for _, node in pairs(ai.nodegraph.nodes) do
        local distance = self.lastFollowingPlayOrigin:getDistance(node.origin)

        if distance < 200 then
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

return Nyx.class("AiStateFollow", AiStateFollow, AiState)
--}}}
