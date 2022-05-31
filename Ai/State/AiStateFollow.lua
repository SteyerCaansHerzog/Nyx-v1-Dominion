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
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateFollow
--- @class AiStateFollow : AiStateBase
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
        return AiPriority.FOLLOW
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateFollow:activate()
    self.lastFollowingPlayOrigin = self.followingPlayer:getOrigin()

    self:move()
end

--- @return void
function AiStateFollow:reset()
    self.isFollowing = false
    self.followingPlayer = nil
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateFollow:think(cmd)
    self.activity = "Following teammate"

    local followingPlayerOrigin = self.followingPlayer:getOrigin()
    local distance = followingPlayerOrigin:getDistance(self.lastFollowingPlayOrigin)

    if distance > 64 then
        self.lastFollowingPlayOrigin = followingPlayerOrigin

        self:move()
    end

    if distance < 250 then
       View.lookAtLocation(self.followingPlayer:getOrigin():offset(0, 0, 64), 4, View.noise.idle, "Follow look at player")
    end
end

--- @return void
function AiStateFollow:move()
    --- @type Node[]
    local nodes = {}
    --- @type Node[]
    local closestNode
    local closestNodeDistance = math.huge

    for _, node in pairs(self.ai.nodegraph.nodes) do
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

   self.ai.nodegraph:pathfind(node.origin, {
        objective = Node.types.GOAL
    })
end

return Nyx.class("AiStateFollow", AiStateFollow, AiStateBase)
--}}}
