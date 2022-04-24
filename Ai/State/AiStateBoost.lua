--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiStateBoost
--- @class AiStateBoost : AiState
--- @field boostOrigin Vector3
--- @field boostPlayer Player
--- @field isBoosting boolean
--- @field boostLookTimer Timer
--- @field boostLookAngles Angle
local AiStateBoost = {
    name = "Boost"
}

--- @param fields AiStateBoost
--- @return AiStateBoost
function AiStateBoost:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateBoost:__init()
    self.boostLookTimer = Timer:new():startThenElapse()

    Callbacks.roundStart(function()
    	self:reset()
    end)
end

--- @return number
function AiStateBoost:assess()
    if self.boostPlayer then
        if AiUtility.client:getOrigin():getDistance2(self.boostPlayer:getOrigin()) < 256 then
            return AiPriority.BOOST_ACTIVE
        end

        return AiPriority.BOOST
    end

    return AiPriority.IGNORE
end

--- @param player Player
--- @param origin Vector3
--- @return void
function AiStateBoost:boost(player, origin)
    self.boostPlayer = player
    self.boostOrigin = origin
end

--- @return void
function AiStateBoost:activate()
    self.ai.nodegraph:pathfind(self.boostOrigin, {
    objective = Node.types.GOAL,
        task = string.format("Boost %s", self.boostPlayer:getName())
    })

    self.ai.commands.boost.isTaken = false
end

--- @return void
function AiStateBoost:deactivate()
    self:reset()
end

--- @return void
function AiStateBoost:reset()
    self.boostPlayer = nil
    self.boostOrigin = nil
    self.isBoosting = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateBoost:think(cmd)
    self.activity = "Going to boost teammate"

    if self.ai.nodegraph.pathfindFails > 0 then
        self:reset()

        return
    end

    if not self.boostPlayer or not self.boostPlayer:isAlive() then
        self:reset()

        return
    end

    local playerOrigin = AiUtility.client:getOrigin()
    local originDistance = playerOrigin:getDistance(self.boostOrigin)
    local senderDistance = playerOrigin:getDistance(self.boostPlayer:getOrigin())

    if self.isBoosting and senderDistance > 128 then
        self:reset()

        return
    end

    if self.boostLookTimer:isElapsedThenRestart(2) then
        self.boostLookAngles = self.boostPlayer:getCameraAngles():offset(
            Client.getRandomFloat(-2, 2),
            Client.getRandomFloat(-8, 8)
        )
    end

    if originDistance < 200 then
        self.activity = "Waiting to boost teammate"
    end

    if senderDistance < 500 and originDistance < 200 then
        self.ai.nodegraph.isAllowedToAvoidTeammates = false
        self.ai.canLookAwayFromFlash = false
        self.ai.states.evade.isBlocked = true

        local bounds = playerOrigin:clone():offset(0, 0, 32):getBounds(Vector3.align.BOTTOM, 25, 25, 128)

        if originDistance < 64 and not self.boostPlayer:getOrigin():offset(0, 0, 48):isInBounds(bounds) then
            if senderDistance < 128 then
                cmd.in_duck = 1
            end

            self.ai.view:lookAtLocation(self.boostPlayer:getHitboxPosition(Player.hitbox.NECK), 2, self.ai.view.noiseType.IDLE, "Boost look at booster")
        else
            self.ai.view:lookInDirection(self.boostLookAngles, 2, self.ai.view.noiseType.IDLE, "Boost copy booster direction")
        end
    end

    if originDistance < 64 and senderDistance < 72 then
        self.activity = "Boosting teammate"
        self.isBoosting = true
    end
end

return Nyx.class("AiStateBoost", AiStateBoost, AiState)
--}}}
