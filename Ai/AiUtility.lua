--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
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
--- @field closestEnemy Player
--- @field dormantAt number[]
--- @field enemies Player[]
--- @field enemiesAlive number
--- @field enemyDistances number[]
--- @field enemyFovs number[]
--- @field enemyHitboxes table<number, Vector3[]>
--- @field hasBomb Player
--- @field isBombBeingDefusedByEnemy boolean
--- @field isBombBeingDefusedByTeammate boolean
--- @field isLastAlive boolean
--- @field isClientPlanting boolean
--- @field isBombBeingPlantedByEnemy boolean
--- @field isBombBeingPlantedByTeammate boolean
--- @field isRoundOver boolean
--- @field lastVisibleEnemyTimer Timer
--- @field mainWeapons number[]
--- @field plantedBomb Entity
--- @field roundTimer Timer
--- @field teammates Player[]
--- @field teammatesAlive number
--- @field traceOptionsPathfinding TraceOptions
--- @field traceOptionsAttacking TraceOptions
--- @field visibleEnemies Player[]
--- @field weaponNames string[]
--- @field weaponPriority AiWeaponPriorityGeneral
--- @field defuseTimer Timer
--- @field threatOrigin Vector3
--- @field threatUpdateTimer Timer
--- @field totalThreats number
--- @field isClientThreatened boolean
local AiUtility = {
    mainWeapons = {
        Weapons.FAMAS, Weapons.GALIL, Weapons.M4A1, Weapons.AUG, Weapons.AK47, Weapons.AWP, Weapons.SG553, Weapons.SSG08
    },
    weaponPriority = AiWeaponPriorityGeneral,
    weaponNames = AiWeaponNames
}

--- @return void
function AiUtility:__setup()
    self:initFields()
    self:initEvents()
end

--- @return void
function AiUtility:initFields()
    self.client = Player.getClient()
    self.visibleEnemies = {}
    self.lastVisibleEnemyTimer = Timer:new()
    self.enemyDistances = Table.populateForMaxPlayers(math.huge)
    self.enemyFovs = Table.populateForMaxPlayers(math.huge)
    self.roundTimer = Timer:new()
    self.defuseTimer = Timer:new()
    self.lastKnownOrigin = {}
    self.dormantAt = {}
    self.enemies = {}
    self.teammates = {}
    self.enemiesAlive = 0
    self.teammatesAlive = 0
    self.threatUpdateTimer = Timer:new():startThenElapse()

    local solidPathfindingEntities = {
        CDynamicProp = true,
        CFuncBrush = true,
        CBaseEntity = true,
        CPropDoorRotating = true,
        CPhysicsProp = true,
    }

    self.traceOptionsPathfinding = {
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

    self.traceOptionsAttacking = {
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
        self.canDefuse = nil
        self.visibleEnemies = {}
        self.enemyDistances = Table.populateForMaxPlayers(math.huge)
        self.enemyFovs = Table.populateForMaxPlayers(math.huge)
        self.lastKnownOrigin = {}
        self.dormantAt = {}

        self.defuseTimer:stop()
    end)

    Callbacks.roundEnd(function()
        self.roundTimer:stop()

        self.isRoundOver = true
    end)

    Callbacks.roundFreezeEnd(function()
        self.roundTimer:start()

        self.enemiesAlive = 0

        for _, _ in Player.findAll(function(p)
            return p:isEnemy()
        end) do
            self.enemiesAlive = self.enemiesAlive + 1
        end
    end)

    Callbacks.init(function()
    	self.bombCarrier = nil
        self.enemiesAlive = 5
        self.client = Player.getClient()
    end)

    Callbacks.roundPrestart(function(e)
        self.bombCarrier = nil
        self.isRoundOver = false
        self.isBombBeingDefusedByEnemy = false
        self.isBombBeingDefusedByTeammate = false
        self.isBombBeingPlantedByEnemy = false
        self.isBombBeingPlantedByTeammate = false
        self.isClientPlanting = false
    end)

    Callbacks.itemPickup(function(e)
        if e.item == "c4" then
            self.bombCarrier = e.player
        end
    end)

    Callbacks.itemEquip(function(e)
        if e.item == "c4" then
            self.bombCarrier = e.player
        end
    end)

    Callbacks.itemRemove(function(e)
        if e.item == "c4" then
            self.bombCarrier = nil
        end
    end)

    Callbacks.bombBeginPlant(function(e)
        if e.player:isClient() then
            self.isClientPlanting = true
        elseif e.player:isTeammate() then
            self.isBombBeingPlantedByTeammate = true
        elseif e.player:isEnemy() then
            self.isBombBeingPlantedByEnemy = true
        end
    end)

    Callbacks.bombAbortPlant(function(e)
        if e.player:isClient() then
            self.isClientPlanting = false
        elseif e.player:isTeammate() then
            self.isBombBeingPlantedByTeammate = false
        elseif e.player:isEnemy() then
            self.isBombBeingPlantedByEnemy = false
        end
    end)

    Callbacks.bombPlanted(function()
    	self.bombCarrier = nil
        self.isClientPlanting = false
        self.isBombBeingPlantedByEnemy = false
        self.isBombBeingPlantedByTeammate = false
    end)

    Callbacks.bombBeginDefuse(function(e)
        if e.player:isClient() then
            self.defuseTimer:start()
        end

        if not e.player:isClient() and e.player:isTeammate() then
            self.isBombBeingDefusedByTeammate = true
        elseif e.player:isEnemy() then
            self.isBombBeingDefusedByEnemy = true
        end
    end)

    Callbacks.bombAbortDefuse(function(e)
        if e.player:isClient() then
            self.defuseTimer:stop()
        end

        if not e.player:isClient() and e.player:isTeammate() then
            self.isBombBeingDefusedByTeammate = true
        elseif e.player:isEnemy() then
            self.isBombBeingDefusedByEnemy = true
        end
    end)

    Callbacks.bombDefused(function(e)
        if e.player:isClient() then
            self.defuseTimer:stop()
        end

        if not e.player:isClient() and e.player:isTeammate() then
            self.isBombBeingDefusedByTeammate = true
        elseif e.player:isEnemy() then
            self.isBombBeingDefusedByEnemy = true
        end
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isClient() then
            self.canDefuse = nil
            self.visibleEnemies = {}
            self.enemyDistances = Table.populateForMaxPlayers(math.huge)
            self.enemyFovs = Table.populateForMaxPlayers(math.huge)
            self.lastKnownOrigin = {}
            self.dormantAt = {}
        elseif e.victim:isEnemy() then
            self.enemiesAlive = self.enemiesAlive - 1
        end
    end)

    Callbacks.runCommand(function()
        self.client = Player.getClient()
        self.bomb = Entity.findOne("CC4")
        self.plantedBomb = Entity.findOne("CPlantedC4")

        if self.plantedBomb and not self.isRoundOver then
            self.weaponPriority = AiWeaponPriorityClutch
        else
            self.weaponPriority = AiWeaponPriorityGeneral
        end

        local origin = Client.getOrigin()
        local eyeOrigin = Client.getEyeOrigin()
        local cameraAngles = Client.getCameraAngles()

        self.enemies = {}
        self.teammates = {}
        self.visibleEnemies = {}
        self.closestEnemy = nil
        self.isLastAlive = true
        self.enemiesAlive = 0
        -- Very funny Valve.
        self.teammatesAlive = -1

        local playerResource = entity.get_player_resource()

        for eid = 1, globals.maxplayers() do
            local isEnemy = entity.is_enemy(eid)
            local isAlive = entity.get_prop(playerResource, "m_bAlive", eid)

            if isAlive == 1 then
                if isEnemy then
                    self.enemiesAlive = self.enemiesAlive + 1
                else
                    self.teammatesAlive = self.teammatesAlive + 1
                end
            end
        end

        for _, teammate in Player.find(function(p)
            return p:isTeammate() and p:isAlive() and not p:isClient()
        end) do
            self.teammates[teammate.eid] = teammate
            self.isLastAlive = false
        end

        local closestEnemy
        local closestDistance = math.huge

        for _, enemy in Player.find(function(p)
            return p:isEnemy() and p:isAlive()
        end) do
            self.enemies[enemy.eid] = enemy

            if not enemy:isDormant() then
                self.dormantAt[enemy.eid] = Time.getRealtime()
            end

            local fov = cameraAngles:getFov(eyeOrigin, enemy:getHitboxPosition(Player.hitbox.SPINE_1))

            self.enemyFovs[enemy.eid] = fov

            local enemyOrigin = enemy:getOrigin()

            local distance = origin:getDistance(enemyOrigin)

            if distance < closestDistance then
                closestDistance = distance
                closestEnemy = enemy
            end

            self.enemyDistances[enemy.eid] = distance

            local visibleHitboxes = 0

            if not enemy:isDormant() then
                for _, hitbox in pairs(enemy:getHitboxPositions()) do
                    local trace = Trace.getLineToPosition(eyeOrigin, hitbox, AiUtility.traceOptionsAttacking)

                    if not trace.isIntersectingGeometry then
                        if enemy:m_bIsDefusing() == 1 then
                            visibleHitboxes = visibleHitboxes + 1
                        else
                            if not eyeOrigin:isRayIntersectingSmoke(hitbox) then
                                visibleHitboxes = visibleHitboxes + 1
                            end
                        end
                    end
                end
            end

            if visibleHitboxes > 0 then
                self.visibleEnemies[enemy.eid] = enemy
            end
        end

        if closestEnemy then
            self.closestEnemy = closestEnemy
        end

        if next(AiUtility.visibleEnemies) then
            self.lastVisibleEnemyTimer:stop()
        else
            self.lastVisibleEnemyTimer:ifPausedThenStart()
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

            self.canDefuse = time > defuseTime
        end

        -- Update threats.
        local eyeOrigin = Client.getEyeOrigin() + AiUtility.client:m_vecVelocity() * 0.5
        local threatUpdateTime = self.threatOrigin and 2.5 or 0.5
        local threats = 0

        -- Don't update the watch origin too often, or it'll be obvious this is effectively wallhacking.
        if self.threatUpdateTimer:isElapsedThenRestart(threatUpdateTime) then
            self.threatOrigin = nil
            self.isClientThreatened = false

            for _, enemy in pairs(AiUtility.enemies) do
                local enemyOffset = enemy:getOrigin():offset(0, 0, 64)
                local angle = eyeOrigin:getAngle(enemyOffset):offset(0, 90)
                local steps = 16
                local stepDistance = 180 / 16
                --- @type Vector3
                local closestPoint
                local closestPointDistance = math.huge

                for _ = 1, steps do
                    -- Trace our circle and collide with walls.
                    local wallTrace = Trace.getLineAtAngle(enemyOffset, angle, Table.merge(AiUtility.traceOptionsAttacking, {
                        distance = 350
                    }))

                    wallTrace.endPosition:lerp(enemyOffset, 0.25)

                    -- Trace to see if we can see the previous trace.
                    local testTrace = Trace.getLineToPosition(wallTrace.endPosition, eyeOrigin, AiUtility.traceOptionsAttacking)

                    -- Set the closest point to the enemy as the best point to look at.
                    if not testTrace.isIntersectingGeometry then
                        local distance = enemyOffset:getDistance(testTrace.endPosition)

                        if distance < closestPointDistance then
                            closestPointDistance = distance
                            closestPoint = wallTrace.endPosition
                        end
                    end

                    angle:offset(0, stepDistance)
                end

                if closestPoint then
                    self.threatOrigin = closestPoint
                    self.isClientThreatened = true

                    threats = threats + 1
                end
            end

            self.totalThreats = threats
        end
    end)
end

--- @return boolean
function AiUtility.isBombPlanted()
    return AiUtility.plantedBomb ~= nil
end

return Nyx.class("AiUtility", AiUtility)
--}}}
