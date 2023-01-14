--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Time = require "gamesense/Nyx/v1/Api/Time"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateFreezetime
--- @class AiStateFreezetime : AiStateBase
--- @field crouchCooldownTime number
--- @field crouchCooldownTimer Timer
--- @field crouchTime number
--- @field crouchTimer Timer
--- @field currentBehavior fun(self: AiStateFreezetime, cmd: SetupCommandEvent): void
--- @field freezeTime number
--- @field freezeTimeCutoff number
--- @field freezeTimer Timer
--- @field lookAngles Angle
--- @field nextBehaviorTime Timer
--- @field nextBehaviorTimer Timer
--- @field plusDirection number
--- @field target Player
local AiStateFreezetime = {
    name = "Freezetime"
}

--- @param fields AiStateFreezetime
--- @return AiStateFreezetime
function AiStateFreezetime:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateFreezetime:__init()
    self.nextBehaviorTimer = Timer:new()
    self.nextBehaviorTime = 0
    self.lookAngles = Angle:new()
    self.crouchTimer = Timer:new()
    self.crouchTime = 1
    self.crouchCooldownTimer = Timer:new():startThenElapse()
    self.crouchCooldownTime = 1
    self.freezeTimer = Timer:new()

    Callbacks.roundPrestart(function()
    	self.freezeTimer:restart()
        self.freezeTime = cvar.mp_freezetime:get_int()
        self.plusDirection = Math.getChance(2) and 1 or 0

        if Math.getChance(3) then
            self.freezeTimeCutoff = Math.getRandomFloat(0.1, 1.5)
        else
            self.freezeTimeCutoff = -(self.freezeTime * Math.getRandomFloat(0.0, 0.33))
        end
    end)
end

--- @return void
function AiStateFreezetime:assess()
    -- Handle the AI being restarted.
    if not self.freezeTimer:isStarted() then
        return AiPriority.IGNORE
    end

    -- Stop idling and start preparing for the round instead.
    if self.freezeTimer:isStarted() and self.freezeTimer:isElapsed(self.freezeTime + self.freezeTimeCutoff) then
        return AiPriority.IGNORE
    end

    return AiPriority.FREEZETIME
end

--- @return void
function AiStateFreezetime:activate()
    self.target = Table.getRandomFromNonIndexed(AiUtility.teammates)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateFreezetime:think(cmd)
    self.activity = "Idling in freezetime"

    self.ai.routines.manageGear:block()

    LocalPlayer.cancelEquip()

    if self.nextBehaviorTimer:isElapsedThenRestart(self.nextBehaviorTime) then
        self.nextBehaviorTime = Math.getRandomFloat(1.5, 8)
        self.target = Table.getRandomFromNonIndexed(AiUtility.teammates)

        if Math.getChance(10) then
            self.currentBehavior = AiStateFreezetime.actionSpinAround
        elseif Math.getChance(5) then
            self.currentBehavior = AiStateFreezetime.actionLookAtTeammate
        else
            self.currentBehavior = self.actionIdle
        end
    end

    self.currentBehavior(self, cmd)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateFreezetime:actionIdle(cmd) end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateFreezetime:actionLookAtTeammate(cmd)
    if not self.target then
        return
    end

    if self.crouchCooldownTimer:isElapsed(self.crouchCooldownTime) then
        self.crouchTimer:ifPausedThenStart()

        if self.crouchTimer:isElapsed(self.crouchTime) then
            self.crouchCooldownTime = Math.getRandomFloat(1, 15)
            self.crouchTime = Math.getRandomFloat(0.5, 1)

            self.crouchCooldownTimer:restart()
            self.crouchTimer:stop()
        else
            cmd.in_duck = true
        end
    end

    local targetOrigin = self.target:getOrigin():offset(0, 0, 64)

    -- I don't know why this sometimes returns nil.
    if not targetOrigin then
        return
    end

    VirtualMouse.lookAtLocation(targetOrigin, 4, VirtualMouse.noise.idle, "Freezetime idling")
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateFreezetime:actionSpinAround(cmd)
    local speed

    if self.plusDirection == 0 then
        speed = 180
    else
        speed = -180
    end

    self.lookAngles:offset(0, speed * Time.getDelta())

    VirtualMouse.lookAlongAngle(self.lookAngles, 6, VirtualMouse.noise.idle, "Freezetime idling")
end

return Nyx.class("AiStateFreezetime", AiStateFreezetime, AiStateBase)
--}}}
