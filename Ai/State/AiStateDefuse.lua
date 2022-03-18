--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateDefuse
--- @class AiStateDefuse : AiState
--- @field isDefusing boolean
--- @field lookAtOffset Vector3
--- @field inThrowTimer Timer
local AiStateDefuse = {
    name = "Defuse"
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

    Callbacks.bombPlanted(function()
        Client.fireAfter(0.1, function()
            local player = AiUtility.client
            local playerOrigin = player:getOrigin()
            local bomb = AiUtility.plantedBomb

            if not bomb then
                return
            end

            local nearestSite = self.nodegraph:getNearestSiteName(bomb:m_vecOrigin())
            --- @type Node[]
            local chokes = self.nodegraph[string.format("objective%sChoke", nearestSite:upper())]

            for _, choke in pairs(chokes) do repeat
                if Client.getRandomInt(1, 3) ~= 1 or playerOrigin:getDistance(choke.origin) <= 512 then
                    break
                end

                for _, node in pairs(self.nodegraph.nodes) do
                    if choke.origin:getDistance(node.origin) < 128 then
                        node.active = false
                    end
                end
            until true end

            self.nodegraph:rePathfind()
        end)
    end)
end

--- @return void
function AiStateDefuse:assess()
    local player = AiUtility.client

    if not player:isCounterTerrorist() then
        return AiState.priority.IGNORE
    end

    local bomb = AiUtility.plantedBomb

    if not bomb then
        return AiState.priority.IGNORE
    end

    if bomb:m_bBombDefused() == 1 then
        return AiState.priority.IGNORE
    end

    if AiUtility.isBombBeingDefusedByTeammate then
        return AiState.priority.IGNORE
    end

    local clientOrigin = player:getOrigin()
    local isCovered = false
    local nearestTeammateDistance = math.huge
    local bombOrigin = AiUtility.plantedBomb:m_vecOrigin()

    for _, teammate in pairs(AiUtility.teammates) do
        local teammateOrigin = teammate:getOrigin()

        if clientOrigin:getDistance(teammateOrigin) < 512 then
            isCovered = true
        end

        local teammateDistanceToBomb = teammateOrigin:getDistance(bombOrigin)

        if teammateDistanceToBomb < nearestTeammateDistance then
            nearestTeammateDistance = teammateDistanceToBomb
        end
    end

    local defuseTime = AiUtility.client:m_bHasDefuser() == 1 and 5 or 10

    if AiUtility.defuseTimer:isElapsed(defuseTime - 1) then
        return AiState.priority.DEFUSE_STICK
    end

    if player:m_bIsDefusing() == 1 and clientOrigin:getDistance(bomb:getOrigin()) < 64 and isCovered then
        return AiState.priority.DEFUSE_COVERED
    end

    local clientDistanceToBomb = clientOrigin:getDistance(bombOrigin)

    if clientDistanceToBomb < 80 then
        for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
            if clientOrigin:getDistance(smoke:m_vecOrigin()) < 80 then
                return AiState.priority.DEFUSE_COVERED
            end
        end
    end

    if isCovered and clientDistanceToBomb < 256 and clientDistanceToBomb < nearestTeammateDistance then
        -- todo return AiState.priority.DEFEND_ACTIVE makes them spazz out
    end

    if AiUtility.bombDetonationTime <= 15 then
        return AiState.priority.DEFUSE_EXPEDITE
    end

    return AiState.priority.DEFUSE
end

--- @param ai AiOptions
--- @return void
function AiStateDefuse:activate(ai)
    local bomb = AiUtility.plantedBomb

    if not bomb then
        return
    end

    local bombOrigin = bomb:m_vecOrigin()
    local pathEnd
    local task

    if ai.priority == AiState.priority.DEFEND_DEFUSER then
        pathEnd = Table.getRandom(ai.nodegraph:getVisibleNodesFrom(bombOrigin:clone():offset(0, 0, 128), Client.getEid()), Node).origin
        task = "Defending the defuser"
    else
        pathEnd = bombOrigin
        task = string.format("Retaking %s site", ai.nodegraph:getNearestSiteName(bombOrigin):upper())
    end

    ai.nodegraph:pathfind(pathEnd, {
        objective = Node.types.BOMB,
        ignore = Client.getEid(),
        task = task,
        onComplete = function()
            ai.nodegraph:log("Defusing the bomb")
        end
    })
end

--- @param ai AiOptions
--- @return void
function AiStateDefuse:deactivate(ai)
    ai.nodegraph:reactivateAllNodes()
end

--- @param ai AiOptions
--- @return void
function AiStateDefuse:think(ai)
    local bomb = AiUtility.plantedBomb

    if not bomb then
        return
    end

    local bombOrigin = bomb:m_vecOrigin()
    local distance = AiUtility.client:getOrigin():getDistance(bombOrigin)

    if distance < 64 then
        ai.view.isCrosshairUsingVelocity = false

        self.isDefusing = true
    else
        self.isDefusing = false
    end

    if AiUtility.client:m_bIsDefusing() == 1 then
        ai.view:lookInDirection(Client.getCameraAngles(), 4, ai.view.noiseType.NONE, "Defuse keep current angles")
    elseif distance < 256 then
        ai.view:lookAtLocation(bombOrigin:clone():offset(5, -3, 14), 4.5, ai.view.noiseType.MOVING, "Defuse look at bomb")
    end

    if self.isDefusing then
        ai.controller.canReload = false
        ai.cmd.in_use = 1
        ai.cmd.in_duck = 1

        if AiUtility.client:hasWeapon(Weapons.SMOKE)
            and Table.isEmpty(AiUtility.visibleEnemies)
            and (not AiUtility.closestEnemy or (AiUtility.closestEnemy and AiUtility.client:getOrigin():getDistance(AiUtility.closestEnemy:getOrigin()) > 400))
        then
            ai.controller.canUseGear = false
            ai.controller.states.evade.isBlocked = true

            if not AiUtility.client:isHoldingWeapon(Weapons.SMOKE) then
                Client.equipSmoke()
            end

            ai.view:lookAtLocation(bombOrigin:clone():offset(5, -3, -64), 4.5, ai.view.noiseType.NONE, "Defuse look to drop smoke")

            if AiUtility.client:isAbleToAttack() then
                if Client.getCameraAngles().p > 22 then
                    self.inThrowTimer:ifPausedThenStart()
                end

                if self.inThrowTimer:isElapsedThenStop(0.1) then
                    ai.cmd.in_attack2 = 1
                end
            end
        end
    end
end

return Nyx.class("AiStateDefuse", AiStateDefuse, AiState)
--}}}
