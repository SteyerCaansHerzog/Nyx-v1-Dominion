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
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateFlashbangDynamic
--- @class AiStateFlashbangDynamic : AiStateBase
--- @field canJumpThrow boolean
--- @field isActivated boolean
--- @field isAllowedToFlashTeammate boolean
--- @field isThrowing boolean
--- @field node NodeTypeTraverse
--- @field targetPlayer Player
--- @field threatCooldownTimer Timer
--- @field throwAngles Angle
--- @field throwAttemptCooldownTimer Timer
--- @field throwCooldownTimer Timer
--- @field throwFromOrigin Vector3
--- @field throwTimer Timer
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

    Callbacks.flashbangDetonate(function(e)
        if not e.player:isLocalPlayer() then
            return
        end

        self.isAllowedToFlashTeammate = Math.getChance(3)
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
        self.threatCooldownTimer:start()
    end

    -- We were just threatened by an enemy, so we don't want to try again too soon.
    if not self.threatCooldownTimer:isElapsed(5) then
        return AiPriority.IGNORE
    end

    -- We already found an angle to not-blind a totally-suspecting enemy player with.
    if self.throwAngles then
        return AiPriority.FLASHBANG_DYNAMIC
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

    --- @type Vector3
    local throwFromOrigin
    local clientEyeOrigin = LocalPlayer.getEyeOrigin()
    local bounds = Vector3:newBounds(Vector3.align.CENTER, 8)
    local node = Nodegraph.getRandom(Node.traverseGeneric, LocalPlayer:getOrigin(),  200)

    if node then
        local nodeEyeOrigin = node.origin:clone():offset(0, 0, 46)

        -- Are any enemies able to see the node directly?
        -- If so, then we really don't want to try that lineup.
        for _, enemy in pairs(AiUtility.enemies) do
            local trace = Trace.getLineToPosition(nodeEyeOrigin, enemy:getEyeOrigin(), AiUtility.traceOptionsVisible, "AiStateFlashbangDynamic.asses<FindVisibleEnemy>")

            if not trace.isIntersectingGeometry then
                return AiPriority.IGNORE
            end
        end

        throwFromOrigin = nodeEyeOrigin
    else
        throwFromOrigin = clientEyeOrigin
    end

    self.node = node

    -- Angle to try our mentally handicapped flash prediction with.
    local predictionAngles = Angle:new(Math.getRandomFloat(-85, 25), Math.getRandomFloat(-180, 180))
    local predictor = GrenadePrediction.create()

    predictor:setupArbitrary(
        LocalPlayer.eid,
        Weapons.FLASHBANG,
        throwFromOrigin,
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

    -- Avoid flashing teammates.
    if not self.isAllowedToFlashTeammate then
        for _, teammate in pairs(AiUtility.teammates) do
            local teammateTestOrigin = teammate:getOrigin():offset(0, 0, 64)

            -- Does our super accurate "detonate" spot trace have line of sight to the approximate enemy's eyeballs?
            -- Not using getHitboxPosition because getOrigin works on dormancy. That and CSGO's hitbox positions are more demented than this code.
            local blindTrace = Trace.getHullToPosition(predictionEndPosition, teammateTestOrigin, bounds, {
                skip = teammate.eid,
                mask = Trace.mask.VISIBLE
            }, "AiStateFlashbangDynamic.assess<FindTeammateVisibleToFlashbang>")

            -- No line of sight. Lucky for him.
            if blindTrace.isIntersectingGeometry then
                break
            end

            local distance = blindTrace.startPosition:getDistance(blindTrace.endPosition)

            -- The teammate probably wouldn't be blinded even if we threw an actually well-calculated flash at them.
            if distance > 800 then
                break
            end

            return AiPriority.IGNORE
        end
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
            distance = 100
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

    if self.node then
        Pathfinder.moveToNode(self.node, {
            task = "Flashbang dynamic move to throw nade",
            isCounterStrafingOnGoal = true,
            goalReachedRadius = 5
        })
    end
end

--- @return void
function AiStateFlashbangDynamic:deactivate()
    self.throwAttemptCooldownTimer:start()

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

    self.activity = "Throwing Flashbang"

    self.ai.states.evade:block()
    self.ai.routines.manageGear:block()
    self.ai.routines.lookAwayFromFlashbangs:block()

    Pathfinder.blockTeammateAvoidance()
    LocalPlayer.equipFlashbang()
    VirtualMouse.lookAlongAngle(self.throwAngles, 4.5, VirtualMouse.noise.none, "FlashbangDynamic look at throw angle")

    VirtualMouse.isCrosshairUsingVelocity = true
    VirtualMouse.isCrosshairLerpingToZero = true

    -- Don't continue until we've lined the flash up.
    if Pathfinder.isOnValidPath() then
        return
    end

    Pathfinder.counterStrafe(true)

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
            self.throwCooldownTimer:start()

            self.ai.routines.walk.cooldownTimer:start()

            self:reset()
        end)
    end
end

return Nyx.class("AiStateFlashbangDynamic", AiStateFlashbangDynamic, AiStateBase)
--}}}
