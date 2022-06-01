--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
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
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateKnife
--- @class AiStateKnife : AiStateBase
--- @field isActive boolean
--- @field isScared boolean
--- @field isCommitted boolean
--- @field isPathfindingToTarget boolean
--- @field lastTargetOrigin Vector3
local AiStateKnife = {
    name = "Knife"
}

--- @param fields AiStateKnife
--- @return AiStateKnife
function AiStateKnife:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateKnife:__init()
    Callbacks.roundStart(function()
    	self:reset()
    end)

    Callbacks.playerDeath(function(e)
        if not self.isActive then
            return
        end

        -- Enemy killed one of us with something other than a knife, so all bets are off.
        if e.victim:isTeammate() and not e.attacker:isHoldingKnife() then
            self:reset()
        end
    end)

    Callbacks.bulletImpact(function(e)
        if not self.isActive then
            return
        end

        if not e.shooter:isEnemy() then
            return
        end

        if e.shooter:isHoldingKnife() then
            return
        end

        local eyeOrigin = Client.getEyeOrigin()
        local rayIntersection = eyeOrigin:getRayClosestPoint(e.shooter:getEyeOrigin(), e.origin)

        -- The enemy shot near us.
        if eyeOrigin:getDistance(rayIntersection) < 200 then
            self:reset()
        end
    end)
end

--- @return void
function AiStateKnife:assess()
    if AiUtility.plantedBomb then
        return AiPriority.IGNORE
    end

    if AiUtility.enemiesAlive == 0 then
        return AiPriority.IGNORE
    end

    if AiUtility.isRoundOver then
        return AiPriority.IGNORE
    end

    if not self.isActive then
        return AiPriority.IGNORE
    end

    return AiPriority.KNIFE
end

--- @return void
function AiStateKnife:activate()
    self.isPathfindingToTarget = false

    MenuGroup.autoKnifeRef:set(true)
end

--- @return void
function AiStateKnife:deactivate()
    MenuGroup.autoKnifeRef:set(false)
end

--- @return void
function AiStateKnife:reset()
    self.isActive = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateKnife:think(cmd)
    LocalPlayer.equipKnife()

    self.ai.canUseGear = false

    if not AiUtility.closestEnemy then
        self.activity = "Hunting for enemies"

        if self.ai.nodegraph:isIdle() then
            self:pathfindToMiddle()
        end

        return
    end

    self.activity = "Going to knife enemy"

    local clientOrigin = Client.getOrigin()
    local targetOrigin = AiUtility.closestEnemy:getOrigin()

    if AiUtility.visibleEnemies[AiUtility.closestEnemy.eid] then
        View.lookAtLocation(targetOrigin:clone():offset(0, 0, 64), 4, View.noise.minor, "Knife look at enemy")
    end

    if clientOrigin:getDistance2(targetOrigin) < 350 then
        local traceRun = Trace.getHullToPosition(
            Client.getEyeOrigin(),
            AiUtility.closestEnemy:getEyeOrigin(),
            Vector3:newBounds(Vector3.align.CENTER, 8),
            AiUtility.traceOptionsPathfinding,
            "AiStateKnife.think<FindPathableEnemy>"
        )

        local traceJump = Trace.getHullToPosition(
            Client.getEyeOrigin(),
            targetOrigin:offset(0, 0, 32),
            Vector3:newBounds(Vector3.align.CENTER, 16),
            AiUtility.traceOptionsPathfinding,
            "AiStateKnife.think<FindPathableEnemy>"
        )

        if not traceRun.isIntersectingGeometry then
            self.ai.nodegraph.moveAngle = clientOrigin:getAngle(targetOrigin)
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

    if self.ai.nodegraph:isIdle() then
        self.ai.nodegraph:rePathfind()
    end
end

--- @return void
function AiStateKnife:pathfindToEnemy()
    local origin

    if self.isScared then
        local node = self.ai.nodegraph:getRandomNodeWithin(AiUtility.closestEnemy:getOrigin(), 600)

        if node then
            origin = node.origin
        end
    end

    if origin then
        self.ai.nodegraph:pathfind(origin, {
            task = "Knife enemy player"
        })
    else
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
end

--- @return void
function AiStateKnife:pathfindToMiddle()
    self.ai.nodegraph:pathfind(self.ai.nodegraph.mapMiddle.origin, {
        task = "Moving to middle",
        onComplete = function()
        	self:pathfindSweepMap()
        end
    })
end

--- @return void
function AiStateKnife:pathfindSweepMap()
    self.ai.nodegraph:pathfind(self.ai.nodegraph:getRandomNodeWithin(Vector3:new(), Vector3.MAX_DISTANCE).origin, {
        task = "Find an enemy"
    })
end

return Nyx.class("AiStateKnife", AiStateKnife, AiStateBase)
--}}}
