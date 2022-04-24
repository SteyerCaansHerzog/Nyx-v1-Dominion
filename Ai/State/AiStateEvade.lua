--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
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
        if e.player:isClient() and e.player:isHoldingSniper() then
            self.shotBoltActionRifleTimer:ifPausedThenStart()
        end
    end)
end

--- @return void
function AiStateEvade:assess()
    if self.isBlocked then
        self.isBlocked = nil

        return AiPriority.IGNORE
    end

    -- No enemies to threaten us.
    if AiUtility.enemiesAlive == 0 then
        return AiPriority.IGNORE
    end

    local player = AiUtility.client

    -- We can be peeked by an enemy.
    if not AiUtility.isClientThreatened then
        return AiPriority.IGNORE
    end

    -- We're flashed.
    if Client.isFlashed() then
        if not AiUtility.isClientPlanting and player:m_bIsDefusing() == 0 then
            return AiPriority.EVADE
        end
    end

    -- We fired an AWP or Scout.
    if self.shotBoltActionRifleTimer:isNotElapsed(1) then
        return AiPriority.EVADE
    end

    -- We're reloading.
    if player:isReloading() and player:getReloadProgress() < 0.66 then
        return AiPriority.EVADE
    end

    -- We're switching weapons.
    if (Time.getCurtime() - player:m_flNextAttack()) <= 0
        and player:getWeapon().classname ~= "CC4"
    then
        return AiPriority.EVADE
    end

    -- We're avoiding a flash.
    if self.ai.flashbang then
        return AiPriority.EVADE
    end

    -- Avoid grenades
    if not AiUtility.isClientThreatened then
        local eyeOrigin = Client.getEyeOrigin()

        for _, grenade in Entity.find({"CBaseCSGrenadeProjectile", "CMolotovProjectile"}) do
            if eyeOrigin:getDistance(grenade:m_vecOrigin()) < 128 then

            end
        end
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateEvade:activate()
    self:moveToCover()
end

--- @return void
function AiStateEvade:think()
    self.activity = "Seeking cover"
    self.ai.canUseKnife = false

    --- @type Angle
    local cameraAngles

    if next(AiUtility.visibleEnemies) and AiUtility.visibleEnemies[AiUtility.closestEnemy.eid] then
        cameraAngles = Client.getEyeOrigin():getAngle(AiUtility.closestEnemy:getEyeOrigin())
    end

    if self.ai.view.lastLookAtLocationOrigin then
       self.ai.view:lookAtLocation(self.ai.view.lastLookAtLocationOrigin, self.ai.view.noiseType.MINOR, "Evade look at last spot")
    end

    if self.ai.nodegraph:isIdle() then
        self:moveToCover()
    end
end

--- @return void
function AiStateEvade:moveToCover()
    local player = AiUtility.client
    local playerOrigin = player:getOrigin()
    --- @type Node[]
    local possibleNodes = {}
    local cameraAngles = -(Client.getCameraAngles():set(0))

    for _, node in pairs(self.ai.nodegraph.nodes) do
        if playerOrigin:getDistance(node.origin) < 1000 and cameraAngles:getFov(playerOrigin, node.origin) < 90 then
            local isVisibleToEnemy = false

            for _, enemy in pairs(AiUtility.enemies) do
                local enemyPos = enemy:getOrigin():offset(0, 0, 64)
                local trace = Trace.getLineToPosition(enemyPos, node.origin, AiUtility.traceOptionsAttacking)

                if not trace.isIntersectingGeometry then
                    isVisibleToEnemy = true

                    break
                end
            end

            if not isVisibleToEnemy then
                table.insert(possibleNodes, node)
            end
        end
    end

    if not next(possibleNodes) then
        -- If we ever reach this, we've graphed the map badly, or the AI is literally surrounded.
        self.ai.nodegraph:log("No cover to move to for reload")

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

    self.ai.nodegraph:pathfind(farthestNode.origin, {
        objective = Node.types.GOAL,
        task = "Moving to cover",
        canUseInactive = true,
        onComplete = function()
            self.ai.nodegraph:log("Found cover")
        end
    })
end

return Nyx.class("AiStateEvade", AiStateEvade, AiState)
--}}}
