--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiThreats = require "gamesense/Nyx/v1/Dominion/Ai/AiThreats"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateDefuse
--- @class AiStateDefuse : AiStateBase
--- @field isDefusing boolean
--- @field lookAtOffset Vector3
--- @field inThrowTimer Timer
local AiStateDefuse = {
    name = "Defuse",
    delayedMouseMin = 0.1,
    delayedMouseMax = 0.4,
    requiredGamemodes = {
        AiUtility.gamemodes.DEMOLITION,
        AiUtility.gamemodes.WINGMAN,
    },
    isLockable = false
}

--- @param fields AiStateDefuse
--- @return AiStateDefuse
function AiStateDefuse:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDefuse:__init()
    self.inThrowTimer = Timer:new()
    self.lookAtOffset = Vector3:newRandom(-16, 16)

    Callbacks.roundStart(function()
        self.lookAtOffset = Vector3:newRandom(-16, 16)
    end)
end

--- @return void
function AiStateDefuse:getAssessment()
    -- Only CTs can defuse.
    if not LocalPlayer:isCounterTerrorist() then
        return AiPriority.IGNORE
    end

    local bomb = AiUtility.plantedBomb

    -- No bomb to defuse.
    if not bomb then
        return AiPriority.IGNORE
    end

    -- No time left and we haven't started defusing.
    if not AiUtility.canDefuse and not LocalPlayer:m_bIsDefusing() == 1 then
        return AiPriority.IGNORE
    end

    -- Bomb's already defused.
    if AiUtility.isBombDefused() then
        return AiPriority.IGNORE
    end

    -- A teammate is on the bomb.
    if AiUtility.isBombBeingDefusedByTeammate then
        return AiPriority.IGNORE
    end

    local defuseTime = LocalPlayer:m_bHasDefuser() == 1 and 5 or 10

    -- We might as well stick the defuse if we have 1 second left.
    if AiUtility.defuseTimer:isElapsed(defuseTime - 1) then
        return AiPriority.DEFUSE_STICK
    end

    local clientOrigin = LocalPlayer:getOrigin()
    local isCovered = false
    local bombOrigin = AiUtility.plantedBomb:m_vecOrigin()

    for _, teammate in pairs(AiUtility.teammates) do
        local teammateOrigin = teammate:getOrigin()

        if clientOrigin:getDistance(teammateOrigin) < 512 then
            isCovered = true
        end
    end

    -- We're covered by a teammate.
    if LocalPlayer:m_bIsDefusing() == 1 and isCovered then
        return AiPriority.DEFUSE_COVERED
    end

    local clientDistanceToBomb = clientOrigin:getDistance(bombOrigin)

    -- We're in a smoke.
    if clientDistanceToBomb < 100 and self.ai.routines.handleOccluderTraversal.smokeInsideOf then
        return AiPriority.DEFUSE_COVERED
    end

    -- Safe to defuse.
    if not AiUtility.closestEnemy then
        return AiPriority.DEFUSE_ACTIVE
    end

    -- Enemy is far away and isn't a threat to us.
    if AiThreats.threatLevel < AiThreats.threatLevels.HIGH and AiUtility.closestEnemy and AiUtility.closestEnemy:getOrigin():getDistance(bombOrigin) > 1500 then
        return AiPriority.DEFUSE_ACTIVE
    end

    -- We're close to the bomb and covered.
    if clientDistanceToBomb < 200 and isCovered then
        return AiPriority.DEFUSE_ACTIVE
    end

    -- We're not threatened, but time is running out.
    if AiThreats.threatLevel <= AiThreats.threatLevels.MEDIUM and AiUtility.bombDetonationTime < 15 then
        return AiPriority.DEFUSE_ACTIVE
    end

    return AiPriority.DEFUSE_PASSIVE
end

--- @return void
function AiStateDefuse:activate()
    if not AiUtility.plantedBomb then
        return
    end

    Pathfinder.moveToLocation(AiUtility.plantedBomb:m_vecOrigin(), {
        task = "Defuse the bomb",
    })
end

--- @return void
function AiStateDefuse:deactivate() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDefuse:think(cmd)
	if not AiUtility.plantedBomb then
		return
	end

	local bombsite = Nodegraph.getClosestBombsiteName(AiUtility.plantedBomb:m_vecOrigin())

    self.activity = string.format("Retaking bombsite %s", bombsite)

    local bombOrigin = AiUtility.plantedBomb:m_vecOrigin()
    local distance = LocalPlayer:getOrigin():getDistance(bombOrigin)

    if distance < 64 then
        VirtualMouse.isCrosshairUsingVelocity = false

        self.isDefusing = true
    else
        self.isDefusing = false
    end

    if LocalPlayer:m_bIsDefusing() == 1 then
        VirtualMouse.lookAlongAngle(LocalPlayer.getCameraAngles(), 4, VirtualMouse.noise.none, "Defuse keep current angles")
    elseif distance < 256 then
       VirtualMouse.lookAtLocation(bombOrigin:clone():offset(5, -3, 14), 4.5, VirtualMouse.noise.moving, "Defuse look at bomb")
    end

    if self.isDefusing then
        self.activity = string.format("Defusing bomb on %s", bombsite)

        self.ai.routines.manageWeaponReload:block()

        Pathfinder.blockTeammateAvoidance()

        cmd.in_use = true

        if AiUtility.enemiesAlive > 0 then
            Pathfinder.duck()
        end

        if LocalPlayer:hasWeapon(Weapons.SMOKE)
            and AiUtility.enemiesAlive > 0
            and Table.isEmpty(AiUtility.visibleEnemies)
            and (not AiUtility.closestEnemy or (AiUtility.closestEnemy and LocalPlayer:getOrigin():getDistance(AiUtility.closestEnemy:getOrigin()) > 400))
        then
            LocalPlayer.equipSmoke()

            self:dropGrenade(cmd)
        end

        if not LocalPlayer:hasWeapon(Weapons.SMOKE)
            and self.ai.routines.handleOccluderTraversal.smokeInsideOf
            and LocalPlayer:hasWeapon(Weapons.FLASHBANG)
            and AiUtility.enemiesAlive > 0
            and Table.isEmpty(AiUtility.visibleEnemies)
            and (not AiUtility.closestEnemy or (AiUtility.closestEnemy and LocalPlayer:getOrigin():getDistance(AiUtility.closestEnemy:getOrigin()) > 400))
        then
            LocalPlayer.equipFlashbang()

            self:dropGrenade(cmd)
        end
    end

    Pathfinder.ifIdleThenRetryLastRequest()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDefuse:dropGrenade(cmd)
    self.ai.routines.manageGear:block()
    self.ai.states.evade:block()

    VirtualMouse.lookAtLocation(AiUtility.plantedBomb:m_vecOrigin():clone():offset(5, -3, -64), 6, VirtualMouse.noise.moving, "Defuse look to drop smoke")

    if LocalPlayer:isAbleToAttack() then
        if LocalPlayer.getCameraAngles().p > 22 then
            self.inThrowTimer:ifPausedThenStart()
        end

        if self.inThrowTimer:isElapsedThenStop(0.1) then
            cmd.in_attack2 = true
        end
    end
end

return Nyx.class("AiStateDefuse", AiStateDefuse, AiStateBase)
--}}}
