--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Enums
--- @class AiWeaponPriority
local AiWeaponPriority = {
    [Weapons.SCAR20] = 7,
    [Weapons.G3SG1] = 7,
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
--- @field visibleEnemies Player[]
--- @field lastVisibleEnemyTimer Timer
--- @field enemies Player[]
--- @field enemiesAlive number
--- @field bombCarrier Player
--- @field teammates Player[]
--- @field enemyDistances number[]
--- @field enemyFovs number[]
--- @field closestEnemy Player
--- @field dormantAt number[]
--- @field hasBomb Player
--- @field bombDetonationTime number
--- @field canDefuse boolean
--- @field bomb Entity
--- @field plantedBomb Entity
--- @field roundTimer Timer
--- @field isRoundOver boolean
--- @field isPlanting boolean
--- @field mainWeapons number[]
--- @field weaponPriority AiWeaponPriority
--- @field weaponNames string[]
--- @field mainWeapons number[]
local AiUtility = {
    mainWeapons = {
        Weapons.FAMAS, Weapons.GALIL, Weapons.M4A1, Weapons.AUG, Weapons.AK47, Weapons.AWP, Weapons.SG553, Weapons.SCAR20, Weapons.G3SG1, Weapons.SSG08
    },
    weaponPriority = AiWeaponPriority,
    weaponNames = AiWeaponNames
}

--- @return void
function AiUtility:__setup()
    self:initFields()
    self:initEvents()
end

--- @return void
function AiUtility:initFields()
    self.visibleEnemies = {}
    self.lastVisibleEnemyTimer = Timer:new()
    self.enemyDistances = Table.populateForMaxPlayers(math.huge)
    self.enemyFovs = Table.populateForMaxPlayers(math.huge)
    self.roundTimer = Timer:new()
    self.lastKnownOrigin = {}
    self.dormantAt = {}
    self.enemies = {}
    self.teammates = {}
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
        self.enemiesAlive = 5
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
    end)

    Callbacks.roundStart(function(e)
        self.bombCarrier = nil
        self.isRoundOver = false
    end)

    Callbacks.itemPickup(function(e)
        if not e.item == "c4" then
            return
        end

        self.bombCarrier = e.player
    end)

    Callbacks.itemEquip(function(e)
        if not e.item == "c4" then
            return
        end

        self.bombCarrier = e.player
    end)

    Callbacks.itemRemove(function(e)
        if not e.item == "c4" then
            return
        end

        self.bombCarrier = nil
    end)

    Callbacks.bombBeginPlant(function(e)
        if e.player:isClient() then
            self.isPlanting = true
        end
    end)

    Callbacks.bombAbortPlant(function(e)
        if e.player:isClient() then
            self.isPlanting = false
        end
    end)

    Callbacks.bombPlanted(function()
    	self.bombCarrier = nil
        self.isPlanting = false
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
        self.bomb = Entity.findOne("CC4")
        self.plantedBomb = Entity.findOne("CPlantedC4")

        local origin = Client.getOrigin()
        local eyeOrigin = Client.getEyeOrigin()
        local cameraAngles = Client.getCameraAngles()
        local playerEid = Client.getEid()

        self.enemies = {}
        self.teammates = {}
        self.visibleEnemies = {}
        self.closestEnemy = nil

        for _, teammate in Player.find(function(p)
            return p:isTeammate() and p:isAlive() and not p:isClient()
        end) do
            self.teammates[teammate.eid] = teammate
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

            for _, hitbox in pairs(enemy:getHitboxPositions()) do
                local _, _, eid = eyeOrigin:getTraceLine(hitbox, playerEid)

                if eid == enemy.eid then
                    if enemy:m_bIsDefusing() == 1 then
                        visibleHitboxes = visibleHitboxes + 1
                    else
                        if not eyeOrigin:isRayIntersectingSmoke(hitbox) then
                            visibleHitboxes = visibleHitboxes + 1
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
            self.lastVisibleEnemyTimer:startIfPaused()
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
    end)
end

--- @return boolean
function AiUtility.isBombPlanted()
    return AiUtility.plantedBomb ~= nil
end

return Nyx.class("AiUtility", AiUtility)
--}}}
