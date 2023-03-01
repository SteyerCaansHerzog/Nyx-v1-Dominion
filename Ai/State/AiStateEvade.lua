--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiThreats = require "gamesense/Nyx/v1/Dominion/Ai/AiThreats"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateEvade
--- @class AiStateEvade : AiStateBase
--- @field changeAngleTime number
--- @field changeAngleTimer Timer
--- @field evadeLookAtAngles Vector3
--- @field hurtTimer Timer
--- @field isFirstJumpEvasion boolean
--- @field isHurt boolean
--- @field isJumpEvasionActive boolean
--- @field isLookingAtPathfindingDirection boolean
--- @field jumpEvasionAngle Angle
--- @field jumpEvasionCooldownTimer Timer
--- @field jumpEvasionMethod fun(self: AiStateEvade, cmd: SetupCommandEvent): void
--- @field node Node
--- @field shotBoltActionRifleTimer Timer
local AiStateEvade = {
    name = "Evade",
    isLockable = false
}

--- @param fields AiStateEvade
--- @return AiStateEvade
function AiStateEvade:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateEvade:__init()
    self.shotBoltActionRifleTimer = Timer:new():startThenElapse()
    self.evadeLookAtAngles = LocalPlayer.getCameraAngles()
    self.changeAngleTimer = Timer:new():startThenElapse()
    self.changeAngleTime = 1
    self.hurtTimer = Timer:new():startThenElapse()
    self.jumpEvasionCooldownTimer = Timer:new():startThenElapse()

    Callbacks.weaponFire(function(e)
        if e.player:isLocalPlayer() and e.player:isHoldingBoltActionRifle() then
            self.shotBoltActionRifleTimer:start()
        end
    end)

    Callbacks.playerHurt(function(e)
        if e.victim:isLocalPlayer() and e.health < 20 then
            self.hurtTimer:start()
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

    -- We can't be peeked by an enemy.
    if AiThreats.threatLevel < AiThreats.threatLevels.EXTREME then
        return AiPriority.IGNORE
    end

    -- We're flashed.
    if LocalPlayer.isFlashed() then
        if not AiUtility.isClientPlanting and LocalPlayer:m_bIsDefusing() == 0 then
            return AiPriority.EVADE_ACTIVE
        end
    end

    -- We fired an AWP or Scout.
    if not self.shotBoltActionRifleTimer:isElapsed(1) then
        return AiPriority.EVADE_ACTIVE
    end

    -- We're reloading.
    if LocalPlayer:isReloading() and LocalPlayer:getReloadProgress() < 0.66 then
        return AiPriority.EVADE_ACTIVE
    end

    -- We're switching weapons.
    if LocalPlayer:getNextAttackProgress() > 1
        and LocalPlayer:getWeapon().classname ~= "CC4"
    then
        return AiPriority.EVADE_ACTIVE
    end

    -- We're avoiding a flash.
    if self.ai.flashbang then
        return AiPriority.EVADE_ACTIVE
    end

    local eyeOrigin = LocalPlayer.getEyeOrigin()

    -- Retreat due to injury.
    if not AiUtility.plantedBomb and not LocalPlayer.isCarryingBomb() and not self.hurtTimer:isElapsed(4) and AiUtility.timeData.roundtime_remaining > 40 then
        self.isLookingAtPathfindingDirection = true

        return AiPriority.EVADE_PASSIVE
    end

    -- Avoid grenades.
    for _, grenade in Entity.find({"CBaseCSGrenadeProjectile", "CMolotovProjectile"}) do repeat
        if eyeOrigin:getDistance(grenade:m_vecOrigin()) > 128 then
            break
        end

        return AiPriority.EVADE_PASSIVE
    until true end

    return AiPriority.IGNORE
end

--- @return void
function AiStateEvade:activate()
    self.jumpEvasionAngle = nil
    self.isFirstJumpEvasion = true

    self:moveToCover()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEvade:think(cmd)
    self.activity = "Seeking cover"

    self.ai.routines.manageGear:block()

    if not self.isLookingAtPathfindingDirection then
        if AiUtility.clientThreatenedFromOrigin then
            VirtualMouse.lookAtLocation(AiUtility.clientThreatenedFromOrigin, 2.5, VirtualMouse.noise.minor, "Evade look at threat origin")
        elseif VirtualMouse.lastLookAtLocationOrigin then
            VirtualMouse.lookAtLocation( VirtualMouse.lastLookAtLocationOrigin, 2.5, VirtualMouse.noise.minor, "Evade look at last spot")
        end
    end

    if Pathfinder.isIdle() then
        self:moveToCover()
    end

    self:moveJumpEvasion(cmd)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEvade:moveJumpEvasion(cmd)
    if LocalPlayer:isAbleToAttack() then
        return
    end

    if LocalPlayer:getNextAttackProgress() < 0.35 then
        return
    end

    if not AiUtility.isEnemyVisible then
        return
    end

    local isEnemyLookingAtClient = false
    local eyeOrigin = LocalPlayer.getEyeOrigin()

    for _, enemy in pairs(AiUtility.visibleEnemies) do
        local fov = enemy:getCameraAngles():getFov(enemy:getEyeOrigin(), eyeOrigin)

        if fov < AiUtility.visibleFovThreshold then
            isEnemyLookingAtClient = true

            break
        end
    end

    if not isEnemyLookingAtClient then
        return
    end

    self.ai.routines.walk:block()

    if LocalPlayer:m_vecVelocity():getMagnitude() > 165 and self.jumpEvasionCooldownTimer:isElapsedThenRestart(0.75) then
        if not Math.getChance(3) then
            self.jumpEvasionMethod = nil
        else
            if self.isFirstJumpEvasion then
                -- Duplicated because easy weighted random.
                self.jumpEvasionMethod = Table.getRandom({
                    AiStateEvade.jumpEvasionForward,
                    AiStateEvade.jumpEvasionForward,
                    AiStateEvade.jumpEvasionBackward,
                    AiStateEvade.jumpEvasionSimple
                })
            else
                self.jumpEvasionMethod = AiStateEvade.jumpEvasionSimple
            end
        end

        self.isFirstJumpEvasion = false
        cmd.in_jump = true
    end

    if not self.jumpEvasionMethod or LocalPlayer:isFlagActive(Player.flags.FL_ONGROUND) then
        return
    end

    if not self.jumpEvasionAngle then
        self.jumpEvasionAngle = LocalPlayer.getCameraAngles()
    end


    Pathfinder.blockMovement()
    VirtualMouse.block()

    self.jumpEvasionMethod(self, cmd)

    VirtualMouse.viewAngles = self.jumpEvasionAngle
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEvade:jumpEvasionBackward(cmd)
    self.jumpEvasionAngle:offset(0, 8)

    cmd.in_right = true -- todo incorrect param
    cmd.sidemove = 450
    cmd.in_back = true
    cmd.forwardmove = -450
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEvade:jumpEvasionForward(cmd)
    self.jumpEvasionAngle:offset(0, 8)

    cmd.in_left = true -- todo incorrect param
    cmd.sidemove = -450
    cmd.in_forward = true
    cmd.forwardmove = 450
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEvade:jumpEvasionSimple(cmd)
    cmd.in_back = true
    cmd.forwardmove = -450
end

--- @return void
function AiStateEvade:moveToCover()
    local cover = self:getCoverNode(800, AiThreats.highestThreat, 135)

    if not cover then
        return
    end

    Pathfinder.moveToNode(cover, {
        task = "Move to cover",
        isAllowedToTraverseInactives = true,
    })
end

return Nyx.class("AiStateEvade", AiStateEvade, AiStateBase)
--}}}
