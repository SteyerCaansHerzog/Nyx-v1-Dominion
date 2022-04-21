--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local DominionMenu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
--}}}

--{{{ Enums
--- @class AiWeaponPriorityGeneral
local AiWeaponPriorityGeneral = {
    [Weapons.AK47] = 6,
    [Weapons.AWP] = 6,
    [Weapons.AUG] = 5,
    [Weapons.M4A1] = 5,
    [Weapons.FAMAS] = 4,
    [Weapons.GALIL] = 4,
    [Weapons.BIZON] = 3,
    [Weapons.MP7] = 3,
    [Weapons.MP9] = 3,
    [Weapons.P90] = 3,
    [Weapons.SSG08] = 3,
    [Weapons.SG553] = 5,
    [Weapons.UMP45] = 3,
    [Weapons.MAC10] = 2,
    [Weapons.NEGEV] = 1
}

--- @class AiWeaponPriorityClutch
local AiWeaponPriorityClutch = {
    [Weapons.AK47] = 7,
    [Weapons.AUG] = 6,
    [Weapons.M4A1] = 6,
    [Weapons.AWP] = 5,
    [Weapons.FAMAS] = 4,
    [Weapons.GALIL] = 4,
    [Weapons.BIZON] = 3,
    [Weapons.MP7] = 3,
    [Weapons.MP9] = 3,
    [Weapons.P90] = 3,
    [Weapons.SSG08] = 3,
    [Weapons.SG553] = 5,
    [Weapons.UMP45] = 3,
    [Weapons.MAC10] = 2,
    [Weapons.NEGEV] = 1
}

local AiWeaponNames = {
    "CAK47",
    "CWeaponAug",
    "CWeaponAWP",
    "CWeaponBizon",
    "CWeaponFamas",
    "CWeaponGalilAR",
    "CWeaponM4A1",
    "CWeaponMAC10",
    "CWeaponMP7",
    "CWeaponMP9",
    "CWeaponP90",
    "CWeaponSSG08",
    "CWeaponSG556",
    "CWeaponUMP45",
}
--}}}

--{{{ AiUtility
--- @class AiUtility : Class
--- @field bomb Entity
--- @field bombCarrier Player
--- @field bombDetonationTime number
--- @field bombPlantedAt string
--- @field canDefuse boolean
--- @field client Player
--- @field clientThreatenedFromOrigin Vector3
--- @field closestEnemy Player
--- @field defuseTimer Timer
--- @field dormantAt number[]
--- @field enemies Player[]
--- @field enemiesAlive number
--- @field enemyDistances number[]
--- @field enemyFovs number[]
--- @field enemyHitboxes table<number, Vector3[]>
--- @field hasBomb Player
--- @field isBombBeingDefusedByEnemy boolean
--- @field isBombBeingDefusedByTeammate boolean
--- @field isBombBeingPlantedByEnemy boolean
--- @field isBombBeingPlantedByTeammate boolean
--- @field isClientPlanting boolean
--- @field isClientThreatened boolean
--- @field isEnemyVisible boolean
--- @field isLastAlive boolean
--- @field isRoundOver boolean
--- @field lastVisibleEnemyTimer Timer
--- @field mainWeapons number[]
--- @field plantedBomb Entity
--- @field roundTimer Timer
--- @field teammates Player[]
--- @field teammatesAlive number
--- @field threats boolean[]
--- @field threatUpdateTimer Timer
--- @field timeData GameStateTimeData
--- @field totalThreats number
--- @field traceOptionsAttacking TraceOptions
--- @field traceOptionsPathfinding TraceOptions
--- @field visibleEnemies Player[]
--- @field weaponNames string[]
--- @field weaponPriority AiWeaponPriorityGeneral
local AiUtility = {
    mainWeapons = {
        Weapons.FAMAS, Weapons.GALIL, Weapons.M4A1, Weapons.AUG, Weapons.AK47, Weapons.AWP, Weapons.SG553, Weapons.SSG08
    },
    weaponPriority = AiWeaponPriorityGeneral,
    weaponNames = AiWeaponNames
}

--- @return void
function AiUtility:__setup()
    AiUtility.initFields()
    AiUtility.initEvents()
end

--- @return void
function AiUtility:initFields()
    AiUtility.client = Player.getClient()
    AiUtility.visibleEnemies = {}
    AiUtility.lastVisibleEnemyTimer = Timer:new()
    AiUtility.enemyDistances = Table.populateForMaxPlayers(math.huge)
    AiUtility.enemyFovs = Table.populateForMaxPlayers(math.huge)
    AiUtility.roundTimer = Timer:new()
    AiUtility.defuseTimer = Timer:new()
    AiUtility.lastKnownOrigin = {}
    AiUtility.dormantAt = {}
    AiUtility.enemies = {}
    AiUtility.teammates = {}
    AiUtility.enemiesAlive = 0
    AiUtility.teammatesAlive = 0
    AiUtility.totalThreats = 0
    AiUtility.threatUpdateTimer = Timer:new():startThenElapse()

    if Server.isIngame() then
        AiUtility.timeData = Table.fromPanorama(Panorama.GameStateAPI.GetTimeDataJSO())
    end

    local solidPathfindingEntities = {
        CDynamicProp = true,
        CFuncBrush = true,
        CBaseEntity = true,
        CPropDoorRotating = true,
        CPhysicsProp = true,
    }

    AiUtility.traceOptionsPathfinding = {
        skip = function(eid)
            local entity = Entity:create(eid)

            if solidPathfindingEntities[entity.classname] then
                return false
            end

            if entity.classname ~= "CWorld" then
                return true
            end
        end,
        mask = Trace.mask.PLAYERSOLID,
        type = Trace.type.EVERYTHING
    }

    local solidAttackingEntities = {
        CFuncBrush = true,
        CBaseEntity = true,
        CPropDoorRotating = true,
    }

    AiUtility.traceOptionsAttacking = {
        skip = function(eid)
            local entity = Entity:create(eid)

            if solidAttackingEntities[entity.classname] then
                return false
            end

            if entity.classname ~= "CWorld" then
                return true
            end
        end,
        mask = Trace.mask.SHOT,
        type = Trace.type.EVERYTHING
    }
end

--- @return void
function AiUtility:initEvents()
    Callbacks.roundStart(function()
        AiUtility.canDefuse = nil
        AiUtility.visibleEnemies = {}
        AiUtility.enemyDistances = Table.populateForMaxPlayers(math.huge)
        AiUtility.enemyFovs = Table.populateForMaxPlayers(math.huge)
        AiUtility.lastKnownOrigin = {}
        AiUtility.dormantAt = {}

        AiUtility.defuseTimer:stop()
    end)

    Callbacks.roundEnd(function()
        AiUtility.roundTimer:stop()

        AiUtility.isRoundOver = true
    end)

    Callbacks.roundFreezeEnd(function()
        AiUtility.roundTimer:start()

        AiUtility.enemiesAlive = 0

        for _, _ in Player.findAll(function(p)
            return p:isEnemy()
        end) do
            AiUtility.enemiesAlive = AiUtility.enemiesAlive + 1
        end
    end)

    Callbacks.init(function()
    	AiUtility.bombCarrier = nil
        AiUtility.enemiesAlive = 5
        AiUtility.client = Player.getClient()
    end)

    Callbacks.roundPrestart(function(e)
        AiUtility.bombCarrier = nil
        AiUtility.isRoundOver = false
        AiUtility.isBombBeingDefusedByEnemy = false
        AiUtility.isBombBeingDefusedByTeammate = false
        AiUtility.isBombBeingPlantedByEnemy = false
        AiUtility.isBombBeingPlantedByTeammate = false
        AiUtility.isClientPlanting = false
    end)

    Callbacks.itemPickup(function(e)
        if e.item == "c4" then
            AiUtility.bombCarrier = e.player
        end
    end)

    Callbacks.itemEquip(function(e)
        if e.item == "c4" then
            AiUtility.bombCarrier = e.player
        end
    end)

    Callbacks.itemRemove(function(e)
        if e.item == "c4" then
            AiUtility.bombCarrier = nil
        end
    end)

    Callbacks.bombBeginPlant(function(e)
        if e.player:isClient() then
            AiUtility.isClientPlanting = true
        elseif e.player:isTeammate() then
            AiUtility.isBombBeingPlantedByTeammate = true
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingPlantedByEnemy = true
        end
    end)

    Callbacks.bombAbortPlant(function(e)
        if e.player:isClient() then
            AiUtility.isClientPlanting = false
        elseif e.player:isTeammate() then
            AiUtility.isBombBeingPlantedByTeammate = false
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingPlantedByEnemy = false
        end
    end)

    Callbacks.bombPlanted(function()
    	AiUtility.bombCarrier = nil
        AiUtility.isClientPlanting = false
        AiUtility.isBombBeingPlantedByEnemy = false
        AiUtility.isBombBeingPlantedByTeammate = false
    end)

    Callbacks.bombBeginDefuse(function(e)
        if e.player:isClient() then
            AiUtility.defuseTimer:start()
        end

        if not e.player:isClient() and e.player:isTeammate() then
            AiUtility.isBombBeingDefusedByTeammate = true
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingDefusedByEnemy = true
        end
    end)

    Callbacks.bombAbortDefuse(function(e)
        if e.player:isClient() then
            AiUtility.defuseTimer:stop()
        end

        if not e.player:isClient() and e.player:isTeammate() then
            AiUtility.isBombBeingDefusedByTeammate = false
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingDefusedByEnemy = false
        end
    end)

    Callbacks.bombDefused(function(e)
        if e.player:isClient() then
            AiUtility.defuseTimer:stop()
        end

        if not e.player:isClient() and e.player:isTeammate() then
            AiUtility.isBombBeingDefusedByTeammate = false
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingDefusedByEnemy = false
        end
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isClient() then
            AiUtility.canDefuse = nil
            AiUtility.visibleEnemies = {}
            AiUtility.enemyDistances = Table.populateForMaxPlayers(math.huge)
            AiUtility.enemyFovs = Table.populateForMaxPlayers(math.huge)
            AiUtility.lastKnownOrigin = {}
            AiUtility.dormantAt = {}
        elseif e.victim:isEnemy() then
            AiUtility.enemiesAlive = AiUtility.enemiesAlive - 1
        end
    end)

    Callbacks.runCommand(function()
        AiUtility.updateMisc()
        AiUtility.updateThreats()
        AiUtility.updateEnemies()
        AiUtility.updateAllPlayers()
    end)
end

--- @return void
function AiUtility.updateMisc()
    AiUtility.client = Player.getClient()
    AiUtility.bomb = Entity.findOne("CC4")
    AiUtility.plantedBomb = Entity.findOne("CPlantedC4")

    if AiUtility.plantedBomb and not AiUtility.isRoundOver then
        AiUtility.weaponPriority = AiWeaponPriorityClutch
    else
        AiUtility.weaponPriority = AiWeaponPriorityGeneral
    end

    AiUtility.timeData = Table.fromPanorama(Panorama.GameStateAPI.GetTimeDataJSO())
end

--- @return void
function AiUtility.updateEnemies()
    AiUtility.enemies = {}
    AiUtility.visibleEnemies = {}
    AiUtility.closestEnemy = nil
    AiUtility.isLastAlive = true
    AiUtility.enemiesAlive = 0
    AiUtility.isEnemyVisible = false

    local clientOrigin = Client.getOrigin()
    local clientEyeOrigin = Client.getEyeOrigin()
    local cameraAngles = Client.getCameraAngles()

    local closestEnemy
    local closestDistance = math.huge

    for _, enemy in Player.find(function(p)
        return p:isEnemy() and p:isAlive()
    end) do
        plist.set(enemy.eid, "Correction active", false)

        AiUtility.enemies[enemy.eid] = enemy

        if not enemy:isDormant() then
            AiUtility.dormantAt[enemy.eid] = Time.getRealtime()
        end

        local fov = cameraAngles:getFov(clientEyeOrigin, enemy:getHitboxPosition(Player.hitbox.SPINE_1))

        AiUtility.enemyFovs[enemy.eid] = fov

        local enemyOrigin = enemy:getOrigin()

        local distance = clientOrigin:getDistance(enemyOrigin)

        if distance < closestDistance then
            closestDistance = distance
            closestEnemy = enemy
        end

        AiUtility.enemyDistances[enemy.eid] = distance

        local isVisible = false

        if not enemy:isDormant() then
            for _, hitbox in pairs(enemy:getHitboxPositions()) do
                local trace = Trace.getLineToPosition(clientEyeOrigin, hitbox, AiUtility.traceOptionsAttacking)

                if not trace.isIntersectingGeometry then
                    if not clientEyeOrigin:isRayIntersectingSmoke(hitbox) then
                        isVisible = true

                        break
                    end
                end
            end
        end

        if isVisible then
            AiUtility.visibleEnemies[enemy.eid] = enemy

            AiUtility.isEnemyVisible = true
            AiUtility.isClientThreatened = true
            AiUtility.clientThreatenedFromOrigin = enemyOrigin:clone():offset(0, 0, 64)
        elseif enemy:m_bIsDefusing() == 1 then
            AiUtility.visibleEnemies[enemy.eid] = enemy
        end
    end

    if closestEnemy then
        AiUtility.closestEnemy = closestEnemy
    end

    if next(AiUtility.visibleEnemies) then
        AiUtility.lastVisibleEnemyTimer:stop()
    else
        AiUtility.lastVisibleEnemyTimer:ifPausedThenStart()
    end

    local bomb = AiUtility.plantedBomb

    if bomb then
        local explodeAt = bomb:m_flC4Blow()
        local time = explodeAt - globals.curtime()

        AiUtility.bombDetonationTime = math.max(0, time)

        if time <= 0 then
            return
        end

        local playerHasKit = Player.getClient():m_bHasDefuser() == 1
        local defuseTime = 10

        if playerHasKit then
            defuseTime = 5
        end

        AiUtility.canDefuse = time > defuseTime
    end
end

--- @return void
function AiUtility.updateAllPlayers()
    AiUtility.teammates = {}
    -- Very funny Valve.
    AiUtility.teammatesAlive = -1

    local playerResource = entity.get_player_resource()

    for eid = 1, globals.maxplayers() do
        local isEnemy = entity.is_enemy(eid)
        local isAlive = entity.get_prop(playerResource, "m_bAlive", eid)

        if isAlive == 1 then
            if isEnemy then
                AiUtility.enemiesAlive = AiUtility.enemiesAlive + 1
            else
                AiUtility.teammatesAlive = AiUtility.teammatesAlive + 1
            end
        end
    end

    for _, teammate in Player.find(function(p)
        return p:isTeammate() and p:isAlive() and not p:isClient()
    end) do
        AiUtility.teammates[teammate.eid] = teammate
        AiUtility.isLastAlive = false
    end
end

--- @return void
function AiUtility.updateThreats()
    AiUtility.threats = {}

    -- Update threats.
    local eyeOrigin = Client.getEyeOrigin() + AiUtility.client:m_vecVelocity():set(nil, nil, 0) * 0.33
    local threatUpdateTime = AiUtility.clientThreatenedFromOrigin and 0.3 or 0.1
    local threats = 0

    -- Don't update the threat origin too often, or it'll be obvious this is effectively wallhacking.
    if AiUtility.threatUpdateTimer:isElapsedThenRestart(threatUpdateTime) then
        AiUtility.clientThreatenedFromOrigin = nil
        AiUtility.isClientThreatened = false

        local clientPlane = eyeOrigin:getPlane(Vector3.align.CENTER, 75)

        for _, enemy in pairs(AiUtility.enemies) do
            local enemyOffset = enemy:getOrigin():offset(0, 0, 72)
            local bandAngle = eyeOrigin:getAngle(enemyOffset):set(0):offset(0, 90)
            local enemyAngle = eyeOrigin:getAngle(enemyOffset)
            local steps = 8
            local stepDistance = 180 / steps
            --- @type Vector3
            local closestPoint
            local closestPointDistance = math.huge
            local absPitch = math.abs(enemyAngle.p)
            local traceExtension = 1 - Math.getFloat(Math.getClamped(absPitch, 0, 75), 90)
            local traceDistance = 250 * traceExtension
            local lowestFov = math.huge

            for _ = 1, steps do
                local testOrigin = enemyOffset + bandAngle:getForward() * traceDistance
                local wallTrace = Trace.getLineToPosition(enemyOffset, testOrigin, AiUtility.traceOptionsAttacking)

                for _, vertex in pairs(clientPlane) do
                    -- Trace to see if we can see the previous trace.
                    local testTrace = Trace.getLineToPosition(wallTrace.endPosition, vertex, AiUtility.traceOptionsAttacking)
                    local fov = enemyAngle:getFov(eyeOrigin, wallTrace.endPosition)

                    -- Set the closest point to the enemy as the best point to look at.
                    if not testTrace.isIntersectingGeometry then
                        local distance = enemyOffset:getDistance(testTrace.endPosition)

                        if distance < closestPointDistance then
                            closestPointDistance = distance
                            closestPoint = wallTrace.endPosition
                        end

                        if fov < lowestFov and fov < 20 then
                            lowestFov = fov

                            AiUtility.clientThreatenedFromOrigin = wallTrace.endPosition
                        end
                    end
                end

                bandAngle:offset(0, stepDistance)
            end

            if closestPoint then
                AiUtility.isClientThreatened = true

                threats = threats + 1

                AiUtility.threats[enemy.eid] = true
            end
        end

        AiUtility.totalThreats = threats
    end
end

--- @return boolean
function AiUtility.isBombPlanted()
    return AiUtility.plantedBomb ~= nil
end

return Nyx.class("AiUtility", AiUtility)
--}}}
