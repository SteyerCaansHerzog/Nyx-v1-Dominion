--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
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
    }
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
function AiStateDefuse:assess()
    -- Only CTs can defuse.
    if not LocalPlayer:isCounterTerrorist() then
        return AiPriority.IGNORE
    end

    local bomb = AiUtility.plantedBomb

    -- No bomb to defuse.
    if not bomb then
        return AiPriority.IGNORE
    end

    -- Can't defuse if we're not already on the bomb.
    if not AiUtility.canDefuse and not LocalPlayer:m_bIsDefusing() == 1 then
        return AiPriority.IGNORE
    end

    -- Bomb's already defused.
    if bomb:m_bBombDefused() == 1 then
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
    if clientDistanceToBomb < 80 then
        for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
            if clientOrigin:getDistance(smoke:m_vecOrigin()) < 100 then
                return AiPriority.DEFUSE_COVERED
            end
        end
    end

    -- We're close to the bomb and covered.
    if clientDistanceToBomb < 200 and isCovered then
        return AiPriority.DEFUSE_ACTIVE
    end

    -- We're not threatened, but time is running out.
    if not AiUtility.isClientThreatened and AiUtility.bombDetonationTime < 15 then
        return AiPriority.DEFUSE_ACTIVE
    end

    return AiPriority.DEFUSE_PASSIVE
end

--- @return void
function AiStateDefuse:activate()
    local bomb = AiUtility.plantedBomb

    if not bomb then
        return
    end

    local bombOrigin = bomb:m_vecOrigin()

    Pathfinder.moveToLocation(bombOrigin, {
        task = "Defuse the bomb",
        isAllowedToTraverseSmokes = true
    })
end

--- @return void
function AiStateDefuse:deactivate() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDefuse:think(cmd)
    local bomb = AiUtility.plantedBomb

    if not bomb then
        return
    end

    self.activity = "Retaking bombsite"

    local bombOrigin = bomb:m_vecOrigin()
    local distance = LocalPlayer:getOrigin():getDistance(bombOrigin)

    if distance < 64 then
        View.isCrosshairUsingVelocity = false

        self.isDefusing = true
    else
        self.isDefusing = false
    end

    if LocalPlayer:m_bIsDefusing() == 1 then
        View.lookAlongAngle(Client.getCameraAngles(), 4, View.noise.none, "Defuse keep current angles")
    elseif distance < 256 then
       View.lookAtLocation(bombOrigin:clone():offset(5, -3, 14), 4.5, View.noise.moving, "Defuse look at bomb")
    end

    if self.isDefusing then
        self.activity = "Defusing the bomb"

        self.ai.canReload = false
        cmd.in_use = true

        Pathfinder.duck()

        if LocalPlayer:hasWeapon(Weapons.SMOKE)
            and Table.isEmpty(AiUtility.visibleEnemies)
            and (not AiUtility.closestEnemy or (AiUtility.closestEnemy and LocalPlayer:getOrigin():getDistance(AiUtility.closestEnemy:getOrigin()) > 400))
        then
            self.ai.routines.manageGear:block()

            self.ai.states.evade:block()

            if not LocalPlayer:isHoldingWeapon(Weapons.SMOKE) then
                LocalPlayer.equipSmoke()
            end

           View.lookAtLocation(bombOrigin:clone():offset(5, -3, -64), 4.5, View.noise.moving, "Defuse look to drop smoke")

            if LocalPlayer:isAbleToAttack() then
                if Client.getCameraAngles().p > 22 then
                    self.inThrowTimer:ifPausedThenStart()
                end

                if self.inThrowTimer:isElapsedThenStop(0.1) then
                    cmd.in_attack2 = true
                end
            end
        end
    end

    Pathfinder.ifIdleThenRetryLastRequest()
end

return Nyx.class("AiStateDefuse", AiStateDefuse, AiStateBase)
--}}}
