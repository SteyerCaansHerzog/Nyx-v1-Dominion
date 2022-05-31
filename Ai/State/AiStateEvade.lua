--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateEvade
--- @class AiStateEvade : AiStateBase
--- @field node Node
--- @field shotBoltActionRifleTimer Timer
--- @field shotBoltActionRifleTime number
--- @field changeAngleTimer Timer
--- @field changeAngleTime number
--- @field evadeLookAtAngles Vector3
--- @field isHurt boolean
--- @field hurtTimer Timer
--- @field isLookingAtPathfindingDirection boolean
local AiStateEvade = {
    name = "Evade"
}

--- @param fields AiStateEvade
--- @return AiStateEvade
function AiStateEvade:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateEvade:__init()
    self.shotBoltActionRifleTimer = Timer:new()
    self.shotBoltActionRifleTime = 1
    self.evadeLookAtAngles = Client.getCameraAngles()
    self.changeAngleTimer = Timer:new():startThenElapse()
    self.changeAngleTime = 1
    self.hurtTimer = Timer:new():startThenElapse()

    Callbacks.weaponFire(function(e)
        if e.player:isClient() and e.player:isHoldingSniper() then
            self.shotBoltActionRifleTimer:ifPausedThenStart()
        end
    end)

    Callbacks.playerHurt(function(e)
        if e.victim:isClient() and e.health < 20 then
            self.hurtTimer:restart()
        end
    end)
end

--- @return void
function AiStateEvade:assess()
    self.isLookingAtPathfindingDirection = false

    -- No enemies to threaten us.
    if AiUtility.enemiesAlive == 0 then
        return AiPriority.IGNORE
    end

    if not Client.hasBomb() and not self.hurtTimer:isElapsed(10) and AiUtility.timeData.roundtime_remaining > 40 then
        self.isLookingAtPathfindingDirection = true

        return AiPriority.EVADE_PASSIVE
    end

    local player = AiUtility.client

    -- We can be peeked by an enemy.
    if not AiUtility.isClientThreatened then
        return AiPriority.IGNORE
    end

    -- We're flashed.
    if Client.isFlashed() then
        if not AiUtility.isClientPlanting and player:m_bIsDefusing() == 0 then
            return AiPriority.EVADE_ACTIVE
        end
    end

    -- We fired an AWP or Scout.
    if self.shotBoltActionRifleTimer:isNotElapsed(1) then
        return AiPriority.EVADE_ACTIVE
    end

    -- We're reloading.
    if player:isReloading() and player:getReloadProgress() < 0.66 then
        return AiPriority.EVADE_ACTIVE
    end

    -- We're switching weapons.
    if (Time.getCurtime() - player:m_flNextAttack()) <= 0
        and player:getWeapon().classname ~= "CC4"
    then
        return AiPriority.EVADE_ACTIVE
    end

    -- We're avoiding a flash.
    if self.ai.flashbang then
        return AiPriority.EVADE_ACTIVE
    end

    local eyeOrigin = Client.getEyeOrigin()
    local isCheckingSmokes = true

    if AiUtility.plantedBomb and AiUtility.bombDetonationTime < 15 then
        isCheckingSmokes = false
    end

    -- Avoid grenades.
    for _, grenade in Entity.find({"CBaseCSGrenadeProjectile", "CMolotovProjectile"}) do
        if eyeOrigin:getDistance(grenade:m_vecOrigin()) < 128 then
            return AiPriority.EVADE_ACTIVE
        end
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateEvade:activate()
    self:moveToCover()
end

--- @return void
function AiStateEvade:think()
    self.activity = "Seeking cover"
    self.ai.canUseGear = false

    if not self.isLookingAtPathfindingDirection then
        if AiUtility.clientThreatenedFromOrigin then
            View.lookAtLocation(AiUtility.clientThreatenedFromOrigin, 2.5, View.noise.minor, "Evade look at threat origin")
        elseif  View.lastLookAtLocationOrigin then
            View.lookAtLocation( View.lastLookAtLocationOrigin, 2.5, View.noise.minor, "Evade look at last spot")
        end
    end

    if Pathfinder.isIdle() then
        self:moveToCover()
    end
end

--- @return void
function AiStateEvade:moveToCover()
    local cover = self:getCoverNode(750, AiUtility.clientThreatenedBy)

    if not cover then
        return
    end

    Pathfinder.moveToNode(cover, {
        task = "Move to cover",
        isAllowedToTraverseInactives = true
    })
end

return Nyx.class("AiStateEvade", AiStateEvade, AiStateBase)
--}}}
