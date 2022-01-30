--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local CsgoWeapons = require "gamesense/csgo_weapons"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateEngage
--- @class AiStateEngage : AiState
--- @field activeWeapon string
--- @field aimAdjustmentMaxAccuracy number
--- @field aimAdjustmentPitch number
--- @field aimAdjustmentYaw number
--- @field aimOffset number
--- @field aimSpeed number
--- @field anticipateTime number
--- @field bestTarget Player
--- @field blockTime number
--- @field blockTimer Timer
--- @field canAutoStop boolean
--- @field canCrouch boolean
--- @field isPreAimViableForHoldingAngle boolean
--- @field currentReactionTime number
--- @field enemySpottedCooldown Timer
--- @field enemyVisibleTime number
--- @field enemyVisibleTimer Timer
--- @field ferrariPeekCooldownTimer Timer
--- @field ferrariPeekStuckTimer Timer
--- @field hitboxOffset Vector3
--- @field hitboxOffsetTimer Timer
--- @field ignoreDormancyTime number
--- @field ignoreDormancyTimer Timer
--- @field ignorePlayerAfter number
--- @field isHoldingAngle boolean
--- @field isHoldingAngleDucked boolean
--- @field isIgnoringDormancy boolean
--- @field isPathfindingDirectlyToEnemy boolean
--- @field isRcsEnabled boolean
--- @field isSneaking boolean
--- @field isTargetEasilyShot boolean
--- @field isVisibleToAimSystem boolean
--- @field jiggleDirection string
--- @field jiggleTime number
--- @field jiggleTimer Timer
--- @field lastBestTargetOrigin Vector3
--- @field lastMoveDirection Vector3
--- @field lastSeenTimers Timer[]
--- @field lastSoundTimer Timer
--- @field noticedPlayerTimers Timer[]
--- @field onGroundTime Timer
--- @field onGroundTimer Timer
--- @field patienceTimer Timer
--- @field patienceCooldownTimer Timer
--- @field preAimAroundCornersTime number
--- @field preAimAroundCornersTimer Timer
--- @field preAimCornerOrigin Vector3
--- @field preAimOrigin Vector3
--- @field preAimOriginTimer Timer
--- @field preAimTarget Player
--- @field preAimThroughCornerBlockTimer Timer
--- @field priorityHitbox number
--- @field reactionTime number
--- @field reactionTimer Timer
--- @field recoilControl number
--- @field scopedTimer Timer
--- @field setBestTargetTimer Timer
--- @field shootAtOrigin Vector3
--- @field skill number
--- @field slowAimSpeed number
--- @field sprayTime number
--- @field sprayTimer Timer
--- @field tapFireTime number
--- @field tapFireTimer Timer
--- @field tellRotateTimer Timer
--- @field updatePreAimOriginTime Timer
--- @field updatePreAimOriginTimer Timer
--- @field walkCheckCount number
--- @field walkCheckTimer Timer
--- @field watchOrigin Vector3
--- @field watchTime number
--- @field watchTimer Timer
local AiStateEngage = {
    name = "Engage"
}

--- @param fields AiStateEngage
--- @return AiStateEngage
function AiStateEngage:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateEngage:__init()
    self:initFields()
    self:initEvents()
end

--- @return void
function AiStateEngage:initFields()
    self.skill = 4
    self.enemyVisibleTimer = Timer:new()
    self.enemyVisibleTime = 0.66
    self.watchTimer = Timer:new()
    self.watchTime = 2
    self.anticipateTime = 0.1
    self.ignorePlayerAfter = 25
    self.onGroundTimer = Timer:new()
    self.onGroundTime = 0.1
    self.ignoreDormancyTimer = Timer:new():startThenElapse()
    self.ignoreDormancyTime = 6.5
    self.isIgnoringDormancy = false
    self.isSneaking = false
    self.blockTimer = Timer:new():startThenElapse()
    self.blockTime = 0.25
    self.lastSoundTimer = Timer:new():start()
    self.preAimOriginDelayed = Vector3:new()
    self.preAimOriginTimer = Timer:new():startThenElapse()
    self.setBestTargetTimer = Timer:new():startThenElapse()
    self.ferrariPeekStuckTimer = Timer:new()
    self.ferrariPeekCooldownTimer = Timer:new():startThenElapse()
    self.preAimThroughCornerBlockTimer = Timer:new():startThenElapse()
    self.jiggleTimer = Timer:new():startThenElapse()
    self.jiggleTime = Client.getRandomFloat(0.33, 0.66)
    self.jiggleDirection = "Left"
    self.patienceTimer = Timer:new()
    self.patienceCooldownTimer = Timer:new():startThenElapse()

    self.noticedPlayerTimers = {}

    for i = 1, 64 do
        self.noticedPlayerTimers[i] = Timer:new()
    end

    self.lastSeenTimers = {}

    for i = 1, 64 do
        self.lastSeenTimers[i] = Timer:new()
    end

    self.tapFireTime = 0.2
    self.tapFireTimer = Timer:new():start()

    self.reactionTimer = Timer:new()
    self.sprayTimer = Timer:new()
    self.aimAdjustmentPitch = 0
    self.aimAdjustmentYaw = 0
    self.currentReactionTime = 0
    self.scopedTimer = Timer:new()
    self.tellRotateTimer = Timer:new():startThenElapse()
    self.walkCheckTimer = Timer:new():start()
    self.walkCheckCount = 0
    self.hitboxOffsetTimer = Timer:new():startThenElapse()
    self.enemySpottedCooldown = Timer:new():startThenElapse()
    self.preAimAroundCornersTimer = Timer:new()
    self.preAimAroundCornersTime = 1
    self.updatePreAimOriginTimer = Timer:new():startThenElapse()
    self.updatePreAimOriginTime = 1.2

    Menu.enableAimbot = Menu.group:checkbox("    > Enable Aimbot"):setParent(Menu.enableAi)
    Menu.visualiseAimbot = Menu.group:checkbox("    > Visualise Aimbot"):setParent(Menu.enableAimbot)
    Menu.aimSkillLevel = Menu.group:slider("    > Aim Skill Level", 0, 10, {
        default = 4,
        unit = "x"
    }):addCallback(function(item)
        self:setAimSkill(item:get())
    end):setParent(Menu.enableAi)
end

--- @return void
function AiStateEngage:initEvents()
    Callbacks.playerFootstep(function(e)
        if e.player:isClient() then
            self.lastSoundTimer:restart()
        end

        if e.player:isEnemy() or e.player:isClient() then
            return
        end

        if AiUtility.client:getOrigin():getDistance(e.player:getOrigin()) > 512 then
            return
        end

        self.walkCheckCount = self.walkCheckCount + 1
    end)

    Callbacks.weaponFire(function(e)
        if e.player:isClient() then
            self.lastSoundTimer:restart()
        end

        if e.player:isEnemy() or e.player:isClient() then
            return
        end

        if AiUtility.client:getOrigin():getDistance(e.player:getOrigin()) > 512 then
            return
        end

        self.walkCheckCount = self.walkCheckCount + 1
    end)

    Callbacks.playerSpawned(function(e)
        if e.player:isClient() then
            self:reset()
        else
            self:unnoticeEnemy(e.player)
        end
    end)

    Callbacks.roundStart(function()
        self:reset()

        self.ignoreDormancyTimer:stop()

        self.isIgnoringDormancy = true
        self.jiggleTime = Client.getRandomFloat(0.33, 0.66)
    end)

    Callbacks.roundFreezeEnd(function()
        self.ignoreDormancyTimer:start()
    end)

    Callbacks.runCommand(function()
        local player = AiUtility.client
        local bomb = AiUtility.plantedBomb

        if player:isCounterTerrorist() and bomb then
            local bombOrigin = bomb:m_vecOrigin()

            for _, enemy in pairs(AiUtility.enemies) do
                if bombOrigin:getDistance(enemy:getOrigin()) < 512 then
                    self:noticeEnemy(enemy, 512, "Near Site")
                end
            end
        end

        local isLastAlive = true

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:isAlive() then
                isLastAlive = false

                break
            end
        end

        if isLastAlive then
            for _, enemy in pairs(AiUtility.enemies) do
                self:noticeEnemy(enemy, 1024)
            end
        end

        if player:m_bIsScoped() == 1 then
            self.scopedTimer:ifPausedThenStart()
        else
            self.scopedTimer:stop()
        end
    end)

    Callbacks.playerHurt(function(e)
        if not e.victim:isClient() then
            return
        end

        self:noticeEnemy(e.attacker, Vector3.MAX_DISTANCE, "Shot by")
    end)

    Callbacks.playerFootstep(function(e)
        self:noticeEnemy(e.player, 900, "Stepped")
    end)

    Callbacks.playerJump(function(e)
        self:noticeEnemy(e.player, 512, "Jumped")
    end)

    Callbacks.weaponZoom(function(e)
        self:noticeEnemy(e.player, 512, "Scoped")
    end)

    Callbacks.weaponReload(function(e)
        self:noticeEnemy(e.player, 700, "Reloaded")
    end)

    Callbacks.weaponFire(function(e)
        if e.player:isClient() and e.player:isHoldingBoltActionRifle() then
            Client.unscope(true)
        end

        if CsgoWeapons[e.weapon].is_melee_weapon then
            return
        end

        local range = 1100

        if AiUtility.visibleEnemies[e.player.eid] then
            range = Vector3.MAX_DISTANCE
        end

        self:noticeEnemy(e.player, range, "Shot")
    end)

    Callbacks.bulletImpact(function(e)
        if not e.shooter:isEnemy() then
            return
        end

        if AiUtility.client:getOrigin():getDistance(e.origin) > 128 then
            return
        end

        self:noticeEnemy(e.shooter, 4096, "Shot at")
    end)

    Callbacks.bombBeginDefuse(function(e)
        self:noticeEnemy(e.player, 4096, "Began defusing")
    end)

    Callbacks.bombBeginPlant(function(e)
        self:noticeEnemy(e.player, 2048, "Began planting")
    end)

    Callbacks.grenadeThrown(function(e)
        self:noticeEnemy(e.player, 512, "Threw grenade")
    end)

    Callbacks.playerDeath(function(e)
        self.isPathfindingDirectlyToEnemy = Client.getChance(3)

        if e.victim:isClient() then
            self:reset()

            return
        end

        if e.attacker:isClient() and e.victim:isEnemy() then
            self.blockTimer:start()
        end

        if e.victim:isTeammate() and AiUtility.client:getOrigin():getDistance(e.victim:getOrigin()) < 1250 then
            self:noticeEnemy(e.attacker, 1250, "Teammate killed")
        end

        if e.victim:isEnemy() and self.noticedPlayerTimers[e.victim.eid] then
            self.noticedPlayerTimers[e.victim.eid]:stop()
            self.lastSeenTimers[e.victim.eid]:stop()
        end
    end)
end

--- @return void
function AiStateEngage:assess()
    self:setBestTarget()

    self.sprayTimer:isElapsedThenStop(self.sprayTime)
    self.watchTimer:isElapsedThenStop(self.watchTime)

    if Client.isFlashed() and self.bestTarget and AiUtility.visibleEnemies[self.bestTarget.eid] then
        return AiState.priority.ENGAGE_PANIC
    end

    if self.sprayTimer:isStarted() then
        return AiState.priority.ENGAGE_VISIBLE
    end

    for _, enemy in pairs(AiUtility.enemies) do
        if AiUtility.visibleEnemies[enemy.eid] and self:hasNoticedEnemy(enemy) then
            return AiState.priority.ENGAGE_VISIBLE
        end
    end

    if not AiUtility.plantedBomb then
        if self.reactionTimer:isStarted() then
            return AiState.priority.ENGAGE_VISIBLE
        end

        if self.watchTimer:isStarted() then
            return AiState.priority.ENGAGE_VISIBLE
        end
    end

    if AiUtility.isBombBeingDefusedByEnemy then
        return AiState.priority.ENGAGE_VISIBLE
    end

    if self:hasNoticedEnemies() then
        return AiState.priority.ENGAGE_NEARBY
    end

    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:activate(ai)
    self.canCrouch = Client.getChance(2)

    if self.enemySpottedCooldown:isElapsedThenRestart(60) then
        local player = AiUtility.client

        if AiUtility.bombCarrier and AiUtility.bombCarrier:is(self.bestTarget) and player:isCounterTerrorist() then
            ai.radio:speak(ai.radio.message.ENEMY_SPOTTED, 1, 0.5, 1, "I have the %sbomb carrier%s near me.", ai.radio.color.GOLD, ai.radio.color.DEFAULT)

            if not AiUtility.isLastAlive then
                ai.voice.pack:speakNotifyTeamOfBombCarrier()
            end
        else
            ai.radio:speak(ai.radio.message.ENEMY_SPOTTED, 2, 0.5, 1, "I am %sengaging%s enemies near me.", ai.radio.color.YELLOW, ai.radio.color.DEFAULT)

            if not AiUtility.isLastAlive then
                ai.voice.pack:speakHearNearbyEnemies()
            end
        end
    end
end

--- @return void
function AiStateEngage:deactivate() end

--- @return void
function AiStateEngage:reset()
    self.reactionTimer:stop()
    self.sprayTimer:stop()
    self.watchTimer:stop()
    self.watchOrigin = nil
    self.bestTarget = nil

    self.noticedPlayerTimers = {}

    for i = 1, 64 do
        self.noticedPlayerTimers[i] = Timer:new()
    end

    self.lastSeenTimers = {}

    for i = 1, 64 do
        self.lastSeenTimers[i] = Timer:new()
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:think(ai)
    if not Menu.master:get() or not Menu.enableAi:get() then
        return
    end

    self:tellRotate(ai)
    self:walk(ai)
    self:engage(ai)
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:tellRotate(ai)
    if not self.tellRotateTimer:isElapsed(15) then
        return
    end

    local player = AiUtility.client

    if not player:isCounterTerrorist() then
        return
    end

    local playerOrigin = player:getOrigin()

    local nearestBombSite = ai.nodegraph:getNearestSiteName(playerOrigin)
    local siteOrigin = ai.nodegraph:getSiteNode(nearestBombSite).origin

    if playerOrigin:getDistance(siteOrigin) > 2048 then
        return
    end

    local countEnemiesNearby = 0
    --- @type Player
    local tellEnemy

    for _, enemy in pairs(AiUtility.enemies) do
        if self:hasNoticedEnemy(enemy) then
            local enemyOrigin = enemy:getOrigin()

            if enemyOrigin:getDistance(siteOrigin) < 2048 and playerOrigin:getDistance(enemyOrigin) < 2048 then
                countEnemiesNearby = countEnemiesNearby + 1
                tellEnemy = enemy
            end
        end
    end

    for _, enemy in pairs(AiUtility.visibleEnemies) do
        if AiUtility.bombCarrier and AiUtility.bombCarrier:is(enemy) then
            countEnemiesNearby = 5
            tellEnemy = enemy

            break
        end
    end

    if not tellEnemy then
        return
    end

    local isBombVisible = AiUtility.bomb and playerOrigin:isVisible(AiUtility.bomb:m_vecOrigin(), Client.getEid())

    if isBombVisible or countEnemiesNearby >= 2 then
        self.tellRotateTimer:restart()

        local nearestBombSite = ai.nodegraph:getNearestSiteName(tellEnemy:getOrigin())

        if Menu.useChatCommands:get() then
            Messenger.send(string.format(" go %s", nearestBombSite), true)
        end

        local color = nearestBombSite == "a" and ai.radio.color.BLUE or ai.radio.color.PURPLE

        ai.radio:speak(ai.radio.message.HELP, 1, 1, 2, "Please %srotate%s to %sbombsite %s%s!", ai.radio.color.YELLOW, ai.radio.color.DEFAULT, color , nearestBombSite:upper(), ai.radio.color.DEFAULT)

        if not AiUtility.isLastAlive then
            ai.voice.pack:speakRequestTeammatesToRotate(nearestBombSite)
        end
    end
end

--- @param player Player
--- @param range number
--- @param reason string
--- @return void
function AiStateEngage:noticeEnemy(player, range, reason)
    if not AiUtility.client:isAlive() or not self.ignoreDormancyTimer:isElapsed(self.ignoreDormancyTime) then
        return
    end

    if player:isTeammate() then
        return
    end

    local enemyOrigin = player:getOrigin()

    if enemyOrigin:isZero() then
        return
    end

    if AiUtility.client:getOrigin():getDistance(enemyOrigin) > range then
        return
    end

    self.noticedPlayerTimers[player.eid]:start()
end

--- @param player Player
--- @return void
function AiStateEngage:unnoticeEnemy(player)
    self.noticedPlayerTimers[player.eid]:stop()
end

--- @return boolean
function AiStateEngage:hasNoticedEnemies()
    local ignorePlayerAfter = Client.hasBomb() and 3 or self.ignorePlayerAfter

    for _, enemy in pairs(AiUtility.enemies) do
        local timer = self.noticedPlayerTimers[enemy.eid]

        if timer:isStarted() and not timer:isElapsed(ignorePlayerAfter) then
            return true
        end
    end

    return false
end

--- @param enemy WeaponFireOnEmptyEvent
--- @return boolean
function AiStateEngage:hasNoticedEnemy(enemy)
    local timer = self.noticedPlayerTimers[enemy.eid]

    return timer:isStarted() and not timer:isElapsed(self.ignorePlayerAfter)
end

--- @return void
function AiStateEngage:unnoticeAllEnemies()
    for i = 1, 64 do
        self.noticedPlayerTimers[i]:stop()
    end
end

--- @return Player
function AiStateEngage:setBestTarget()
    if self.sprayTimer:isStarted() and not self.sprayTimer:isElapsed(self.sprayTime) then
        return
    end

    --- @type Player
    local selectedEnemy
    local lowestFov = math.huge
    local closestDistance = math.huge
    local player = AiUtility.client
    local origin = player:getOrigin()

    for _, enemy in pairs(AiUtility.enemies) do
        if enemy:m_bIsDefusing() == 1 then
            selectedEnemy = enemy

            break
        end

        if self:hasNoticedEnemy(enemy) then
            local distance = origin:getDistance(enemy:getOrigin())

            if distance < closestDistance then
                closestDistance = distance
                selectedEnemy = enemy
            end
        end
    end

    for _, enemy in pairs(AiUtility.visibleEnemies) do
        if enemy:m_bIsDefusing() == 1 then
            selectedEnemy = enemy

            break
        end

        local fov = AiUtility.enemyFovs[enemy.eid]

        if fov < 55 then
            self:noticeEnemy(enemy, Vector3.MAX_DISTANCE, "In field of view")
        end

        if self:hasNoticedEnemy(enemy) and fov < lowestFov then
            lowestFov = fov
            selectedEnemy = enemy
        end
    end

    if self.bestTarget and not self.bestTarget:isAlive() then
        self.watchTimer:stop()
    end

    if (selectedEnemy and self.bestTarget) and not selectedEnemy:is(self.bestTarget) then
        self.preAimOriginTimer:elapse()
    end

    self:setWeaponStats(selectedEnemy)

    self.bestTarget = selectedEnemy

    if self.bestTarget and AiUtility.visibleEnemies[self.bestTarget.eid] then
        self.watchTimer:ifPausedThenStart()
    end
end

--- @class AiStateEngageWeaponStats
--- @field name string
--- @field ranges table
--- @field firerates table
--- @field runAtCloseRange boolean
--- @field closeRange number
--- @field priorityHitbox number
--- @field isBoltAction boolean
--- @field isRcsEnabled table
--- @field evaluate fun(): boolean
---
--- @param enemy Player
--- @return void
function AiStateEngage:setWeaponStats(enemy)
    if not enemy then
        return
    end

    local player = AiUtility.client
    local weapon = player:getWeapon()
    local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]

    --- @type AiStateEngageWeaponStats[]
    local weaponTypes = {
        {
            name = "LMG",
            ranges = {
                long = 2,
                medium = 1,
                short = 0
            },
            firerates = {
                long = 0,
                medium = 0,
                short = 0
            },
            isRcsEnabled = {
                long = true,
                medium = true,
                short = true
            },
            runAtCloseRange = true,
            closeRange = 512,
            priorityHitbox = Player.hitbox.NECK,
            evaluate = function()
                return player:isHoldingLmg()
            end
        },
        {
            name = "Auto-Sniper",
            ranges = {
                long = 2000,
                medium = 1500,
                short = 0
            },
            firerates = {
                long = 0.12,
                medium = 0.06,
                short = 0
            },
            isRcsEnabled = {
                long = false,
                medium = true,
                short = true
            },
            runAtCloseRange = true,
            closeRange = 1024,
            priorityHitbox = Player.hitbox.NECK,
            evaluate = function()
                return player:isHoldingWeapons({
                    Weapons.SCAR20,
                    Weapons.G3SG1
                })
            end
        },
        {
            name = "Rifle",
            ranges = {
                long = 1500,
                medium = 1000,
                short = 0
            },
            firerates = {
                long = 0.2,
                medium = 0.16,
                short = 0
            },
            isRcsEnabled = {
                long = true,
                medium = true,
                short = true
            },
            runAtCloseRange = false,
            closeRange = 0,
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return player:isHoldingRifle()
            end
        },
        {
            name = "Desert Eagle",
            ranges = {
                long = 750,
                medium = 300,
                short = 0
            },
            firerates = {
                long = 0.64,
                medium = 0.45,
                short = 0.1
            },
            isRcsEnabled = {
                long = false,
                medium = false,
                short = true
            },
            runAtCloseRange = false,
            closeRange = 0,
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return csgoWeapon.name == "Desert Eagle"
            end
        },
        {
            name = "Revolver",
            ranges = {
                long = 2000,
                medium = 1000,
                short = 0
            },
            firerates = {
                long = 0,
                medium = 0,
                short = 0
            },
            isRcsEnabled = {
                long = false,
                medium = false,
                short = false
            },
            runAtCloseRange = false,
            closeRange = 0,
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return csgoWeapon.name == "R8 Revolver"
            end
        },
        {
            name = "Pistol",
            ranges = {
                long = 1250,
                medium = 650,
                short = 0
            },
            firerates = {
                long = 0.36,
                medium = 0.14,
                short = 0.04
            },
            isRcsEnabled = {
                long = true,
                medium = true,
                short = true
            },
            runAtCloseRange = true,
            closeRange = 600,
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return player:isHoldingPistol()
            end
        },
        {
            name = "SMG",
            ranges = {
                long = 1250,
                medium = 1000,
                short = 0
            },
            firerates = {
                long = 0.18,
                medium = 0.13,
                short = 0
            },
            isRcsEnabled = {
                long = true,
                medium = true,
                short = true
            },
            runAtCloseRange = true,
            closeRange = 900,
            priorityHitbox = Player.hitbox.NECK,
            evaluate = function()
                return player:isHoldingSmg()
            end
        },
        {
            name = "AWP",
            ranges = {
                long = 2000,
                medium = 1000,
                short = 0
            },
            firerates = {
                long = 0,
                medium = 0,
                short = 0
            },
            isRcsEnabled = {
                long = false,
                medium = false,
                short = false
            },
            runAtCloseRange = false,
            closeRange = 0,
            priorityHitbox = Player.hitbox.SPINE_2,
            isBoltAction = true,
            evaluate = function()
                return csgoWeapon.name == "AWP"
            end
        },
        {
            name = "Scout",
            ranges = {
                long = 2000,
                medium = 1000,
                short = 0
            },
            firerates = {
                long = 0,
                medium = 0,
                short = 0
            },
            isRcsEnabled = {
                long = false,
                medium = false,
                short = false
            },
            runAtCloseRange = false,
            closeRange = 0,
            priorityHitbox = Player.hitbox.HEAD,
            isBoltAction = true,
            evaluate = function()
                return csgoWeapon.name == "SSG 08"
            end
        },
    }

    --- @type AiStateEngageWeaponStats
    local selectedWeaponType

    for _, weaponType in pairs(weaponTypes) do
        if weaponType.evaluate() then
            selectedWeaponType = weaponType

            break
        end
    end

    if not selectedWeaponType then
        return
    end

    local distance = player:getOrigin():getDistance(enemy:getOrigin())

    if distance >= selectedWeaponType.ranges.long then
        self.tapFireTime = selectedWeaponType.firerates.long
        self.isRcsEnabled = selectedWeaponType.isRcsEnabled.long
    elseif distance >= selectedWeaponType.ranges.medium then
        self.tapFireTime = selectedWeaponType.firerates.medium
        self.isRcsEnabled = selectedWeaponType.isRcsEnabled.medium
    elseif distance >= selectedWeaponType.ranges.short then
        self.tapFireTime = selectedWeaponType.firerates.short
        self.isRcsEnabled = selectedWeaponType.isRcsEnabled.short
    else
        self.tapFireTime = 0
        self.isRcsEnabled = true
    end

    self.activeWeapon = selectedWeaponType.name
    self.priorityHitbox = selectedWeaponType.priorityHitbox
    self.canAutoStop = selectedWeaponType.runAtCloseRange and distance < selectedWeaponType.closeRange

    if selectedWeaponType.runAtCloseRange then
        self.canAutoStop = distance >= selectedWeaponType.closeRange
    else
        self.canAutoStop = true
    end
end

--- @return void
function AiStateEngage:render()
    if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableAimbot:get() or not Menu.visualiseAimbot:get() then
        return
    end

    local player = AiUtility.client

    if not player:isAlive() then
        return
    end

    local screenDimensions = Client.getScreenDimensions()
    local uiPos = Vector2:new(screenDimensions.x - 50, 20)

    local kd = string.format(
        "%i / %i (%i KD)",
        player:m_iKills(), player:m_iDeaths(), player:getKdRatio()
    )

    local kdColor = Color:hsla(0, 0.8, 0.6):setHue(Math.clamp(Math.pct(player:getKdRatio(), 2), 0, 1) * 100)

    self:renderText(uiPos, kdColor, kd)
    self:renderTimer("REACT", uiPos, self.reactionTimer, self.currentReactionTime)
    self:renderTimer("BLOCK", uiPos, self.blockTimer, self.blockTime)
    self:renderTimer("WATCH", uiPos, self.watchTimer, self.watchTime)
    self:renderTimer("SEE", uiPos, self.enemyVisibleTimer, self.enemyVisibleTime)
    self:renderTimer("PRE-AIM", uiPos, self.preAimAroundCornersTimer, self.preAimAroundCornersTime)
    self:renderTimer("SPRAY", uiPos, self.sprayTimer, self.sprayTime)
    self:renderTimer("TAPPING", uiPos, self.tapFireTimer, self.tapFireTime)
    self:renderTimer("IGNORE DORMANCY", uiPos, self.ignoreDormancyTimer, self.ignoreDormancyTime)
    self:renderEmpty(uiPos)

    if self.activeWeapon then
        self:renderText(uiPos, nil, "Weapon: %s", self.activeWeapon)
    end

    self:renderText(uiPos, nil, "Aim speed (in aim): %.2f", self.aimSpeed)
    self:renderText(uiPos, nil, "Aim speed (in aquire): %.2f", self.slowAimSpeed)
    self:renderText(uiPos, nil, self.isSneaking and "SNEAKING" or "RUNNING")

    self:renderEmpty(uiPos)

    if self.bestTarget then
        local color

        if AiUtility.visibleEnemies[self.bestTarget.eid] then
            color = Color:hsla(100, 0.8, 0.6)
        else
            color = Color:hsla(0, 0.8, 0.6)
        end

        self:renderText(uiPos, color, "Target: %s", self.bestTarget:getName())
    end

    self:renderEmpty(uiPos)

    for _, enemy in pairs(AiUtility.enemies) do
        local text = "%s %s"

        local color

        local status

        if AiUtility.visibleEnemies[enemy.eid] and not self:hasNoticedEnemy(enemy) then
            color = Color:hsla(60, 0.8, 0.6)
            status = "(BEHIND)"
        elseif AiUtility.visibleEnemies[enemy.eid] then
            color = Color:hsla(100, 0.8, 0.6)
            status = "(VISIBLE)"
        elseif self:hasNoticedEnemy(enemy) then
            color = Color:hsla(40, 0.8, 0.6)
            status = "(NOTICED)"
        else
            color = Color:hsla(0, 0.8, 0.6)
            status = "(UNKNOWN)"
        end

        self:renderTimer(string.format(text, enemy:getName(), status), uiPos, self.noticedPlayerTimers[enemy.eid], self.ignorePlayerAfter, color)
    end
end

--- @param uiPos Vector2
--- @return void
function AiStateEngage:renderEmpty(uiPos)
    local offset = 30
    uiPos:offset(0, offset)
end

--- @param uiPos Vector2
--- @param color Color
--- @vararg string
--- @return void
function AiStateEngage:renderText(uiPos, color, ...)
    local offset = 25

    color = color or Color:hsla(0, 0, 0.9)

    uiPos:drawSurfaceText(Font.MEDIUM, color, "r", string.format(...))

    uiPos:offset(0, offset)
end

--- @param title string
--- @param uiPos Vector2
--- @param timer Timer
--- @param time number
--- @return void
function AiStateEngage:renderTimer(title, uiPos, timer, time, color)
    local offset = 25
    local pct = math.min(1, timer:get() / time)
    local color = color or Color:hsla(0, 0, 0.9)
    local timerColor = Color:hsla(100 * pct, 0.8, 0.6)
    local timerBgColor = Color:hsla(100 * pct, 0.4, 0.2, 100)

    uiPos:drawSurfaceText(Font.MEDIUM, color, "r", string.format(
        "%s - %.2f / %.2f",
        title,
        timer:get() < time and timer:get() or time,
        time
    ))

    uiPos:clone():offset(20, 10)
         :drawCircle(12, timerBgColor)
         :drawCircleOutline(10, 3, timerColor, 180, pct)

    uiPos:offset(0, offset)
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:walk(ai)
    local player = AiUtility.client
    local canWalk
    local playerEid = Client.getEid()

    if self.bestTarget and AiUtility.closestEnemy then
        local eyeOrigin = Client.getEyeOrigin()
        local predictedEyeOrigin = eyeOrigin + player:m_vecVelocity() * 0.8

        predictedEyeOrigin = eyeOrigin:getTraceLine(predictedEyeOrigin, playerEid)

        local _, fraction, eid = predictedEyeOrigin:getTraceLine(self.bestTarget:getHitboxPosition(Player.hitbox.NECK), playerEid)
        local enemyOrigin = AiUtility.closestEnemy:getOrigin()
        local distance = eyeOrigin:getDistance(enemyOrigin)

        if player:isCounterTerrorist() and AiUtility.plantedBomb and distance > 350 then
            canWalk = false
        elseif eid == self.bestTarget.eid or fraction == 1 then
            canWalk = false
        elseif distance < 1200 then
            canWalk = true
        end
    end

    if self.walkCheckTimer:isElapsedThenRestart(0.15) then
        self.walkCheckCount = Math.clamp(self.walkCheckCount - 1, 0, 20)
    end

    if self.walkCheckCount >= 10 then
        canWalk = false
    end

    if AiUtility.isBombBeingDefusedByEnemy then
        canWalk = false
    end

    self.isSneaking = canWalk

    if canWalk then
        ai.controller.isWalking = true
    end
end

--- @param ai AiOptions
--- @return boolean
function AiStateEngage:canHoldAngle(ai)
    -- Activates if the enemy is near a corner, but not too close to it.
    if not self.isPreAimViableForHoldingAngle then
        return false
    end

    -- Don't hold if the enemy is planting or has planted the bomb.
    if AiUtility.client:isCounterTerrorist() and not AiUtility.plantedBomb and not AiUtility.isBombBeingPlantedByEnemy then
        return true
    end

    -- We have to have a cooldown, or you can immediately trigger the AI back into holding the angle.
    if self.patienceCooldownTimer:isStarted() and not self.patienceCooldownTimer:isElapsed(8) then
        return false
    end

    -- Don't hold if the enemy is defusing the bomb.
    if AiUtility.client:isTerrorist() and not AiUtility.isBombBeingDefusedByEnemy then
        -- Don't hold the angle forever.
        if self.patienceTimer:isElapsed(6) then
            self.patienceCooldownTimer:restart()

            return false
        end

        local clientOrigin = AiUtility.client:getOrigin()
        local distanceToSite = ai.nodegraph:getNearestSiteNode(clientOrigin).origin:getDistance(clientOrigin)
        local isNearPlantedBomb = AiUtility.plantedBomb and AiUtility.client:getOrigin():getDistance(AiUtility.plantedBomb:m_vecOrigin()) < 512

        -- Please don't hold angles if we have to plant.
        if AiUtility.bombCarrier and not AiUtility.bombCarrier:is(AiUtility.client) then
            return true
        end

        -- Good enough situation to hold as a T.
        -- We don't do it outside of sites because we should really be pushing the enemy at this stage.
        if isNearPlantedBomb or distanceToSite < 700 then
            return true
        end
    end

    -- It's best to just push the enemy.
    return false
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:engage(ai)
    self:attack(ai)

    if not self.bestTarget then
        return
    end

    local targetOrigin = self.bestTarget:getOrigin()

    if self.lastBestTargetOrigin and self.bestTarget:getFlag(Player.flags.FL_ONGROUND) and targetOrigin:getDistance(self.lastBestTargetOrigin) > 128 then
        ai.nodegraph:clearPath("Enemy moved")
    end

    -- Don't peek the angle. Hold it.
    if self:canHoldAngle(ai) then
        if ai.nodegraph.path then
            self.isHoldingAngle = Client.getChance(2)
            self.isHoldingAngleDucked = Client.getChance(4)

            if self.isHoldingAngle then
                ai.nodegraph:clearPath("Enemy is around corner")
            end
        end

        if self.isHoldingAngle then
            self.patienceTimer:ifPausedThenStart()

            if self.isHoldingAngleDucked then
                ai.cmd.in_duck = 1
            else
                if self.jiggleTimer:isElapsedThenRestart(self.jiggleTime) then
                    self.jiggleDirection = self.jiggleDirection == "Left" and "Right" or "Left"
                end

                --- @type Vector3
                local direction

                if self.jiggleDirection == "Left" then
                    direction = Client.getCameraAngles():getLeft()
                else
                    direction = Client.getCameraAngles():getRight()
                end

                ai.nodegraph.moveSpeed = 450
                ai.nodegraph.moveYaw = direction:getAngleFromForward().y
            end

            return
        else
            self.patienceTimer:stop()
        end
    end

    if not ai.nodegraph.path and ai.nodegraph:canPathfind() then
        local targetEyeOrigin = self.bestTarget:getEyeOrigin()

        --- @type Node[]
        local selectedNodes = {}
        --- @type Node
        local closestNode
        local closestNodeDistance = math.huge

        -- Find a nearby node that is visible to the enemy.
        for _, node in pairs(ai.nodegraph.nodes) do
            local distance = targetOrigin:getDistance(node.origin)

            -- Determine closest node. This is our backup in case there's no visible nodes.
            if distance < closestNodeDistance then
                closestNodeDistance = distance
                closestNode = node
            end

            -- Find a visible node nearby.
            if not self.isPathfindingDirectlyToEnemy and distance < 512 then
                local trace = Trace.getLineToPosition(targetEyeOrigin, node.origin, AiUtility.traceOptionsPathfinding)

                if not trace.isIntersectingGeometry then
                    table.insert(selectedNodes, node)
                end
            end
        end

        -- We can pathfind to a node visible to the enemy.
        if not Table.isEmpty(selectedNodes) then
            ai.nodegraph:pathfind(Table.getRandom(selectedNodes).origin, {
                objective = Node.types.ENEMY,
                ignore = self.bestTarget.eid,
                task = string.format("Engage (vis) %s", self.bestTarget:getName())
            })

            self.lastBestTargetOrigin = targetOrigin

            return
        end

        -- Move to the closest node to the enemy.
        if closestNode then
            ai.nodegraph:pathfind(closestNode.origin, {
                objective = Node.types.ENEMY,
                ignore = self.bestTarget.eid,
                task = string.format("Engage (pxy) %s", self.bestTarget:getName())
            })

            self.lastBestTargetOrigin = targetOrigin
        end
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:attack(ai)
    if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableAimbot:get() then
        return
    end

    -- Prevent certain generic behaviours
    ai.controller.canUseKnife = false
    ai.controller.canAntiBlock = false
    ai.controller.canInspectWeapon = false

    -- Prevent reloading when enemies visible
    if next(AiUtility.visibleEnemies) then
        ai.controller.canReload = false
        ai.controller.canUnscope = false
    end

    local player = AiUtility.client

    -- Spray
    if self.sprayTimer:isStarted() and not self.sprayTimer:isElapsed(self.sprayTime) then
        ai.controller.canReload = false

        self:shoot(ai, self.watchOrigin, 3, self.bestTarget)
    end

    -- Reset reaction delay
    if not next(AiUtility.visibleEnemies) then
        self.reactionTimer:stop()
    end

    -- Ignore unnoticed enemies
    if not self:hasNoticedEnemies() then
        return
    end

    -- Block overpowered spray transfers
    if not self.blockTimer:isElapsed(self.blockTime) then
        ai.controller.canReload = false

        return
    end

    -- Swap guns when out of ammo.
    if self.lastPriority == AiState.priority.ENGAGE_VISIBLE then
        local weapon = Entity:create(player:m_hActiveWeapon())
        local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
        local ammo = weapon:m_iClip1()
        local maxAmmo = csgoWeapon.primary_clip_size
        local ammoLeftRatio = ammo / maxAmmo

        if ammoLeftRatio == 0 then
            if AiUtility.client:isHoldingPrimary() then
                Client.equipPistol()
            end
        end
    elseif self.lastPriority == AiState.priority.ENGAGE_NEARBY then
        -- Ensure bot is holding a weapon
        if not player:isHoldingGun() or player:isHoldingPistol() then
            Client.equipAnyWeapon()
        end
    end

    -- Enemy
    local enemy = self.bestTarget

    -- Prevent reloading
    if self.watchTimer:isStarted() and not self.watchTimer:isElapsed(self.watchTime) then
        ai.controller.canReload = false
    end

    -- Watch last known position
    if not enemy then
        self:watchAngle(ai)

        return
    end

    self.shootAtOrigin = enemy:getEyeOrigin() + Vector3:new(
        Animate.sine(0, 22, 3),
        Animate.sine(0, 22, 2),
        Animate.sine(0, 8, 2.5)
    )

    -- Ensure player is holding weapon
    if not player:isHoldingGun() then
        Client.equipAnyWeapon()
    end

    -- Shoot while blind
    if Client.isFlashed() and AiUtility.visibleEnemies[enemy.eid] then
        self:shoot(ai, self.shootAtOrigin, 10, enemy)

        return
    end

    -- Shoot through smokes
    if self:shootThroughSmokes(ai, enemy) then
        return
    end

    -- Shoot last position
    if not next(AiUtility.visibleEnemies) and self.watchOrigin then
        self:watchAngle(ai)
    end

    if not AiUtility.visibleEnemies[enemy.eid] then
        local eyeOrigin = Client.getEyeOrigin()
        local wallbangOrigin = enemy:getOrigin():offset(0, 0, 48)
        local eid, dmg = eyeOrigin:getTraceBullet(wallbangOrigin, Client.getEid())
        local lastSeenAgo = self.noticedPlayerTimers[enemy.eid]:get()

        print(dmg)

        if eid == enemy.eid and dmg > 10 and lastSeenAgo < 1.5 then
            Client.draw(Vector3.drawCircleOutline, self.shootAtOrigin, 12, 2, Color:hsla(30, 1, 0.5, 200))

            self:shoot(ai, self.shootAtOrigin, self:getShootFov(Client.getCameraAngles(), eyeOrigin, wallbangOrigin))

            return
        end
    end

    -- Get target hitbox
    local hitbox, visibleHitboxCount = self:getHitbox(enemy)

    -- Pre-aim angle
    -- Pre-aim hitbox when peeking
    if self:hasNoticedEnemy(enemy) then
        self:preAimAboutCorners(ai)
        self:preAimThroughCorners(ai)
    end

    if not hitbox then
        return
    end

    -- Wide-peek enemies
    self:ferrariPeek(ai)

    self.isTargetEasilyShot = visibleHitboxCount >= 8

    -- Begin watching last angle
    if AiUtility.visibleEnemies[enemy.eid] then
        if hitbox then
            self.watchOrigin = hitbox
        end

        self.enemyVisibleTimer:ifPausedThenStart()
    else
        self.enemyVisibleTimer:stop()
    end

    local lastSeenEnemyTimer = self.lastSeenTimers[enemy.eid]

    self.currentReactionTime = (lastSeenEnemyTimer:isStarted() and not lastSeenEnemyTimer:isElapsed(2)) and self.anticipateTime or self.reactionTime

    local eyeOrigin = Client.getEyeOrigin()
    local shootFov = self:getShootFov(Client.getCameraAngles(), eyeOrigin, hitbox)

    -- Begin reaction timer
    if AiUtility.visibleEnemies[enemy.eid] and (self:hasNoticedEnemy(enemy) or shootFov < 35) then
        self.reactionTimer:ifPausedThenStart()
    end

    if AiUtility.visibleEnemies[enemy.eid] then
        -- Do not look away from flashbangs
        ai.controller.canLookAwayFromFlash = false
    end

    -- Make sure the default mouse movement isn't active while the enemy is visible but the reaction timer hasn't elapsed.
    if AiUtility.visibleEnemies[enemy.eid] and shootFov < 40 then
        ai.view:lookAtLocation(hitbox, 2.5)
        Client.draw(Vector3.drawCircleOutline, hitbox, 12, 2, Color:hsla(50, 1, 0.5, 200))
    end

    -- React to visible enemy
    if self.reactionTimer:isElapsed(self.currentReactionTime) and AiUtility.visibleEnemies[enemy.eid] then
        if shootFov < 12 then
            ai.controller.canLookAwayFromFlash = false

            self.sprayTimer:start()
            self.watchTimer:start()
            self.lastSeenTimers[enemy.eid]:start()

            self:noticeEnemy(enemy, 4096, "In shoot FoV")
            self:shoot(ai, hitbox, shootFov, enemy)
        elseif shootFov < 40 then
            ai.view:lookAtLocation(hitbox, self.aimSpeed * 0.8)

            self.watchTimer:start()
            self.lastSeenTimers[enemy.eid]:start()
        elseif shootFov >= 40 and self:hasNoticedEnemy(enemy) then
            ai.view:lookAtLocation(hitbox, self.slowAimSpeed)
        end
    end
end

--- @param angle Angle
--- @param vectorA Vector3
--- @param vectorB Vector3
--- @return number
function AiStateEngage:getShootFov(angle, vectorA, vectorB)
    local distance = vectorA:getDistance(vectorB)
    local fov = angle:getFov(vectorA, vectorB)

    return Math.clamp(Math.pct(distance, 512), 0, 90) * fov
end

--- @param ai AiOptions
--- @param hitbox Vector3
--- @param fov number
--- @param enemy Player
--- @return void
function AiStateEngage:shoot(ai, hitbox, fov, enemy)
    if not hitbox then
        return
    end

    ai.nodegraph.canJump = false

    self.hitboxOffset = Vector3:new(
        Animate.sine(0, self.aimOffset, 3.1),
        Animate.sine(0, self.aimOffset, 2.3),
        Animate.sine(0, self.aimOffset / 3, 4)
    )

    local eyeOrigin = Client.getEyeOrigin()
    local player = AiUtility.client

    local aimAt = hitbox + self.hitboxOffset

    if enemy then
        if enemy:isDormant() then
            return
        end

        local trace = Trace.getLineToPosition(eyeOrigin, hitbox, AiUtility.traceOptionsAttacking)

        if trace.isIntersectingGeometry then
            return
        end
    end

    local distance = eyeOrigin:getDistance(hitbox)
    local fireDelay = 1

    if distance > 1500 then
        fireDelay = 0.4
    elseif distance > 1000 then
        fireDelay = 0.3
    elseif distance > 500 then
        fireDelay = 0.25
    else
        fireDelay = 0.15
    end

    if player:isHoldingSniper() then
        if self.scopedTimer:isElapsed(fireDelay * 0.4) then
            ai.view.isCrosshairFloating = false

            ai.view:lookAtLocation(aimAt, self.aimSpeed * 3)
        end
    else
        ai.view.isCrosshairFloating = false

        ai.view:lookAtLocation(aimAt, self.aimSpeed)
    end

    -- Do not shoot teammates
    local clientEyeOrigin = Client.getEyeOrigin()
    local distanceToHitbox = clientEyeOrigin:getDistance(aimAt)
    local correctedAngles = Client.getCameraAngles() + AiUtility.client:m_aimPunchAngle() * 2
    local box = (clientEyeOrigin + correctedAngles:getForward() * distanceToHitbox):getBox(Vector3.align.CENTER, 16)

    for _, vertex in pairs(box) do
        local trace = Trace.getLineToPosition(clientEyeOrigin, vertex, {
            skip = function(eid)
                -- Ignore client
                if eid == entity.get_local_player() then
                    return true
                end

                -- Ignore non-player entities
                if eid < 0 or eid > 64 then
                    return true
                end

                -- Collide with teammates
                if not entity.is_enemy(eid) then
                    return false
                end

                -- Ignore enemies
                return true
            end,
            mask = Trace.mask.SHOT,
            type = Trace.type.ENTITIES_ONLY
        })

        if trace.isIntersectingGeometry then
            return
        end
    end

    -- Auto-stop
    if fov < 20 then
        self:autoStop(ai)
    end

    -- RCS
    ai.view.isRcsEnabled = self.isRcsEnabled

    -- Scope
    if player:isHoldingSniper() and fov < 8 then
        Client.scope()
    end

    if player:m_vecVelocity():getMagnitude() > 100 then
        return
    end

    local weapon = Entity:create(player:m_hActiveWeapon())
    local ammo = weapon:m_iClip1()

    if player:isHoldingSniper() then
        local fireUnderVelocity = CsgoWeapons[weapon:m_iItemDefinitionIndex()].max_player_speed / 5

        if player:m_vecVelocity():getMagnitude() < fireUnderVelocity and
            self.scopedTimer:isElapsed(fireDelay) and
            player:m_bIsScoped() == 1 and
            (fov and fov < 3)
        then
            ai.cmd.in_attack = 1
        end
    else
        ai.view.recoilControl = self.recoilControl

        if ammo and ammo > 0 then
            if self.tapFireTimer:isElapsedThenRestart(self.tapFireTime) then
               ai.cmd.in_attack = 1
            end
        end
    end
end

--- @param enemy Player
--- @return Vector3, number
function AiStateEngage:getHitbox(enemy)
    --- @type Vector3
    local targetHitbox
    local hitboxes = {
        Player.hitbox.HEAD,
        Player.hitbox.NECK,
        Player.hitbox.SPINE_3,
        Player.hitbox.SPINE_2,
        Player.hitbox.SPINE_1,
        Player.hitbox.SPINE_0,
        Player.hitbox.PELVIS,
        Player.hitbox.LEFT_UPPER_ARM,
        Player.hitbox.LEFT_UPPER_LEG,
        Player.hitbox.RIGHT_UPPER_ARM,
        Player.hitbox.RIGHT_UPPER_LEG,
    }

    local hitboxesPriority = {
        [Player.hitbox.HEAD] = 1,
        [Player.hitbox.NECK] = 2,
        [Player.hitbox.SPINE_3] = 3,
        [Player.hitbox.SPINE_2] = 4,
        [Player.hitbox.SPINE_1] = 5,
        [Player.hitbox.SPINE_0] = 6,
        [Player.hitbox.PELVIS] = 7,
        [Player.hitbox.LEFT_UPPER_ARM] = 8,
        [Player.hitbox.LEFT_UPPER_LEG] = 9,
        [Player.hitbox.RIGHT_UPPER_ARM] = 10,
        [Player.hitbox.RIGHT_UPPER_LEG] = 11,
    }

    local eyeOrigin = Client.getEyeOrigin()
    local visibleHitboxCount = 0
    local bestHitbox = math.huge
    local isPriorityHitboxVisible = false

    for hitboxId, hitbox in pairs(enemy:getHitboxPositions(hitboxes)) do
        local hitboxPriority = hitboxesPriority[hitboxId]
        local trace = Trace.getLineToPosition(eyeOrigin, hitbox, AiUtility.traceOptionsAttacking)

        if not trace.isIntersectingGeometry then
            visibleHitboxCount = visibleHitboxCount + 1
        end

        if not isPriorityHitboxVisible then
            if hitboxId == self.priorityHitbox and not trace.isIntersectingGeometry then
                targetHitbox = hitbox
                isPriorityHitboxVisible = true
            elseif not trace.isIntersectingGeometry and hitboxPriority < bestHitbox then
                bestHitbox = hitboxPriority
                targetHitbox = hitbox
            end
        end
    end

    self.isVisibleToAimSystem = visibleHitboxCount > 0

    return targetHitbox, visibleHitboxCount
end

--- @param ai AiOptions
--- @param enemy Player
--- @return boolean
function AiStateEngage:shootThroughSmokes(ai, enemy)
    local cameraAngles = Client.getCameraAngles()
    local eyeOrigin = Client.getEyeOrigin()

    -- Shoot through smokes / walls
    local testHitbox = enemy:getHitboxPosition(Player.hitbox.PELVIS)
    local testOrigin = eyeOrigin:getTraceLine(testHitbox, Client.getEid())
    local isOccludedBySmoke = eyeOrigin:isRayIntersectingSmoke(testOrigin)
    local isClose = testOrigin:getDistance(testHitbox) < 46

    if isOccludedBySmoke
        and isClose
        and not AiUtility.visibleEnemies[self.bestTarget.eid]
        and self.shootAtOrigin
        and not self.lastSoundTimer:isElapsed(2)
    then
        local fov = cameraAngles:getFov(eyeOrigin, self.shootAtOrigin)
        local shootFov = Math.clamp(Math.pct(eyeOrigin:getDistance(self.shootAtOrigin), 512), 0, 90) * fov

        if self.noticedPlayerTimers[enemy.eid]:get() < 2 then
            self:shoot(ai, self.shootAtOrigin, shootFov, self.bestTarget)
        else
            ai.view:lookAtLocation(self.shootAtOrigin, self.slowAimSpeed)
        end

        return true
    else
        return false
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:ferrariPeek(ai)
    local enemy = self.bestTarget

    if not enemy then
        return
    end

    local player = AiUtility.client
    local playerEid = Client.getEid()
    local playerOrigin = player:getOrigin()
    local enemyOrigin = enemy:getOrigin()
    local angleToEnemy = playerOrigin:getAngle(enemyOrigin)
    local forward = angleToEnemy:getForward()

    local directions = {
        angleToEnemy:getLeft(),
        angleToEnemy:getRight()
    }

    local startPoints = {
        forward * 16 + Vector3:new(0, 0, 18),
        forward * 16 + Vector3:new(0, 0, 64),
        forward * -16 + Vector3:new(0, 0, 18),
        forward * -16 + Vector3:new(0, 0, 64)
    }

    local isVisible = false
    local steps = 2
    local stepDistance = 16
    --- @type Angle
    local moveAngles

    local iDebug = 0
    local successes = 0

    for _, startPoint in pairs(startPoints) do
        if isVisible then
            break
        end

        for _, direction in pairs(directions) do
            if isVisible then
                break
            end

            for i = 1, steps do
                if isVisible then
                    break
                end

                local startOffset = playerOrigin + startPoint
                local traceOrigin = startOffset + (direction * i * stepDistance)
                local _, fraction = startOffset:getTraceLine(traceOrigin, playerEid)
                iDebug = iDebug + 1

                if fraction == 1 then
                    for _, hitbox in pairs(enemy:getHitboxPositions({
                        Player.hitbox.HEAD,
                        Player.hitbox.LEFT_LOWER_LEG,
                        Player.hitbox.RIGHT_LOWER_LEG,
                        Player.hitbox.LEFT_LOWER_ARM,
                        Player.hitbox.RIGHT_LOWER_ARM,
                    })) do
                        local _, fraction, eid = traceOrigin:getTraceLine(hitbox, playerEid)

                        iDebug = iDebug + 1

                        if eid == enemy.eid or fraction == 1 then
                            successes = successes + 1

                            if successes >= 3 then
                                isVisible = true
                                moveAngles = playerOrigin:getAngle(traceOrigin)

                                break
                            end

                            break
                        end
                    end
                end
            end
        end
    end

    if moveAngles then
        if player:m_vecVelocity():getMagnitude() < 50 then
            self.ferrariPeekStuckTimer:ifPausedThenStart()
        else
            self.ferrariPeekStuckTimer:stop()
        end

        if self.ferrariPeekStuckTimer:isElapsedThenStop(1) then
            self.ferrariPeekCooldownTimer:start()
        end

        if self.ferrariPeekCooldownTimer:isElapsed(5) then
            ai.nodegraph.moveSpeed = 450
            ai.nodegraph.moveYaw = moveAngles.y
        end
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:preAimThroughCorners(ai)
    local target = self.bestTarget

    if not target then
        return
    end

    if self.isVisibleToAimSystem then
        return
    end

    local player = AiUtility.client
    local clientVelocity = player:m_vecVelocity()

    if clientVelocity:getMagnitude() < 50 then
        return
    end

    if not self.preAimThroughCornerBlockTimer:isElapsed(0.8) then
        return
    end

    local playerEid = Client.getEid()
    local playerOrigin = player:getOrigin()
    local hitboxes = target:getHitboxPositions()

    -- Determine if we're about to peek the target.
    local testOrigin = Client.getEyeOrigin() + (clientVelocity * 0.4)
    local isPeeking = false

    for _, hitbox in pairs(hitboxes) do
        local _, fraction, eid = testOrigin:getTraceLine(hitbox, playerEid)

        if eid == target.eid or fraction == 1 then
            isPeeking = true

            break
        end
    end

    if not isPeeking then
        return
    end

    -- Don't pre-aim if the enemy is about to peek us.
    local targetVelocity = target:m_vecVelocity() * 0.4

    for _, hitbox in pairs(hitboxes) do
        hitbox = hitbox + targetVelocity

        local _, fraction, eid = playerOrigin:getTraceLine(hitbox, playerEid)

        if eid == target.eid or fraction == 1 then
            self.preAimThroughCornerBlockTimer:start()

            return
        end
    end

    if self.updatePreAimOriginTimer:isElapsedThenRestart(self.updatePreAimOriginTime) then
        local hitboxPosition = target:getHitboxPosition(Player.hitbox.HEAD)
        local distance = playerOrigin:getDistance(hitboxPosition)
        local offsetRange = Math.pct(Math.clamp(distance, 0, 1024), 1024) * 100

        self.preAimCornerOrigin = hitboxPosition:offset(
            Client.getRandomFloat(-offsetRange, offsetRange),
            Client.getRandomFloat(-offsetRange, offsetRange),
            Client.getRandomFloat(-8, 2)
        )
    end

    self.preAimTarget = self.bestTarget

    ai.view:lookAtLocation(self.preAimCornerOrigin, self.slowAimSpeed)
    Client.draw(Vector3.drawCircleOutline, self.preAimCornerOrigin, 16, 2, Color:hsla(100, 1, 0.5, 150))
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:preAimAboutCorners(ai)
    if not self.bestTarget or not self.bestTarget:isAlive() then
        return
    end

    if self.bestTarget:getFlag(Player.flags.FL_ONGROUND) and self.preAimOriginTimer:isElapsedThenRestart(0.5) then
        self.preAimOrigin = self.bestTarget:getOrigin():offset(0, 0, 60)
    end

    if not self.preAimOrigin then
        return
    end

    if self.isVisibleToAimSystem then
        return
    end

    local player = Player.getClient()
    local eyeOrigin = Client.getEyeOrigin()

    local bands = {
        {
            distance = 40,
            points = 8
        },
        {
            distance = 80,
            points = 16
        },
        {
            distance = 150,
            points = 32
        },
        {
            distance = 200,
            points = 32
        }
    }

    local bandDirection = eyeOrigin:getAngle(self.preAimOrigin):set(0):offset(nil, 90)
    local isVisible = false
    --- @type Vector3
    local closestVertex
    local closestVertexDistance = math.huge
    local closestBand

    for id, band in pairs(bands) do
        if isVisible then
            break
        end

        local vertexInterval = 180 / band.points

        for i = 1, band.points do
            local direction = Angle:new(0, vertexInterval * i) + (bandDirection)
            local vertex = self.preAimOrigin + (direction:getForward() * band.distance)
            local _, fraction = self.preAimOrigin:getTraceLine(vertex, self.bestTarget.eid)

            if fraction == 1 then
                local _, fraction = vertex:getTraceLine(eyeOrigin, player.eid)

                if fraction == 1 then
                    local distance = eyeOrigin:getDistance(vertex)

                    if distance < closestVertexDistance then
                        closestVertex = vertex
                        closestVertexDistance = distance

                        isVisible = true

                        closestBand = id
                    end
                end
            end
        end
    end

    if not closestVertex then
        self.isPreAimViableForHoldingAngle = false

        return
    end

    self.watchOrigin = closestVertex

    self.watchTimer:start()

    if closestBand == 2 or closestBand == 3 then
        self.isPreAimViableForHoldingAngle = true
    else
        self.isPreAimViableForHoldingAngle = false
    end

    ai.controller.canUnscope = false
    ai.view.isCrosshairFloating = false

    ai.view:lookAtLocation(closestVertex, self.slowAimSpeed)
    Client.draw(Vector3.drawCircleOutline, closestVertex, 12, 2, Color:hsla(200, 1, 0.5, 200))
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:watchAngle(ai)
    if not self.watchTimer:isStarted() then
        return
    end

    if not self.watchOrigin then
        return
    end

    if self.bestTarget and self.bestTarget:isDormant() then
        return
    end

    if self.watchTimer:isElapsedThenStop(self.watchTime) and self.sprayTimer:isElapsedThenStop(self.sprayTime) then
        self.watchOrigin = nil
    end

    ai.view:lookAtLocation(self.watchOrigin, self.aimSpeed)
    Client.draw(Vector3.drawCircleOutline, self.watchOrigin, 16, 2, Color:hsla(300, 1, 0.5, 200))
end

--- @param ai AiOptions
--- @param enemy Player
--- @return void
function AiStateEngage:pathfindBlockedEnemy(ai, enemy)
    local enemyEyeOrigin = enemy:getOrigin():offset(0, 0, 64)

    if not enemyEyeOrigin then
        return
    end

    --- @type Node
    local closestVisibleNode
    local closestDistance = math.huge
    local maxDistance = 1500

    for _, node in pairs(ai.nodegraph.nodes) do
        local distance = enemyEyeOrigin:getDistance(node.origin)

        if distance >= maxDistance then
            local _, fraction = enemyEyeOrigin:getTraceLine(node.origin, enemy.eid)

            if fraction == 1 and distance < closestDistance then
                closestDistance = distance
                closestVisibleNode = node
            end
        end
    end

    if closestVisibleNode then
        ai.nodegraph:pathfind(closestVisibleNode.origin, {
            objective = Node.types.GOAL,
            ignore = enemy.eid,
            task = "Engage enemy by proxy node",
            onFail = function()
                ai.nodegraph:log("Enemy is not in a valid position")
            end
        })
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:autoStop(ai)
    if not self.canAutoStop then
        ai.cmd.in_duck = 1

        return
    end

    local player = AiUtility.client

    if self.isTargetEasilyShot then
        ai.cmd.in_duck = 1

        local inverseVelocity = -player:m_vecVelocity()

        if inverseVelocity:getMagnitude() < 75 then
            ai.nodegraph.moveSpeed = 0

            return
        end

        local velocityAngles = inverseVelocity:normalize():getAngleFromForward()

        ai.nodegraph.moveYaw = velocityAngles.y
        ai.nodegraph.moveSpeed = 450
    else
        ai.nodegraph.moveSpeed = 0
    end
end

--- @param skill number
--- @return void
function AiStateEngage:setAimSkill(skill)
    self.skill = skill

    local skills = {
        [0] = {
            reactionTime = 0.4,
            anticipateTime = 0.2,
            sprayTime = 0.5,
            aimSpeed = 3,
            slowAimSpeed = 3,
            recoilControl = 2.5,
            aimOffset = 20
        },
        [1] = {
            reactionTime = 0.3,
            anticipateTime = 0.15,
            sprayTime = 0.5,
            aimSpeed = 4,
            slowAimSpeed = 3,
            recoilControl = 2.5,
            aimOffset = 16
        },
        [2] = {
            reactionTime = 0.25,
            anticipateTime = 0.1,
            sprayTime = 0.5,
            aimSpeed = 4,
            slowAimSpeed = 3,
            recoilControl = 2.2,
            aimOffset = 14
        },
        [3] = {
            reactionTime = 0.2,
            anticipateTime = 0.05,
            sprayTime = 0.5,
            aimSpeed = 5,
            slowAimSpeed = 4,
            recoilControl = 2.2,
            aimOffset = 12
        },
        [4] = {
            reactionTime = 0.2,
            anticipateTime = 0.05,
            sprayTime = 0.5,
            aimSpeed = 6,
            slowAimSpeed = 4,
            recoilControl = 2,
            aimOffset = 10
        },
        [5] = {
            reactionTime = 0.16,
            anticipateTime = 0.05,
            sprayTime = 0.5,
            aimSpeed = 6,
            slowAimSpeed = 4,
            recoilControl = 2,
            aimOffset = 8
        },
        [6] = {
            reactionTime = 0.14,
            anticipateTime = 0.05,
            sprayTime = 0.5,
            aimSpeed = 8,
            slowAimSpeed = 6,
            recoilControl = 2,
            aimOffset = 8
        },
        [7] = {
            reactionTime = 0.12,
            anticipateTime = 0.05,
            sprayTime = 0.33,
            aimSpeed = 10,
            slowAimSpeed = 8,
            recoilControl = 2,
            aimOffset = 6
        },
        [8] = {
            reactionTime = 0.1,
            anticipateTime = 0.05,
            sprayTime = 0.33,
            aimSpeed = 10,
            slowAimSpeed = 8,
            recoilControl = 2,
            aimOffset = 4
        },
        [9] = {
            reactionTime = 0.1,
            anticipateTime = 0.05,
            sprayTime = 0.33,
            aimSpeed = 12,
            slowAimSpeed = 8,
            recoilControl = 2,
            aimOffset = 2
        },
        [10] = {
            reactionTime = 0.0,
            anticipateTime = 0.00,
            sprayTime = 0.33,
            aimSpeed = 12,
            slowAimSpeed = 8,
            recoilControl = 2,
            aimOffset = 0
        },
    }

    for k, v in pairs(skills[skill]) do
        self[k] = v
    end
end

return Nyx.class("AiStateEngage", AiStateEngage, AiState)
--}}}
