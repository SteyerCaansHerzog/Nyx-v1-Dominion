--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Time = require "gamesense/Nyx/v1/Api/Time"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiStateFreezetime
--- @class AiStateFreezetime : AiState
--- @field target Player
--- @field nextBehaviorTimer Timer
--- @field nextBehaviorTime Timer
--- @field currentBehavior fun(self: AiStateFreezetime, cmd: SetupCommandEvent): void
--- @field lookAngles Angle
--- @field crouchTimer Timer
--- @field crouchTime number
--- @field crouchCooldownTimer Timer
--- @field crouchCooldownTime number
--- @field freezeTimer Timer
--- @field freezeTime number
--- @field freezeTimeCutoff number
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

        if Client.getChance(3) then
            self.freezeTimeCutoff = Client.getRandomFloat(0.1, 1)
        else
            self.freezeTimeCutoff = -(self.freezeTime * Client.getRandomFloat(0.1, 0.8))
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

    if self.nextBehaviorTimer:isElapsedThenRestart(self.nextBehaviorTime) then
        self.nextBehaviorTime = Client.getRandomFloat(4, 10)
        self.target = Table.getRandomFromNonIndexed(AiUtility.teammates)

        if Client.getChance(16) then
            local behaviors = {
                AiStateFreezetime.actionLookAtTeammate,
                AiStateFreezetime.actionSpinAround,
            }

            self.currentBehavior = Table.getRandom(behaviors)
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
            self.crouchCooldownTime = Client.getRandomFloat(1, 10)
            self.crouchTime = Client.getRandomFloat(0.6, 1)

            self.crouchCooldownTimer:restart()
            self.crouchTimer:stop()
        else
            cmd.in_duck = 1
        end
    end

    local targetEyeOrigin = self.target:getEyeOrigin()

    -- I don't know why this sometimes returns nil.
    if not targetEyeOrigin then
        return
    end

    self.ai.view:lookAtLocation(targetEyeOrigin, 4, self.ai.view.noiseType.IDLE, "Freezetime idling")
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateFreezetime:actionSpinAround(cmd)
    self.lookAngles:offset(0, 90 * Time.getDelta())

    self.ai.view:lookInDirection(self.lookAngles, 6, self.ai.view.noiseType.IDLE, "Freezetime idling")
end

return Nyx.class("AiStateFreezetime", AiStateFreezetime, AiState)
--}}}
