--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateEvade
--- @class AiStateEvade : AiState
--- @field node Node
--- @field shotBoltActionRifleTimer Timer
--- @field shotBoltActionRifleTime number
--- @field changeAngleTimer Timer
--- @field reloadLookAngles Vector3
--- @field isBlocked boolean
local AiStateEvade = {
    name = "Evade"
}

--- @param fields AiStateEvade
--- @return AiStateEvade
function AiStateEvade:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateEvade:__init()
    self.shotBoltActionRifleTimer = Timer:new()
    self.shotBoltActionRifleTime = 1
    self.reloadLookAngles = Client.getCameraAngles()
    self.changeAngleTimer = Timer:new():startThenElapse()

    Callbacks.weaponFire(function(e)
        if e.player:isClient() and e.player:hasWeapons({ Weapons.AWP, Weapons.SSG08}) then
            self.shotBoltActionRifleTimer:ifPausedThenStart()
        end
    end)
end

--- @return void
function AiStateEvade:assess()
    if self.isBlocked then
        self.isBlocked = nil

        return AiState.priority.IGNORE
    end

    if AiUtility.isRoundOver then
        return AiState.priority.IGNORE
    end

    local player = AiUtility.client

    if Client.isFlashed() then
        if not AiUtility.isPlanting and player:m_bIsDefusing() == 0 then
            return AiState.priority.EVADE
        end
    end

    local player = AiUtility.client
    local playerOrigin = player:getOrigin()

    for _, inferno in Entity.find("CInferno") do
        if playerOrigin:getDistance(inferno:m_vecOrigin()) < 350 and not player:m_bIsDefusing() == 1 then
            return AiState.priority.EVADE
        end
    end

    if self.shotBoltActionRifleTimer:isStarted() and
        not self.shotBoltActionRifleTimer:isElapsedThenStop(self.shotBoltActionRifleTime) and
        player:isHoldingBoltActionRifle() then
        return AiState.priority.EVADE
    end

    if player:isReloading() and player:getReloadProgress() < 0.5 then
        return AiState.priority.EVADE
    end

    if (next(AiUtility.visibleEnemies) or (AiUtility.lastVisibleEnemyTimer:isStarted() and not AiUtility.lastVisibleEnemyTimer:isElapsed(2)))
        and (Time.getCurtime() - player:m_flNextAttack()) <= 0
        and player:getWeapon().classname ~= "CC4"
    then
        return AiState.priority.EVADE
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateEvade:activate(ai)
    local player = AiUtility.client
    local playerOrigin = player:getOrigin()
    --- @type Node[]
    local possibleNodes = {}

    for _, node in pairs(ai.nodegraph.nodes) do
        if playerOrigin:getDistance(node.origin) < 512 then
            table.insert(possibleNodes, node)
        end
    end

    for _, enemy in pairs(AiUtility.enemies) do
        local enemyPos = enemy:getOrigin():offset(0, 0, 48)

        for key, node in pairs(possibleNodes) do
            local _, fraction = enemyPos:getTraceLine(node.origin, enemy.eid)

            if fraction == 1 then
                possibleNodes[key] = nil
            end
        end
    end

    if not next(possibleNodes) then
        ai.nodegraph:log("No cover to move to for reload")

        return
    end

    --- @type Node
    local farthestNode
    local farthestDistance = -1
    local closestOrigin

    if AiUtility.closestEnemy then
        closestOrigin = AiUtility.closestEnemy:getOrigin()
    else
        closestOrigin = playerOrigin
    end

    for _, node in pairs(possibleNodes) do
        local distance = closestOrigin:getDistance(node.origin)

        if distance > farthestDistance then
            farthestDistance = distance
            farthestNode = node
        end
    end

    ai.nodegraph:pathfind(farthestNode.origin, {
        objective = Node.types.GOAL,
        ignore = Client.getEid(),
        task = "Moving to cover",
        onComplete = function()
            ai.nodegraph:log("Found cover")
        end
    })
end

--- @param ai AiOptions
--- @return void
function AiStateEvade:think(ai)
    if self.changeAngleTimer:isElapsedThenRestart(0.35) then
        local cameraAngles

        if next(AiUtility.visibleEnemies) and AiUtility.visibleEnemies[AiUtility.closestEnemy.eid] then
            cameraAngles = Client.getEyeOrigin():getAngle(AiUtility.closestEnemy:getEyeOrigin())
        else
            cameraAngles = Client.getCameraAngles()
        end

        cameraAngles.p = cameraAngles.p + Client.getRandomFloat(-2, 2)
        cameraAngles.y = cameraAngles.y + Client.getRandomFloat(-6, 6)

        self.reloadLookAngles = cameraAngles
    end

    ai.view.canUseCheckNode = false

    ai.view:look(self.reloadLookAngles, 3)
end

return Nyx.class("AiStateEvade", AiStateEvade, AiState)
--}}}
