--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateZombie
--- @class AiStateZombie : AiStateBase
--- @field isActive boolean
--- @field isPathfindingToTarget boolean
--- @field lastTargetOrigin Vector3
local AiStateZombie = {
    name = "Zombie"
}

--- @param fields AiStateZombie
--- @return AiStateZombie
function AiStateZombie:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateZombie:__init() end

--- @return void
function AiStateZombie:assess()
    if not LocalPlayer:isTerrorist() then
        return AiPriority.IGNORE
    end

    if not self.isActive then
        return AiPriority.IGNORE
    end

    return AiPriority.ZOMBIE
end

--- @return void
function AiStateZombie:activate()
    self.isPathfindingToTarget = false

    MenuGroup.autoKnifeRef:set(true)
end

--- @return void
function AiStateZombie:deactivate()
    MenuGroup.autoKnifeRef:set(false)
end

--- @return void
function AiStateZombie:reset()
    self.isActive = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateZombie:think(cmd)
    Pathfinder.ifIdleThenRetryLastRequest()

    LocalPlayer.equipKnife()

    self.ai.routines.manageGear:block()

    if not AiUtility.closestEnemy then
        self.activity = "Hunting for prey"

        if not Pathfinder.isOnValidPath() then
            self:pathfindSweepMap()
        end

        return
    end

    self.activity = "Attacking prey"

    local clientOrigin = LocalPlayer:getOrigin()
    local targetOrigin = AiUtility.closestEnemy:getOrigin()

    if AiUtility.visibleEnemies[AiUtility.closestEnemy.eid] then
        View.lookAtLocation(targetOrigin:clone():offset(0, 0, 64), 4, View.noise.minor, "Zombie look at enemy")
    end

    if clientOrigin:getDistance2(targetOrigin) < 350 then
        local traceRun = Trace.getHullToPosition(
            LocalPlayer.getEyeOrigin(),
            AiUtility.closestEnemy:getEyeOrigin(),
            Vector3:newBounds(Vector3.align.CENTER, 8),
            AiUtility.traceOptionsPathfinding,
            "AiStateZombie.think<FindPathableEnemy>"
        )

        local traceJump = Trace.getHullToPosition(
            LocalPlayer.getEyeOrigin(),
            targetOrigin:offset(0, 0, 32),
            Vector3:newBounds(Vector3.align.CENTER, 16),
            AiUtility.traceOptionsPathfinding,
            "AiStateZombie.think<FindPathableEnemy>"
        )

        if not traceRun.isIntersectingGeometry then
            Pathfinder.moveAtAngle(clientOrigin:getAngle(targetOrigin))
        end

        if traceJump.isIntersectingGeometry then
            if LocalPlayer:m_vecVelocity():getMagnitude() < 100 then
                local zDelta = clientOrigin.z - targetOrigin.z

                if zDelta < -32 then
                    cmd.in_jump = true
                end
            end

            return
        end
    end

    if not self.isPathfindingToTarget then
        self.isPathfindingToTarget = true
        self.lastTargetOrigin = targetOrigin

        self:pathfindToEnemy()
    elseif targetOrigin:getDistance(self.lastTargetOrigin) > 80 then
        self.lastTargetOrigin = targetOrigin

        self:pathfindToEnemy()
    end
end

--- @return void
function AiStateZombie:pathfindToEnemy()
    Pathfinder.moveToLocation(AiUtility.closestEnemy:getOrigin(), {
        task = "Move to target",
        isPathfindingToNearestNodeOnFailure = true,
        isAllowedToTraverseInactives = true,
    })
end

--- @return void
function AiStateZombie:pathfindSweepMap()
    Pathfinder.moveToNode(Nodegraph.getRandom(Node.traverseGeneric), {
        task = "Find an enemy",
        goalReachedRadius = 100
    })
end

return Nyx.class("AiStateZombie", AiStateZombie, AiStateBase)
--}}}
