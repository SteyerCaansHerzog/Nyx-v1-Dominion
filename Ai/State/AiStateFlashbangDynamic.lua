--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiStateFlashbangDynamic
--- @class AiStateFlashbangDynamic : AiState
--- @field canJumpThrow boolean
--- @field isActivated boolean
--- @field isThrowing boolean
--- @field targetPlayer Player
--- @field throwAngles Angle
--- @field throwAttemptCooldownTimer Timer
--- @field throwCooldownTimer Timer
--- @field throwFromOrigin Vector3
--- @field throwTimer Timer
--- @field threatCooldownTimer Timer
local AiStateFlashbangDynamic = {
    name = "Flashang Dynamic"
}

--- @param fields AiStateFlashbangDynamic
--- @return AiStateFlashbangDynamic
function AiStateFlashbangDynamic:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateFlashbangDynamic:__init()
    self.throwTimer = Timer:new()
    self.throwCooldownTimer = Timer:new():startThenElapse()
    self.throwAttemptCooldownTimer = Timer:new():startThenElapse()
    self.threatCooldownTimer = Timer:new():startThenElapse()

    Callbacks.roundStart(function()
    	self:reset()
    end)
end

--- @return void
function AiStateFlashbangDynamic:assess()
    -- Cooldown. We really need it.
    if not self.throwCooldownTimer:isElapsed(12) then
        return AiState.priority.IGNORE
    end

    -- Don't let them spam when attempting this behaviour.
    if not self.throwAttemptCooldownTimer:isElapsed(1.5) then
        return AiState.priority.IGNORE
    end

    -- AI is threatened. Don't try to, or abort trying to, throw a flashbang.
    if AiUtility.isClientThreatened then
        self.threatCooldownTimer:start()

        return AiState.priority.IGNORE
    end

    -- We were just threatened by an enemy, so we don't want to try again too soon.
    if not self.threatCooldownTimer:isElapsed(5) then
        return AiState.priority.IGNORE
    end

    -- We already found an angle to not-blind a totally-suspecting enemy player with.
    if self.throwAngles then
        return AiState.priority.FLASHBANG_DYNAMIC
    end

    -- Don't bother if we don't even have a flashbang on us.
    if not AiUtility.client:hasWeapon(Weapons.FLASHBANG) then
        return AiState.priority.IGNORE
    end

    local clientEyeOrigin = Client.getEyeOrigin()
    local bounds = Vector3:newBounds(Vector3.align.CENTER, 8)

    -- Angle to try our mentally handicapped flash prediction with.
    local predictionAngles = Angle:new(Client.getRandomFloat(-85, 25), Client.getRandomFloat(-180, 180))

    -- I literally threw a flash into the sky and asked God for the approximate distance it flew before going off.
    local predictionDistance = 700

    -- Oh Source, do tell us where this stray nade "prediction" went?
    local impactTrace = Trace.getHullAtAngle(clientEyeOrigin, predictionAngles, bounds, {
        skip = AiUtility.client.eid,
        mask = Trace.mask.SHOT,
        distance = predictionDistance
    })

    -- Throw away traces that end too close to us because they're useless and will just blind the AI.
    -- Although, the AI would probably want to be blind if it pulled up its own hood and found this demented-ass logic.
    if clientEyeOrigin:getDistance(impactTrace.endPosition) < 400 then
        return AiState.priority.IGNORE
    end

    -- Oh boy, which of our opponents is gonna get to see the worst thrown flashbang of their lives?
    -- If you've never seen a do repeat until true loop before it's because Lua couldn't be bothered to implement "continue".
    for _, enemy in pairs(AiUtility.enemies) do repeat
        local enemyTestOrigin = enemy:getOrigin():offset(0, 0, 72)

        -- Does our super accurate "detonate" spot trace have line of sight to the approximate enemy's eyeballs?
        -- Not using getHitboxPosition because getOrigin works on dormancy. That and CSGO's hitbox positions are more demented than this code.
        local blindTrace = Trace.getHullToPosition(impactTrace.endPosition, enemyTestOrigin, bounds, {
            skip = enemy.eid,
            mask = Trace.mask.SHOT
        })

        -- No line of sight. Lucky for him.
        if blindTrace.isIntersectingGeometry then
            break
        end

        local distance = blindTrace.startPosition:getDistance(blindTrace.endPosition)

        -- The enemy probably wouldn't be blinded even if we threw an actually well-calculated flash at them.
        if distance > 1200 then
            break
        end

        -- Check if we're going to throw it into a wall at close range.
        local nearTrace = Trace.getLineAtAngle(clientEyeOrigin, predictionAngles:clone():offset(-12), {
            skip = AiUtility.client.eid,
            mask = Trace.mask.VISIBLE,
            distance = 200
        })

        -- We're gonna try these angles. Pray on God.
        self.throwAngles = clientEyeOrigin:getAngle(impactTrace.endPosition)

        -- Try not to throw the flash at the wall in front of us.
        if nearTrace.isIntersectingGeometry then
            self.throwAngles:offset(0, 6)
        end

        self.targetPlayer = enemy

        local jumpEyeOrigin = clientEyeOrigin:clone():offset(0, 0, 60)
        local trace = Trace.getLineToPosition(jumpEyeOrigin, enemyTestOrigin, AiUtility.traceOptionsAttacking)
        local isVisibleWhenJumping = not trace.isIntersectingGeometry

        self.canJumpThrow = not isVisibleWhenJumping and predictionAngles.p < -40 and predictionAngles.p > -70
        self.throwFromOrigin = Client.getOrigin()

        Client.onNextTick(function()
            if not self.isActivated then
                self:reset()
            end
        end)

        return AiState.priority.FLASHBANG_DYNAMIC
    until true end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateFlashbangDynamic:activate(ai)
    ai.nodegraph:clearPath("throw a dynamic grenade")

    self.isActivated = true
end

--- @param ai AiOptions
--- @return void
function AiStateFlashbangDynamic:deactivate(ai)
    Client.equipPrimary()

    self.throwAttemptCooldownTimer:restart()

    self:reset()
end

--- @return void
function AiStateFlashbangDynamic:reset()
    self.canJumpThrow = false
    self.isActivated = false
    self.isThrowing = false
    self.targetPlayer = nil
    self.throwAngles = nil
    self.throwFromOrigin = nil

    self.throwTimer:stop()
end

--- @param ai AiOptions
--- @return void
function AiStateFlashbangDynamic:think(ai)
    self.activity = "Throwing Flashbang"

    -- If we're not in a throw, and the round is over or our target has died, then do not throw.
    if not self.isThrowing and (AiUtility.isRoundOver or not self.targetPlayer:isAlive()) then
        self:reset()

        return
    end

    -- We've moved too far.
    if Client.getOrigin():getDistance(self.throwFromOrigin) > 32 then
        self:reset()

        return
    end

    ai.controller.states.evade.isBlocked = true
    ai.controller.canUseGear = false
    ai.controller.canLookAwayFromFlash = false
    ai.controller.isQuickStopping = true
    ai.nodegraph.isAllowedToAvoidTeammates = false
    ai.view.isCrosshairUsingVelocity = true
    ai.view.isCrosshairSmoothed = false

    if not AiUtility.client:isHoldingWeapon(Weapons.FLASHBANG) then
        Client.equipFlashbang()
    end

    ai.view:lookInDirection(self.throwAngles, 4.5, ai.view.noiseType.NONE, "FlashbangDynamic look at throw angle")

    local maxDiff = self.throwAngles:getMaxDiff(Client.getCameraAngles())

    if maxDiff < 15
        and AiUtility.client:isHoldingWeapon(Weapons.FLASHBANG)
        and AiUtility.client:isAbleToAttack()
    then
        self.isThrowing = true
    end

    if self.isThrowing then
        self.throwTimer:ifPausedThenStart()

        ai.cmd.in_attack = 1

        if not AiUtility.isLastAlive then
            ai.voice.pack:speakClientThrowingFlashbang()
        end
    end

    if self.throwTimer:isElapsedThenRestart(0.1) then
        ai.cmd.in_attack = 0

        if self.canJumpThrow then
            ai.cmd.in_jump = 1
        end

        Client.fireAfter(0.15, function()
            self.throwCooldownTimer:restart()

            self:reset()
        end)
    end
end

return Nyx.class("AiStateFlashbangDynamic", AiStateFlashbangDynamic, AiState)
--}}}
