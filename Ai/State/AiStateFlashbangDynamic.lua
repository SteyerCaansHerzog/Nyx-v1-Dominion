--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local GrenadePrediction = require "gamesense/Nyx/v1/Api/GrenadePrediction"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateFlashbangDynamic
--- @class AiStateFlashbangDynamic : AiStateBase
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
    name = "Flashbang Dynamic",
    delayedMouseMin = 0.05,
    delayedMouseMax = 0.2
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
    -- Do not waste time with nades when bomb is close to detonation.
    if AiUtility.plantedBomb and AiUtility.bombDetonationTime <= 18 and LocalPlayer:isCounterTerrorist() then
        return AiPriority.IGNORE
    end

    -- AI is threatened. Don't try to throw a flashbang.
    if AiUtility.isClientThreatenedMajor or AiUtility.isEnemyVisible then
        self.threatCooldownTimer:restart()

        return AiPriority.IGNORE
    end

    -- We were just threatened by an enemy, so we don't want to try again too soon.
    if not self.threatCooldownTimer:isElapsed(5) then
        return AiPriority.IGNORE
    end

    -- Cooldown because the AI doesn't need to keep throwing flashbangs constantly.
    if not self.throwCooldownTimer:isElapsed(12) then
        return AiPriority.IGNORE
    end

    -- Don't let the AI spam when attempting this behaviour.
    -- Our anti-dithering is literally timers. Timers everywhere. Timers forever.
    if not self.throwAttemptCooldownTimer:isElapsed(1.5) then
        return AiPriority.IGNORE
    end

    -- Don't bother if we don't even have a flashbang on us.
    if not LocalPlayer:hasWeapon(Weapons.FLASHBANG) then
        return AiPriority.IGNORE
    end

    -- We already found an angle to not-blind a totally-suspecting enemy player with.
    if self.throwAngles then
        return AiPriority.FLASHBANG_DYNAMIC
    end

    local clientEyeOrigin = LocalPlayer.getEyeOrigin()
    local bounds = Vector3:newBounds(Vector3.align.CENTER, 8)

    -- Angle to try our mentally handicapped flash prediction with.
    local predictionAngles = Angle:new(Math.getRandomFloat(-85, 25), Math.getRandomFloat(-180, 180))

    local predictor = GrenadePrediction.create()

    predictor:setupArbitrary(
        LocalPlayer.eid,
        Weapons.FLASHBANG,
        LocalPlayer.getEyeOrigin(),
        predictionAngles
    )

    local prediction = predictor:predict()

    if not prediction then
        return AiPriority.IGNORE
    end

    local predictionEndPosition = Vector3:new(prediction.end_pos.x, prediction.end_pos.y, prediction.end_pos.z)

    -- Throw away traces that end too close to us because they're useless and will just blind the AI.
    -- Although, the AI would probably want to be blind if it pulled up its own hood and found this demented-ass logic.
    if clientEyeOrigin:getDistance(predictionEndPosition) < 300 then
        return AiPriority.IGNORE
    end

    -- Oh boy, which of our opponents is gonna get to see the worst thrown flashbang of their lives?
    -- If you've never seen a do repeat until true loop before it's because Lua couldn't be bothered to implement "continue".
    for _, enemy in pairs(AiUtility.enemies) do repeat
        local enemyTestOrigin = enemy:getOrigin():offset(0, 0, 64)

        -- Does our super accurate "detonate" spot trace have line of sight to the approximate enemy's eyeballs?
        -- Not using getHitboxPosition because getOrigin works on dormancy. That and CSGO's hitbox positions are more demented than this code.
        local blindTrace = Trace.getHullToPosition(predictionEndPosition, enemyTestOrigin, bounds, {
            skip = enemy.eid,
            mask = Trace.mask.VISIBLE
        }, "AiStateFlashbangDynamic.assess<FindEnemyVisibleToFlashbang>")

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
        local nearTrace = Trace.getHullAtAngle(clientEyeOrigin, predictionAngles:clone():offset(-12), bounds, {
            skip = LocalPlayer.eid,
            mask = Trace.mask.VISIBLE,
            distance = 200
        }, "AiStateFlashbangDynamic.assess<FindWallTooClose>")

        -- We're gonna try these angles. Pray on God.
        self.throwAngles = predictionAngles

        -- Try not to throw the flash at the wall in front of us.
        if nearTrace.isIntersectingGeometry then
            self.throwAngles:offset(0, 6)
        end

        -- Target to blind.
        self.targetPlayer = enemy

        -- Determine if we want to jump-throw the flashbang.
        self.throwFromOrigin = LocalPlayer:getOrigin()

        -- Forgot why this needed to be on the next tick. Probably because of other bad code I have written.
        Client.onNextTick(function()
            if not self.isActivated then
                self:reset()
            end
        end)

        return AiPriority.FLASHBANG_DYNAMIC
    until true end

    return AiPriority.IGNORE
end

--- @return void
function AiStateFlashbangDynamic:activate()
    self.isActivated = true
end

--- @return void
function AiStateFlashbangDynamic:deactivate()
    self.throwAttemptCooldownTimer:restart()

    self:reset()
end

--- @return void
function AiStateFlashbangDynamic:reset()
    self.isActivated = false
    self.isThrowing = false
    self.targetPlayer = nil
    self.throwAngles = nil
    self.throwFromOrigin = nil

    self.throwTimer:stop()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateFlashbangDynamic:think(cmd)
    if not self.targetPlayer then
        self:reset()

        return
    end

    -- If we're not in a throw, and the round is over or our target has died, then do not throw.
    if not self.isThrowing and (AiUtility.isRoundOver or not self.targetPlayer:isAlive()) then
        self:reset()

        return
    end

    -- We've moved too far.
    if LocalPlayer:getOrigin():getDistance(self.throwFromOrigin) > 32 then
        self:reset()

        return
    end

    self.activity = "Throwing Flashbang"

    self.ai.states.evade:block()
    self.ai.routines.manageGear:block()
    self.ai.routines.lookAwayFromFlashbangs:block()

    Pathfinder.standStill()
    Pathfinder.counterStrafe()
    Pathfinder.blockTeammateAvoidance()
    LocalPlayer.equipFlashbang()
    View.lookAlongAngle(self.throwAngles, 4.5, View.noise.none, "FlashbangDynamic look at throw angle")

    View.isCrosshairUsingVelocity = true
    View.isCrosshairSmoothed = false

    local maxDiff = self.throwAngles:getMaxDiff(LocalPlayer.getCameraAngles())

    if maxDiff < 15
        and LocalPlayer:isAbleToAttack()
        and LocalPlayer:isHoldingWeapon(Weapons.FLASHBANG)
    then
        self.isThrowing = true
    end

    if self.isThrowing then
        self.throwTimer:ifPausedThenStart()

        cmd.in_attack = true

        if not AiUtility.isLastAlive then
            self.ai.voice.pack:speakClientThrowingFlashbang()
        end
    end

    if self.throwTimer:isElapsedThenRestart(0.1) then
        cmd.in_attack = false

        Client.fireAfter(0.15, function()
            self.throwCooldownTimer:restart()

            self:reset()
        end)
    end
end

return Nyx.class("AiStateFlashbangDynamic", AiStateFlashbangDynamic, AiStateBase)
--}}}
