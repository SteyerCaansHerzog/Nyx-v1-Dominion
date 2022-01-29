--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateGrenadeDynamic
--- @class AiStateGrenadeDynamic : AiState
--- @field throwAngles Angle
--- @field throwTimer Timer
--- @field throwCooldownTimer Timer
--- @field isThrowing boolean
local AiStateGrenadeDynamic = {
    name = "Grenade Dynamic"
}

--- @param fields AiStateGrenadeDynamic
--- @return AiStateGrenadeDynamic
function AiStateGrenadeDynamic:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateGrenadeDynamic:__init()
    self.throwTimer = Timer:new()
    self.throwCooldownTimer = Timer:new():startThenElapse()

    Callbacks.roundStart(function()
    	self:reset()
    end)
end

--- @return void
function AiStateGrenadeDynamic:assess()
    -- Cooldown. We really need it.
    if not self.throwCooldownTimer:isElapsed(5) then
        return AiState.priority.IGNORE
    end

    -- We already found an angle to not-blind a totally-suspecting enemy player with.
    if self.throwAngles then
        return AiState.priority.DYNAMIC_GRENADE
    end

    -- Don't bother if we don't even have a flashbang on us.
    if not AiUtility.client:hasWeapon(Weapons.FLASHBANG) then
        return AiState.priority.IGNORE
    end

    local clientOrigin = AiUtility.client:getOrigin()

    -- Angle to try our mentally handicapped flash prediction with.
    local predictionAngles = Angle:new(Client.getRandomFloat(-89, -65), Client.getRandomFloat(-180, 180))

    -- I literally threw a flash into the sky and asked for the distance from my eye sockets to the detonation point.
    local predictionDistance = 700

    -- Oh Source, do tell us where this stray nade "prediction" went?
    local impactTrace = Trace.getLineAtAngle(clientOrigin, predictionAngles, {
        skip = AiUtility.client.eid,
        mask = Trace.mask.VISIBLE,
        distance = predictionDistance
    })

    -- Throw away traces that end too close to us because they're useless and will just blind the AI.
    -- Although, the AI would probably want to be blind if it pulled up its own hood and found this demented-ass method.
    if clientOrigin:getDistance(impactTrace.endPosition) < 300 then
        return AiState.priority.IGNORE
    end

    -- Oh boy, which of our opponents is gonna get to see the worst thrown flashbang of their lives?
    -- If you've never seen a do repeat until true loop before it's because Lua couldn't be bothered to implement "continue".
    for _, enemy in pairs(AiUtility.enemies) do repeat
        -- Does our super accurate "detonate" spot trace have line of sight to the approximate enemy's eyeballs?
        -- Not using getHitboxPosition because getOrigin works on dormancy. That and CSGO's hitbox positions are more demented than this code.
        local blindTrace = Trace.getLineToPosition(impactTrace.endPosition, enemy:getOrigin():offset(0, 0, 72), {
            skip = enemy.eid,
            mask = Trace.mask.VISIBLE
        })

        -- No line of sight. Lucky for him.
        if blindTrace.isIntersectingGeometry then
            break
        end

        -- The enemy probably wouldn't be blinded even if we threw an actually well-calculated flash at them.
        if blindTrace.startPosition:getDistance(blindTrace.endPosition) > 1200 then
            break
        end

        -- We're gonna try these angles. Pray on God.
        self.throwAngles = predictionAngles

        return AiState.priority.DYNAMIC_GRENADE
    until true end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateGrenadeDynamic:activate(ai)
    ai.nodegraph:clearPath("throw a dynamic grenade")
end

--- @return void
function AiStateGrenadeDynamic:reset()
    self.throwAngles = nil
    self.isThrowing = false

    self.throwTimer:stop()
end

--- @param ai AiOptions
--- @return void
function AiStateGrenadeDynamic:think(ai)
    ai.controller.states.evade.isBlocked = true
    ai.controller.canUseKnife = false
    ai.controller.canLookAwayFromFlash = false
    ai.controller.isQuickStopping = true
    ai.controller.canAntiBlock = false
    ai.view.isCrosshairFloating = false
    ai.view.isCrosshairUsingVelocity = false
    ai.view.isCrosshairSmoothed = true

    if not AiUtility.client:isHoldingWeapon(Weapons.FLASHBANG) then
        Client.equipFlashbang()
    end

    ai.view:lookInDirection(self.throwAngles, 4)

    local deltaAngles = self.throwAngles:getAbsDiff(Client.getCameraAngles())

    if deltaAngles.p < 4
        and deltaAngles.y < 4
        and AiUtility.client:isHoldingWeapon(Weapons.FLASHBANG)
        and AiUtility.client:isAbleToAttack()
    then
        self.isThrowing = true
    end

    if self.isThrowing then
        self.throwTimer:ifPausedThenStart()

        ai.cmd.in_attack = 1
    end

    if self.throwTimer:isElapsedThenRestart(0.1) then
        ai.cmd.in_attack = 0

        Client.fireAfter(0.1, function()
            self.throwCooldownTimer:restart()

            self:reset()
        end)
    end
end

return Nyx.class("AiStateGrenadeDynamic", AiStateGrenadeDynamic, AiState)
--}}}
