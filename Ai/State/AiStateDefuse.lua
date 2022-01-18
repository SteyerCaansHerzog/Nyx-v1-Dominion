--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

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
local AiStateDefuse = {
    name = "Defuse"
}

--- @param fields AiStateDefuse
--- @return AiStateDefuse
function AiStateDefuse:new(fields)
    return Nyx.new(self, fields)
end

--- @return nil
function AiStateDefuse:__init()
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

            local nearestSite = self.nodegraph:getNearestBombSite(bomb:m_vecOrigin())
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

--- @return nil
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

    local playerOrigin = player:getOrigin()
    local isCovered = false

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:m_bIsDefusing() == 1 then
            return AiState.priority.IGNORE
        end

        if playerOrigin:getDistance(teammate:getOrigin()) < 512 then
            isCovered = true
        end
    end

    if player:m_bIsDefusing() == 1 and playerOrigin:getDistance(bomb:getOrigin()) < 64 and isCovered then
        return AiState.priority.DEFUSE_COVERED
    end

    if AiUtility.bombDetonationTime <= 15 then
        return AiState.priority.DEFUSE_EXPEDITE
    end

    return AiState.priority.DEFUSE
end

--- @param ai AiOptions
--- @return nil
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
        task = string.format("Retaking %s site", ai.nodegraph:getNearestBombSite(bombOrigin):upper())
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
--- @return nil
function AiStateDefuse:deactivate(ai)
    ai.nodegraph:reactivateAllNodes()
end

--- @param ai AiOptions
--- @return nil
function AiStateDefuse:think(ai)
    local bomb = AiUtility.plantedBomb

    if not bomb then
        return
    end

    local bombOrigin = bomb:m_vecOrigin()
    local distance = AiUtility.client:getOrigin():getDistance(bombOrigin)

    if distance < 64 then
        self.isDefusing = true
    else
        self.isDefusing = false
    end

    if AiUtility.client:m_bIsDefusing() == 1 then
        ai.view:lookInDirection(Client.getCameraAngles(), 6)
    elseif distance < 256 then
        ai.view:lookAtLocation(bombOrigin:clone():offset(5, -3, 14), 4.5)
    end

    if self.isDefusing then
        ai.controller.canReload = false
        ai.cmd.in_use = 1

        return
    end
end

return Nyx.class("AiStateDefuse", AiStateDefuse, AiState)
--}}}
