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
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
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
        if e.victim:isLocalPlayer() then
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

    Pathfinder.canRandomlyJump()

    local followingPlayerOrigin = self.followingPlayer:getOrigin()
    local distanceToLastOrigin = followingPlayerOrigin:getDistance(self.lastFollowingPlayOrigin)
    local distanceToPlayer = followingPlayerOrigin:getDistance(LocalPlayer:getOrigin())

    if distanceToLastOrigin > 64 then
        self.lastFollowingPlayOrigin = followingPlayerOrigin

        self:move()
    end

    if distanceToPlayer < 100 then
        Pathfinder.clearActivePathAndLastRequest()
    end

    if distanceToLastOrigin < 300 then
       View.lookAtLocation(self.followingPlayer:getOrigin():offset(0, 0, 64), 5, View.noise.idle, "Follow look at player")
    end
end

--- @return void
function AiStateFollow:move()
    local node = Nodegraph.getRandom(Node.traverseGeneric, self.lastFollowingPlayOrigin, 200)

    Pathfinder.moveToNode(node, {
        task = "Follow player",
        goalReachedRadius = 150
    })
end

return Nyx.class("AiStateFollow", AiStateFollow, AiStateBase)
--}}}
