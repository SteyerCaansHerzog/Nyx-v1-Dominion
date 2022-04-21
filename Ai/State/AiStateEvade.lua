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
        if e.player:isClient() and e.player:hasWeapons({Weapons.AWP, Weapons.SSG08}) then
            self.shotBoltActionRifleTimer:ifPausedThenStart()
        end
    end)
end

--- @param nodegraph Nodegraph
--- @param ai AiController
--- @return void
function AiStateEvade:assess(nodegraph, ai)
    if self.isBlocked then
        self.isBlocked = nil

        return AiState.priority.IGNORE
    end

    -- No enemies to threaten us.
    if AiUtility.enemiesAlive == 0 then
        return AiState.priority.IGNORE
    end

    local player = AiUtility.client

    -- We can be peeked by an enemy.
    if not AiUtility.isClientThreatened then
        return AiState.priority.IGNORE
    end

    -- We're flashed.
    if Client.isFlashed() then
        if not AiUtility.isClientPlanting and player:m_bIsDefusing() == 0 then
            return AiState.priority.EVADE
        end
    end

    -- We fired an AWP or Scout.
    if self.shotBoltActionRifleTimer:isStarted() and
        not self.shotBoltActionRifleTimer:isElapsedThenStop(self.shotBoltActionRifleTime) and
        player:isHoldingBoltActionRifle()
    then
        return AiState.priority.EVADE
    end

    -- We're reloading.
    if player:isReloading() and player:getReloadProgress() < 0.66 then
        return AiState.priority.EVADE
    end

    -- We're switching weapons.
    if (next(AiUtility.visibleEnemies) or (AiUtility.lastVisibleEnemyTimer:isStarted() and not AiUtility.lastVisibleEnemyTimer:isElapsed(2)))
        and (Time.getCurtime() - player:m_flNextAttack()) <= 0
        and player:getWeapon().classname ~= "CC4"
    then
        return AiState.priority.EVADE
    end

    -- We're avoiding a flash.
    if ai.flashbang then
        return AiState.priority.EVADE
    end

    -- Avoid grenades
    if not AiUtility.isClientThreatened then
        local eyeOrigin = Client.getEyeOrigin()

        for _, grenade in Entity.find({"CBaseCSGrenadeProjectile", "CMolotovProjectile"}) do
            if eyeOrigin:getDistance(grenade:m_vecOrigin()) < 128 then

            end
        end
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
    local cameraAngles = Client.getCameraAngles():set(0)

    for _, node in pairs(ai.nodegraph.nodes) do
        if playerOrigin:getDistance(node.origin) < 512 and cameraAngles:getFov(playerOrigin, node.origin) < 45 then
            table.insert(possibleNodes, node)
        end
    end

    for _, enemy in pairs(AiUtility.enemies) do
        local enemyPos = enemy:getOrigin():offset(0, 0, 64)

        for key, node in pairs(possibleNodes) do
            local _, fraction = enemyPos:getTraceLine(node.origin, enemy.eid)

            if fraction == 1 then
                possibleNodes[key] = nil
            end
        end
    end

    if not next(possibleNodes) then
        -- If we ever reach this, we've graphed the map badly, or the AI is literally surrounded.
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
    self.activity = "Seeking cover"
    ai.controller.canUseKnife = false

    --- @type Angle
    local cameraAngles

    if next(AiUtility.visibleEnemies) and AiUtility.visibleEnemies[AiUtility.closestEnemy.eid] then
        cameraAngles = Client.getEyeOrigin():getAngle(AiUtility.closestEnemy:getEyeOrigin())
    end

    if ai.view.lastLookAtLocationOrigin then
        ai.view:lookAtLocation(ai.view.lastLookAtLocationOrigin, ai.view.noiseType.MINOR, "Evade look at last spot")
    end
end

return Nyx.class("AiStateEvade", AiStateEvade, AiState)
--}}}
