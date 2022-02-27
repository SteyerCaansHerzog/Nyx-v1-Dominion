--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
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
--- @field changeAngleTime number
--- @field evadeLookAtAngles Vector3
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
    self.evadeLookAtAngles = Client.getCameraAngles()
    self.changeAngleTimer = Timer:new():startThenElapse()
    self.changeAngleTime = 1

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

    if AiUtility.enemiesAlive == 0 then
        return AiState.priority.IGNORE
    end

    if AiUtility.isRoundOver then
        return AiState.priority.IGNORE
    end

    local player = AiUtility.client
    local clientEyeOrigin = Client.getEyeOrigin()
    local clientTestVisibilityBox = clientEyeOrigin:getPlane(Vector3.align.CENTER, 64)
    local isSafe = true

    for _, enemy in pairs(AiUtility.enemies) do
        local distance = clientEyeOrigin:getDistance(enemy:getOrigin())

        -- Enemy is too close.
        if distance > 500 then
            isSafe = false

            break
        end

        local enemyTestVisibilityBox = enemy:getEyeOrigin():getBox(Vector3.align.CENTER, 64)

        -- Enemy could peek us, or we could peek them.
        for _, clientVertex in pairs(clientTestVisibilityBox) do
            for _, enemyVertex in pairs(enemyTestVisibilityBox) do
                local trace = Trace.getLineToPosition(clientVertex, enemyVertex, AiUtility.traceOptionsAttacking)

                if not trace.isIntersectingGeometry then
                    isSafe = false

                    break
                end
            end
        end
    end

    if isSafe then
        return AiState.priority.IGNORE
    end

    if Client.isFlashed() then
        if not AiUtility.isClientPlanting and player:m_bIsDefusing() == 0 then
            return AiState.priority.EVADE
        end
    end

    if self.shotBoltActionRifleTimer:isStarted() and
        not self.shotBoltActionRifleTimer:isElapsedThenStop(self.shotBoltActionRifleTime) and
        player:isHoldingBoltActionRifle()
    then
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
    --- @type Angle
    local cameraAngles

    if next(AiUtility.visibleEnemies) and AiUtility.visibleEnemies[AiUtility.closestEnemy.eid] then
        cameraAngles = Client.getEyeOrigin():getAngle(AiUtility.closestEnemy:getEyeOrigin())
    end

    if ai.view.lastLookAtLocationOrigin then
        ai.view:lookAtLocation(ai.view.lastLookAtLocationOrigin, 1)
    end
end

return Nyx.class("AiStateEvade", AiStateEvade, AiState)
--}}}
