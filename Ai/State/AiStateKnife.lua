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
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
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

        local eyeOrigin = LocalPlayer.getEyeOrigin()
        local rayIntersection = eyeOrigin:getRayClosestPoint(e.shooter:getEyeOrigin(), e.origin)

        -- The enemy shot near us.
        if eyeOrigin:getDistance(rayIntersection) < 200 then
            self:reset()
        end
    end)
end

--- @return void
function AiStateKnife:getAssessment()
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

    self.ai.routines.manageGear:block()

    if not AiUtility.closestEnemy then
        self.activity = "Hunting for enemies"

        if Pathfinder.isIdle() then
            self:pathfindToMiddle()
        end

        return
    end

    self.activity = "Going to knife enemy"

    local clientOrigin = LocalPlayer:getOrigin()
    local targetOrigin = AiUtility.closestEnemy:getOrigin()

    if AiUtility.visibleEnemies[AiUtility.closestEnemy.eid] then
        VirtualMouse.lookAtLocation(targetOrigin:clone():offset(0, 0, 64), 4, VirtualMouse.noise.minor, "Knife look at enemy")
    end

    if clientOrigin:getDistance2(targetOrigin) < 100 then
        local traceRun = Trace.getHullToPosition(
            LocalPlayer.getEyeOrigin(),
            AiUtility.closestEnemy:getEyeOrigin(),
            Vector3:newBounds(Vector3.align.CENTER, 8),
            AiUtility.traceOptionsPathfinding,
            "AiStateKnife.think<FindPathableEnemy>"
        )

        if not traceRun.isIntersectingGeometry then
            Pathfinder.moveAtAngle(clientOrigin:getAngle(targetOrigin), true)
        end
    end

    if not self.isPathfindingToTarget then
        self.isPathfindingToTarget = true
        self.lastTargetOrigin = targetOrigin

        self:pathfindToEnemy()
    elseif targetOrigin:getDistance(self.lastTargetOrigin) > 150 then
        self.lastTargetOrigin = targetOrigin

        self:pathfindToEnemy()
    end

    Pathfinder.ifIdleThenRetryLastRequest()
end

--- @return void
function AiStateKnife:pathfindToEnemy()
    local origin

    if self.isScared then
        local node = Nodegraph.getRandom(Node.traverseGeneric, AiUtility.closestEnemy:getOrigin(), 400)

        if node then
            origin = node.origin
        end
    end

    if origin then
        Pathfinder.moveToLocation(origin, {
            task = "Knife target (scared)"
        })
    else
        local targetOrigin = AiUtility.closestEnemy:getOrigin():offset(0, 0, 18)

        Pathfinder.moveToLocation(targetOrigin, {
            task = "Knife target",
            isPathfindingToNearestNodeOnFailure = true
        })
    end
end

--- @return void
function AiStateKnife:pathfindToMiddle()
    Pathfinder.moveToNode(Nodegraph.getOne(Node.objectiveMiddle), {
        task = "Go to middle",
        goalReachedRadius = 300,
        onReachedGoal = function()
        	self:pathfindSweepMap()
        end
    })
end

--- @return void
function AiStateKnife:pathfindSweepMap()
    Pathfinder.moveToNode(Nodegraph.getRandom(Node.traverseGeneric), {
        task = "Find an enemy",
        goalReachedRadius = 200
    })
end

return Nyx.class("AiStateKnife", AiStateKnife, AiStateBase)
--}}}
