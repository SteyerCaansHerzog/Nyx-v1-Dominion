--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStatePatrol
--- @class AiStatePatrol : AiStateBase
--- @field patrolOrigin Vector3
--- @field isBeginningPatrol boolean
--- @field isOnPatrol boolean
--- @field patrolNode NodeTypeTraverse
--- @field patrollingOnBehalfOf Player
--- @field hasNotifiedTeamOfBomb boolean
--- @field cooldownTimer Timer
--- @field isAtPatrolArea boolean
local AiStatePatrol = {
    name = "Patrol",
    patrolRadius = 512
}

--- @param fields AiStatePatrol
--- @return AiStatePatrol
function AiStatePatrol:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStatePatrol:__init()
    self.cooldownTimer = Timer:new():startThenElapse()

    Callbacks.roundStart(function()
    	self:reset()
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isLocalPlayer() then
            self:reset()
        end

        if self.patrollingOnBehalfOf and e.victim:is(self.patrollingOnBehalfOf) then
            self:reset()
        end
    end)
end

--- @param origin Vector3
--- @param player Player
--- @return void
function AiStatePatrol:invoke(origin, player)
    self:reset()

    self.patrolOrigin = origin
    self.isBeginningPatrol = true
    self.patrollingOnBehalfOf = player

    self:queueForReactivation()
end

--- @return void
function AiStatePatrol:assess()
    if AiUtility.isRoundOver then
        return AiPriority.IGNORE
    end

    local bomb = AiUtility.bomb

    if LocalPlayer:isCounterTerrorist() and bomb and not self.hasNotifiedTeamOfBomb then
        local bombOrigin = bomb:m_vecOrigin()
        local nearestBombsite = Nodegraph.getClosestBombsite(bombOrigin)

        if bombOrigin:getDistance(nearestBombsite.origin) > 1500 then
            local eyeOrigin = LocalPlayer:getEyeOrigin()
            local trace = Trace.getLineToPosition(eyeOrigin, bombOrigin, AiUtility.traceOptionsAttacking, "AiStatePatrol.assess<FindBomb>")

            if not trace.isIntersectingGeometry then
                self:invoke(bombOrigin, LocalPlayer)

                return AiPriority.PATROL_BOMB
            end
        end
    end

    if self.isBeginningPatrol or self.isOnPatrol then
        if not self.isAtPatrolArea and LocalPlayer:getOrigin():getDistance(self.patrolOrigin) > 1000 then
            return AiPriority.PATROL_MOVE_TO_ZONE
        else
            return AiPriority.PATROL
        end
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStatePatrol:activate()
    self:move()
end

--- @return void
function AiStatePatrol:reset()
    self.isBeginningPatrol = false
    self.isOnPatrol = false
    self.patrolNode = nil
    self.hasNotifiedTeamOfBomb = false
    self.hasFoundBomb = false
    self.isAtPatrolArea = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStatePatrol:think(cmd)
    self.activity = "Going to patrol area"

    if self.priority == AiPriority.PATROL_BOMB then
        if not self.hasNotifiedTeamOfBomb then
            local bomb = AiUtility.bomb

            if bomb then
                local bombOrigin = bomb:m_vecOrigin()

               View.lookAtLocation(bombOrigin, 4, View.noise.minor, "Patrol look at bomb")

                local deltaAngles = LocalPlayer.getEyeOrigin():getAngle(bombOrigin):getAbsDiff(LocalPlayer.getCameraAngles())

                if deltaAngles.p < 20 and deltaAngles.y < 20 then
                    self.hasNotifiedTeamOfBomb = true

                    if not AiUtility.isLastAlive and self.cooldownTimer:isElapsedThenRestart(25) then
                        self.ai.commands.assist:bark()

                       self.ai.voice.pack:speakNotifyTeamOfBomb()
                    end
                end
            end
        end
    end

    if self.isBeginningPatrol or Pathfinder.isIdle() then
        self:move()
    end

    if self.isOnPatrol then
        local origin = LocalPlayer:getOrigin()

        if origin:getDistance(self.patrolOrigin) < 1024 then
            self.isAtPatrolArea = true
            self.activity = "Patrolling area"

            Pathfinder.walk()

            self.ai.routines.manageGear:block()

            LocalPlayer.equipAvailableWeapon()
        end
    end
end

--- @return void
function AiStatePatrol:move()
    self.isBeginningPatrol = false
    self.isOnPatrol = true
    self.isAtPatrolArea = false

    self.patrolNode = self:getPatrolNode()

    if not self.patrolNode then
        self.isOnPatrol = false

        return
    end

    Pathfinder.moveToNode(self.patrolNode, {
        task = "Patrol area",
        onReachedGoal = function()
        	self.isBeginningPatrol = true
        end
    })
end

--- @return NodeTypeTraverse
function AiStatePatrol:getPatrolNode()
    return Nodegraph.getRandom(Node.traverseGeneric, self.patrolOrigin, self.patrolRadius)
end

return Nyx.class("AiStatePatrol", AiStatePatrol, AiStateBase)
--}}}
