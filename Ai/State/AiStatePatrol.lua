--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiRadio = require "gamesense/Nyx/v1/Dominion/Ai/AiRadio"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStatePatrol
--- @class AiStatePatrol : AiState
--- @field patrolOrigin Vector3
--- @field isBeginningPatrol boolean
--- @field isOnPatrol boolean
--- @field patrolNode Node
--- @field patrollingOnBehalfOf Player
--- @field hasNotifiedTeamOfBomb boolean
--- @field cooldownTimer Timer
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
        if e.victim:isClient() then
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
function AiStatePatrol:beginPatrol(origin, player)
    self:reset()

    self.patrolOrigin = origin
    self.isBeginningPatrol = true
    self.patrollingOnBehalfOf = player
end

--- @return void
function AiStatePatrol:assess()
    if AiUtility.isRoundOver then
        return AiState.priority.IGNORE
    end

    local bomb = AiUtility.bomb

    if AiUtility.client:isCounterTerrorist() and bomb and not self.hasNotifiedTeamOfBomb then
        local eyeOrigin = AiUtility.client:getEyeOrigin()
        local bombOrigin = bomb:m_vecOrigin()
        local _, _, eid = eyeOrigin:getTraceLine(bombOrigin, Client.getEid())

        if eid == bomb.eid then
            self:beginPatrol(bombOrigin, AiUtility.client)

            return AiState.priority.PATROL_BOMB
        end
    end

    return (self.isBeginningPatrol or self.isOnPatrol) and AiState.priority.PATROL or AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStatePatrol:activate(ai)
    ai.radio:speak(ai.radio.message.AGREE, 1, 1, 2, "I'm %sassisting%s you.", ai.radio.color.YELLOW, ai.radio.color.DEFAULT)
end

--- @return void
function AiStatePatrol:reset()
    self.isBeginningPatrol = false
    self.isOnPatrol = false
    self.patrolNode = nil
    self.hasNotifiedTeamOfBomb = false
    self.hasFoundBomb = false
end

--- @param ai AiOptions
--- @return void
function AiStatePatrol:think(ai)
    if ai.priority == AiState.priority.PATROL_BOMB then
        if not self.hasNotifiedTeamOfBomb then
            local bomb = AiUtility.bomb

            if bomb then
                local bombOrigin = bomb:m_vecOrigin()

                ai.view:lookAtLocation(bombOrigin, 6)

                local deltaAngles = Client.getEyeOrigin():getAngle(bombOrigin):getAbsDiff(Client.getCameraAngles())

                if deltaAngles.p < 20 and deltaAngles.y < 20 then
                    self.hasNotifiedTeamOfBomb = true

                    if not AiUtility.isLastAlive and self.cooldownTimer:isElapsedThenRestart(25) then

                        Messenger.send(" assist", true)

                        ai.voice.pack:speakNotifyTeamOfBomb()
                    end
                end
            end
        end
    end

    if self.isBeginningPatrol or not ai.nodegraph.path then
        self.isBeginningPatrol = false
        self.isOnPatrol = true

        self.patrolNode = self:getPatrolNode(ai)

        if not self.patrolNode then
            self.isOnPatrol = false

            return
        end

        ai.nodegraph:pathfind(self.patrolNode.origin, {
            objective = Node.types.GOAL,
            ignore = Client.getEid(),
            task = string.format("Patrolling"),
            onComplete = function()
                self.isBeginningPatrol = true
            end
        })
    end

    if self.isOnPatrol then
        local player = AiUtility.client
        local origin = player:getOrigin()

        if origin:getDistance(self.patrolOrigin) < 1024 then
            ai.controller.isWalking = true
            ai.controller.canUseKnife = false
        end
    end
end

--- @param ai AiOptions
--- @return Node
function AiStatePatrol:getPatrolNode(ai)
    local player = AiUtility.client
    local origin = player:getOrigin()
    local filterOrigin = self.patrolOrigin

    local filterNodes = {}

    for _, node in pairs(ai.nodegraph.nodes) do
        if origin:getDistance(node.origin) > 256 and filterOrigin:getDistance(node.origin) < 512 then
            table.insert(filterNodes, node)
        end
    end

    return Table.getRandom(filterNodes, Node)
end

return Nyx.class("AiStatePatrol", AiStatePatrol, AiState)
--}}}
