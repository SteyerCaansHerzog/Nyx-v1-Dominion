--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
--}}}

--{{{ AiStateZombie
--- @class AiStateZombie : AiState
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
    if not AiUtility.client:isTerrorist() then
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

    Menu.autoKnifeRef:set(true)
end

--- @return void
function AiStateZombie:deactivate()
    Menu.autoKnifeRef:set(false)
end

--- @return void
function AiStateZombie:reset()
    self.isActive = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateZombie:think(cmd)
    Client.equipKnife()

    self.ai.canUseGear = false

    if not AiUtility.closestEnemy then
        self.activity = "Hunting for prey"

        if self.ai.nodegraph:isIdle() then
            self:pathfindSweepMap()
        end

        return
    end

    self.activity = "Attacking prey"

    local clientOrigin = Client.getOrigin()
    local targetOrigin = AiUtility.closestEnemy:getOrigin()

    if AiUtility.visibleEnemies[AiUtility.closestEnemy.eid] then
        self.ai.view:lookAtLocation(targetOrigin:clone():offset(0, 0, 64), 4, self.ai.view.noiseType.MINOR, "Zombie look at enemy")
    end

    if clientOrigin:getDistance2(targetOrigin) < 350 then
        local traceRun = Trace.getHullToPosition(
            Client.getEyeOrigin(),
            AiUtility.closestEnemy:getEyeOrigin(),
            Vector3:newBounds(Vector3.align.CENTER, 8),
            AiUtility.traceOptionsPathfinding,
            "AiStateZombie.think<FindPathableEnemy>"
        )

        local traceJump = Trace.getHullToPosition(
            Client.getEyeOrigin(),
            targetOrigin:offset(0, 0, 32),
            Vector3:newBounds(Vector3.align.CENTER, 16),
            AiUtility.traceOptionsPathfinding,
            "AiStateZombie.think<FindPathableEnemy>"
        )

        if not traceRun.isIntersectingGeometry then
            self.ai.nodegraph.moveAngle = clientOrigin:getAngle(targetOrigin)
        end

        if traceJump.isIntersectingGeometry then
            if AiUtility.client:m_vecVelocity():getMagnitude() < 100 then
                local zDelta = clientOrigin.z - targetOrigin.z

                if zDelta < -32 then
                    cmd.in_jump = 1
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

    if self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:rePathfind()
    end
end

--- @return void
function AiStateZombie:pathfindToEnemy()
    local targetOrigin = AiUtility.closestEnemy:getOrigin():offset(0, 0, 18)

    self.ai.nodegraph:pathfind(targetOrigin, {
        task = "Knife enemy player",
        onFail = function()
            self.ai.nodegraph:pathfind(self.ai.nodegraph:getClosestNode(targetOrigin).origin, {
                task = "Knife enemy player"
            })
        end
    })
end

--- @return void
function AiStateZombie:pathfindSweepMap()
    self.ai.nodegraph:pathfind(self.ai.nodegraph:getRandomNodeWithin(Vector3:new(), Vector3.MAX_DISTANCE).origin, {
        task = "Find an enemy"
    })
end

return Nyx.class("AiStateZombie", AiStateZombie, AiState)
--}}}
