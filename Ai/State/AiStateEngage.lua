--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local CsgoWeapons = require "gamesense/csgo_weapons"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Math = require "gamesense/Nyx/v1/Api/Math"
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
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiView = require "gamesense/Nyx/v1/Dominion/Ai/AiView"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ Enums
local WeaponMode = {
    PISTOL = 1,
    LIGHT = 2,
    SHOTGUN = 3,
    HEAVY = 4,
    SNIPER = 5,
}
--}}}

--{{{ AiStateEngage
--- @class AiStateEngage : AiState
--- @field activeWeapon string
--- @field aimInaccurateOffset number
--- @field aimNoise AiViewNoise
--- @field aimOffset number
--- @field aimSpeed number
--- @field anticipateTime number
--- @field bestTarget Player
--- @field blockTime number
--- @field blockTimer Timer
--- @field canRunAndShoot boolean
--- @field canWallbang boolean
--- @field currentReactionTime number
--- @field enemySpottedCooldown Timer
--- @field enemyVisibleTime number
--- @field enemyVisibleTimer Timer
--- @field equipPistolTimer Timer
--- @field hitboxOffset Vector3
--- @field hitboxOffsetTimer Timer
--- @field ignorePlayerAfter number
--- @field isAimEnabled boolean
--- @field isBestTargetVisible boolean
--- @field isHoldingAngle boolean
--- @field isHoldingAngleDucked boolean
--- @field isIgnoringDormancy boolean
--- @field isPreAimViableForHoldingAngle boolean
--- @field isRcsEnabled boolean
--- @field isSneaking boolean
--- @field isStrafePeeking boolean
--- @field isTargetEasilyShot boolean
--- @field isVisibleToBestTarget boolean
--- @field jiggleDirection string
--- @field jiggleTime number
--- @field jiggleTimer Timer
--- @field lastBestTargetOrigin Vector3
--- @field lastMoveDirection Vector3
--- @field lastSeenTimers Timer[]
--- @field lastSoundTimer Timer
--- @field lookAtOccludedOrigin Vector3
--- @field noticedLoudPlayerTimers Timer[]
--- @field noticedPlayerLastKnownOrigin Vector3[]
--- @field noticedPlayerTimers Timer[]
--- @field onGroundTime Timer
--- @field onGroundTimer Timer
--- @field patienceCooldownTimer Timer
--- @field patienceTimer Timer
--- @field preAimAboutCornersAimOrigin Vector3
--- @field preAimAboutCornersCenterOrigin Vector3
--- @field preAimAboutCornersUpdateTimer Timer
--- @field preAimTarget Player
--- @field preAimThroughCornersBlockTimer Timer
--- @field preAimThroughCornersOrigin Vector3
--- @field preAimThroughCornersUpdateTimer Timer
--- @field priorityHitbox number
--- @field reactionTime number
--- @field reactionTimer Timer
--- @field recoilControl number
--- @field scopedTimer Timer
--- @field seekCoverTimer Timer
--- @field setBestTargetTimer Timer
--- @field shootAtOrigin Vector3
--- @field skill number
--- @field skillLevelMax number
--- @field skillLevelMin number
--- @field slowAimSpeed number
--- @field smokeWallBangHoldTimer Timer
--- @field sprayTime number
--- @field sprayTimer Timer
--- @field strafePeekIndex number
--- @field strafePeekMoveAngle Angle
--- @field strafePeekTimer Timer
--- @field tapFireTime number
--- @field tapFireTimer Timer
--- @field tellRotateTimer Timer
--- @field visibleReactionTimer Timer
--- @field visualizerCallbacks function[]
--- @field visualizerExpiryTimers Timer[]
--- @field walkCheckCount number
--- @field walkCheckTimer Timer
--- @field watchOrigin Vector3
--- @field watchTime number
--- @field watchTimer Timer
--- @field weaponMode number
local AiStateEngage = {
    name = "Engage",
    skillLevelMin = 0,
    skillLevelMax = 10
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
    self.isAimEnabled = true
    self.anticipateTime = 0.1
    self.blockTime = 0.25
    self.blockTimer = Timer:new():startThenElapse()
    self.currentReactionTime = 0
    self.enemySpottedCooldown = Timer:new():startThenElapse()
    self.enemyVisibleTime = 0.66
    self.enemyVisibleTimer = Timer:new()
    self.equipPistolTimer = Timer:new()
    self.hitboxOffsetTimer = Timer:new():startThenElapse()
    self.ignorePlayerAfter = 20
    self.isIgnoringDormancy = false
    self.isSneaking = false
    self.jiggleDirection = "Left"
    self.jiggleTime = Client.getRandomFloat(0.33, 0.66)
    self.jiggleTimer = Timer:new():startThenElapse()
    self.lastSoundTimer = Timer:new():start()
    self.noticedPlayerTimers = {}
    self.noticedPlayerLastKnownOrigin = {}
    self.onGroundTime = 0.1
    self.onGroundTimer = Timer:new()
    self.patienceCooldownTimer = Timer:new():startThenElapse()
    self.patienceTimer = Timer:new()
    self.preAimAboutCornersUpdateTimer = Timer:new():startThenElapse()
    self.preAimOriginDelayed = Vector3:new()
    self.preAimThroughCornersBlockTimer = Timer:new():startThenElapse()
    self.preAimThroughCornersUpdateTimer = Timer:new():startThenElapse()
    self.reactionTimer = Timer:new()
    self.scopedTimer = Timer:new()
    self.setBestTargetTimer = Timer:new():startThenElapse()
    self.sprayTimer = Timer:new()
    self.tapFireTime = 0.2
    self.tapFireTimer = Timer:new():start()
    self.tellRotateTimer = Timer:new():startThenElapse()
    self.walkCheckCount = 0
    self.walkCheckTimer = Timer:new():start()
    self.watchTime = 2
    self.watchTimer = Timer:new()
    self.smokeWallBangHoldTimer = Timer:new()
    self.visibleReactionTimer = Timer:new()
    self.visualizerCallbacks = {}
    self.visualizerExpiryTimers = {}
    self.aimNoise = AiView.noiseType.MINOR
    self.seekCoverTimer = Timer:new():startThenElapse()
    self.strafePeekTimer = Timer:new():startThenElapse()
    self.strafePeekIndex = 1

    for i = 1, 64 do
        self.noticedPlayerTimers[i] = Timer:new()
    end

    self.noticedLoudPlayerTimers = {}

    for i = 1, 64 do
        self.noticedLoudPlayerTimers[i] = Timer:new()
    end

    self.lastSeenTimers = {}

    for i = 1, 64 do
        self.lastSeenTimers[i] = Timer:new()
    end

    Menu.enableAimbot = Menu.group:checkbox("    > Enable Aimbot"):setParent(Menu.enableAi)
    Menu.visualiseAimbot = Menu.group:checkbox("    > Visualise Aimbot"):setParent(Menu.enableAimbot)

    self:setAimSkill(5)
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

        if AiUtility.client:getOrigin():getDistance(e.player:getOrigin()) > 600 then
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

        if AiUtility.client:getOrigin():getDistance(e.player:getOrigin()) > 600 then
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

        self.isIgnoringDormancy = true
        self.jiggleTime = Client.getRandomFloat(0.33, 0.66)
    end)

    Callbacks.runCommand(function()
        local player = AiUtility.client
        local bomb = AiUtility.plantedBomb

        if bomb and player:isCounterTerrorist() then
            local bombOrigin = bomb:m_vecOrigin()

            for _, enemy in pairs(AiUtility.enemies) do
                if bombOrigin:getDistance(enemy:getOrigin()) < 512 then
                    self:noticeEnemy(enemy, 500, false, "Near Site")
                end
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

        self:noticeEnemy(e.attacker, Vector3.MAX_DISTANCE, true, "Shot by")
    end)

    Callbacks.playerFootstep(function(e)
        self:noticeEnemy(e.player, 1000, false, "Stepped")
    end)

    Callbacks.playerJump(function(e)
        self:noticeEnemy(e.player, 650, false, "Jumped")
    end)

    Callbacks.weaponZoom(function(e)
        self:noticeEnemy(e.player, 600, false, "Scoped")
    end)

    Callbacks.weaponReload(function(e)
        self:noticeEnemy(e.player, 800, false, "Reloaded")
    end)

    Callbacks.weaponFire(function(e)
        if CsgoWeapons[e.weapon].is_melee_weapon then
            self:noticeEnemy(e.player, 600, true, "Knifed")

            return
        end

        local range = 1600

        if AiUtility.visibleEnemies[e.player.eid] then
            range = Vector3.MAX_DISTANCE
        end

        self:noticeEnemy(e.player, range, true, "Shot")
    end)

    Callbacks.bulletImpact(function(e)
        if not e.shooter:isEnemy() then
            return
        end

        local eyeOrigin = Client.getEyeOrigin()

        local rayIntersection = eyeOrigin:getRayClosestPoint(e.shooter:getEyeOrigin(), e.origin)

        if eyeOrigin:getDistance(rayIntersection) > 300 then
            return
        end

        self:noticeEnemy(e.shooter, Vector3.MAX_DISTANCE, true, "Shot at")
    end)

    Callbacks.bombBeginDefuse(function(e)
        self:noticeEnemy(e.player, Vector3.MAX_DISTANCE, true, "Began defusing")
    end)

    Callbacks.bombBeginPlant(function(e)
        self:noticeEnemy(e.player, Vector3.MAX_DISTANCE, true, "Began planting")
    end)

    Callbacks.grenadeThrown(function(e)
        self:noticeEnemy(e.player, 500, false, "Threw grenade")
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isClient() then
            self:reset()

            return
        end

        if e.attacker:isClient() and e.victim:isEnemy() then
            self.blockTimer:start()
        end

        if e.victim:isTeammate() and AiUtility.client:getOrigin():getDistance(e.victim:getOrigin()) < 1250 then
            self:noticeEnemy(e.attacker, 1600, true, "Teammate killed")
        end

        if e.victim:isEnemy() and self.noticedPlayerTimers[e.victim.eid] then
            self.noticedPlayerTimers[e.victim.eid]:stop()
            self.noticedLoudPlayerTimers[e.victim.eid]:stop()
            self.lastSeenTimers[e.victim.eid]:stop()
        end
    end)
end

--- @return void
function AiStateEngage:assess()
    self:setBestTarget()

    self.sprayTimer:isElapsedThenStop(self.sprayTime)
    self.watchTimer:isElapsedThenStop(self.watchTime)

    local clientOrigin = AiUtility.client:getOrigin()

    -- Do not try to engage people from inside of a smoke.
    -- It looks really dumb.
    for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
        local smokeTick = smoke:m_nFireEffectTickBegin()

        if smokeTick and smokeTick > 0 and clientOrigin:getDistance(smoke:m_vecOrigin()) < 130 then
            return AiPriority.IGNORE
        end
    end

    if Client.isFlashed() and self.bestTarget and AiUtility.visibleEnemies[self.bestTarget.eid] then
        return AiPriority.ENGAGE_PANIC
    end

    if self.sprayTimer:isStarted() then
        return AiPriority.ENGAGE_ACTIVE
    end

    for _, enemy in pairs(AiUtility.enemies) do
        if AiUtility.visibleEnemies[enemy.eid] and self:hasNoticedEnemy(enemy) then
            return AiPriority.ENGAGE_ACTIVE
        end
    end

    if AiUtility.isBombBeingDefusedByEnemy then
        return AiPriority.ENGAGE_ACTIVE
    end

    if not AiUtility.plantedBomb then
        if self.reactionTimer:isStarted() then
            return AiPriority.ENGAGE_PASSIVE
        end

        if self.watchTimer:isStarted() then
            return AiPriority.ENGAGE_PASSIVE
        end
    end

    if self:hasNoticedEnemies() then
        return AiPriority.ENGAGE_PASSIVE
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateEngage:activate()
    if self.enemySpottedCooldown:isElapsedThenRestart(60) then
        local player = AiUtility.client

        if AiUtility.bombCarrier and AiUtility.bombCarrier:is(self.bestTarget) and player:isCounterTerrorist() then
            if not AiUtility.isLastAlive then
               self.ai.voice.pack:speakNotifyTeamOfBombCarrier()
            end
        else
            if not AiUtility.isLastAlive then
               self.ai.voice.pack:speakHearNearbyEnemies()
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

    self.noticedLoudPlayerTimers = {}

    for i = 1, 64 do
        self.noticedLoudPlayerTimers[i] = Timer:new()
    end

    self.lastSeenTimers = {}

    for i = 1, 64 do
        self.lastSeenTimers[i] = Timer:new()
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:think(cmd)
    if not Menu.master:get() or not Menu.enableAi:get() then
        return
    end

    self:tellRotate()
    self:walk()
    self:moveOnBestTarget(cmd)
    self:attackBestTarget(cmd)
end

--- @return void
function AiStateEngage:tellRotate()
    if not self.tellRotateTimer:isElapsed(15) then
        return
    end

    local player = AiUtility.client

    if not player:isCounterTerrorist() then
        return
    end

    local playerOrigin = player:getOrigin()

    local nearestBombSite =self.ai.nodegraph:getNearestSiteName(playerOrigin)
    local siteOrigin =self.ai.nodegraph:getSiteNode(nearestBombSite).origin

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

        local nearestBombSite =self.ai.nodegraph:getNearestSiteName(tellEnemy:getOrigin())

        if Menu.useChatCommands:get() then
            self.ai.commands.go:bark(nearestBombSite)
        end

        if not AiUtility.isLastAlive then
           self.ai.voice.pack:speakRequestTeammatesToRotate(nearestBombSite)
        end
    end
end

--- @param player Player
--- @param range number
--- @param isLoud boolean
--- @param reason string
--- @return void
function AiStateEngage:noticeEnemy(player, range, isLoud, reason)
    if not AiUtility.client:isAlive() then
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

    if isLoud then
        self.noticedLoudPlayerTimers[player.eid]:start()
    end

    self.noticedPlayerLastKnownOrigin[player.eid] = enemyOrigin
end

--- @param player Player
--- @return void
function AiStateEngage:unnoticeEnemy(player)
    if not self.noticedPlayerTimers[player.eid] then
        return
    end

    self.noticedPlayerTimers[player.eid]:stop()
    self.noticedLoudPlayerTimers[player.eid]:stop()
end

--- @return boolean
function AiStateEngage:hasNoticedEnemies()
    local ignorePlayerAfter = self.ignorePlayerAfter

    if Client.hasBomb() then
        ignorePlayerAfter = 3
    end

    for _, enemy in pairs(AiUtility.enemies) do
        local timer = self.noticedPlayerTimers[enemy.eid]

        if timer:isStarted() and not timer:isElapsed(ignorePlayerAfter) then
            return true
        end
    end

    return false
end

--- @param enemy Player
--- @return boolean
function AiStateEngage:hasNoticedEnemy(enemy)
    local timer = self.noticedPlayerTimers[enemy.eid]

    return timer:isStarted() and not timer:isElapsed(self.ignorePlayerAfter)
end

--- @param enemy Player
--- @return boolean
function AiStateEngage:hasNoticedLoudEnemy(enemy)
    local timer = self.noticedLoudPlayerTimers[enemy.eid]

    return timer:isStarted() and not timer:isElapsed(self.ignorePlayerAfter)
end

--- @return void
function AiStateEngage:unnoticeAllEnemies()
    for i = 1, 64 do
        self.noticedPlayerTimers[i]:stop()
        self.noticedLoudPlayerTimers[i]:stop()
    end
end

--- @return Player
function AiStateEngage:setBestTarget()
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
            self:noticeEnemy(enemy, Vector3.MAX_DISTANCE, false, "In field of view")
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
        self.preAimAboutCornersUpdateTimer:elapse()
    end

    self:setWeaponStats(selectedEnemy)

    self.bestTarget = selectedEnemy

    if self.bestTarget and AiUtility.visibleEnemies[self.bestTarget.eid] then
        self.watchTimer:ifPausedThenStart()
    end

    self:setIsVisibleToBestTarget()
end

--- @class AiStateEngageWeaponStats
--- @field name string
--- @field ranges table
--- @field firerates table
--- @field runAtCloseRange boolean
--- @field priorityHitbox number
--- @field isBoltAction boolean
--- @field isRcsEnabled table
--- @field weaponMode number
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
            name = "Auto-Sniper",
            weaponMode = WeaponMode.SNIPER,
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
            priorityHitbox = Player.hitbox.NECK,
            evaluate = function()
                return player:isHoldingWeapons({
                    Weapons.SCAR20,
                    Weapons.G3SG1
                })
            end
        },
        {
            name = "AWP",
            weaponMode = WeaponMode.SNIPER,
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
            priorityHitbox = Player.hitbox.SPINE_2,
            isBoltAction = true,
            evaluate = function()
                return player:isHoldingWeapon(Weapons.AWP)
            end
        },
        {
            name = "Scout",
            weaponMode = WeaponMode.SNIPER,
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
            priorityHitbox = Player.hitbox.HEAD,
            isBoltAction = true,
            evaluate = function()
                return player:isHoldingWeapon(Weapons.SSG08)
            end
        },
        {
            name = "LMG",
            weaponMode = WeaponMode.HEAVY,
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
            priorityHitbox = Player.hitbox.NECK,
            evaluate = function()
                return player:isHoldingLmg()
            end
        },
        {
            name = "Rifle",
            weaponMode = WeaponMode.HEAVY,
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
            priorityHitbox = Player.hitbox.SPINE_3,
            evaluate = function()
                return player:isHoldingRifle()
            end
        },
        {
            name = "Shotgun",
            weaponMode = WeaponMode.SHOTGUN,
            ranges = {
                long = 0,
                medium = 0,
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
            runAtCloseRange = true,
            priorityHitbox = Player.hitbox.NECK,
            evaluate = function()
                return player:isHoldingShotgun()
            end
        },
        {
            name = "SMG",
            weaponMode = WeaponMode.LIGHT,
            ranges = {
                long = 1600,
                medium = 1400,
                short = 0
            },
            firerates = {
                long = 0.15,
                medium = 0.1,
                short = 0
            },
            isRcsEnabled = {
                long = true,
                medium = true,
                short = true
            },
            runAtCloseRange = true,
            priorityHitbox = Player.hitbox.NECK,
            evaluate = function()
                return player:isHoldingSmg()
            end
        },
        {
            name = "Desert Eagle",
            -- The Deagle really cannot use pistol shooting/movement logic.
            weaponMode = WeaponMode.HEAVY,
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
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return csgoWeapon.name == "Desert Eagle"
            end
        },
        {
            name = "Revolver",
            weaponMode = WeaponMode.HEAVY,
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
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return csgoWeapon.name == "R8 Revolver"
            end
        },
        {
            name = "CZ-75",
            weaponMode = WeaponMode.LIGHT,
            ranges = {
                long = 900,
                medium = 450,
                short = 0
            },
            firerates = {
                long = 0.45,
                medium = 0.2,
                short = 0.05
            },
            isRcsEnabled = {
                long = true,
                medium = true,
                short = true
            },
            runAtCloseRange = true,
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return csgoWeapon.name == "CZ75-Auto"
            end
        },
        {
            name = "Pistol",
            weaponMode = WeaponMode.PISTOL,
            ranges = {
                long = 1300,
                medium = 750,
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
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return player:isHoldingPistol()
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

    self.weaponMode = selectedWeaponType.weaponMode
    self.activeWeapon = selectedWeaponType.name
    self.priorityHitbox = selectedWeaponType.priorityHitbox

    if selectedWeaponType.runAtCloseRange then
        self.canRunAndShoot = distance < selectedWeaponType.ranges.medium
    else
        self.canRunAndShoot = false
    end
end

--- @return void
function AiStateEngage:render()
    if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableAimbot:get() then
        return
    end

    for id, callback in pairs(self.visualizerCallbacks) do
        callback()

        if self.visualizerExpiryTimers[id]:isElapsedThenStop(0.1) then
            self.visualizerCallbacks[id] = nil
        end
    end

    if not Menu.visualiseAimbot:get() then
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

    local kdColor = Color:hsla(0, 0.8, 0.6):setHue(Math.getClamped(Math.getFloat(player:getKdRatio(), 2), 0, 1) * 100)

    self:renderText(uiPos, kdColor, kd)
    self:renderTimer("REACT", uiPos, self.reactionTimer, self.currentReactionTime)
    self:renderTimer("BLOCK", uiPos, self.blockTimer, self.blockTime)
    self:renderTimer("WATCH", uiPos, self.watchTimer, self.watchTime)
    self:renderTimer("SEE", uiPos, self.enemyVisibleTimer, self.enemyVisibleTime)
    self:renderTimer("SPRAY", uiPos, self.sprayTimer, self.sprayTime)
    self:renderTimer("TAPPING", uiPos, self.tapFireTimer, self.tapFireTime)
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

--- @param callback fun(): void
--- @return void
function AiStateEngage:addVisualizer(id, callback)
    self.visualizerCallbacks[id] = callback

    if not self.visualizerExpiryTimers[id] then
        self.visualizerExpiryTimers[id] = Timer:new()
    end

    self.visualizerExpiryTimers[id]:start()
end

--- @param uiPos Vector2
--- @param color Color
--- @vararg string
--- @return void
function AiStateEngage:renderText(uiPos, color, ...)
    local offset = 25

    color = color or Color:hsla(0, 0, 0.9)

    uiPos:drawSurfaceText(Font.SMALL, color, "r", string.format(...))

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

    uiPos:drawSurfaceText(Font.SMALL, color, "r", string.format(
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

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:moveOnBestTarget(cmd)
    if not self.bestTarget then
        return
    end

    if self.seekCoverTimer:isElapsed(1.5) and Table.isEmpty(AiUtility.visibleEnemies) then
        self.lookAtOccludedOrigin = nil

        -- Avoid too many threats.
        local isBackingUp = true

        if AiUtility.totalThreats < 2 then
            isBackingUp = false
        elseif self.isStrafePeeking then
            isBackingUp = false
        elseif AiUtility.timeData.roundtime_remaining < 40 then
            isBackingUp = false
        elseif AiUtility.client:isCounterTerrorist() then
            if AiUtility.plantedBomb or AiUtility.isBombBeingPlantedByEnemy then
                isBackingUp = false
            end

            local bombsiteA = self.ai.nodegraph.objectiveA
            local bombsiteB = self.ai.nodegraph.objectiveB

            for _, enemy in pairs(AiUtility.enemies) do
                local enemyOrigin = enemy:getOrigin()

                if enemyOrigin:getDistance(bombsiteA.origin) < 800 or enemyOrigin:getDistance(bombsiteB.origin) < 800 then
                    isBackingUp = false

                    break
                end
            end
        elseif AiUtility.client:isTerrorist() then
            if not AiUtility.plantedBomb or AiUtility.isBombBeingDefusedByEnemy then
                isBackingUp = false
            end
        end

        if isBackingUp then
            self.activity = "Backing up from enemies"
            self.lookAtOccludedOrigin = Trace.getLineAlongCrosshair(AiUtility.traceOptionsAttacking).endPosition

            self.seekCoverTimer:restart()

            local cover = self:getCoverNode(500, self.bestTarget)

            if cover then
                self.ai.nodegraph:pathfind(cover.origin, {
                    objective = Node.types.ENEMY,
                    task = string.format("Back-up (threat) from %s", self.bestTarget:getName()),
                    canUseJump = false
                })
            else
                self:actionBackUp()
            end
        end

        -- Avoid smokes.
        local isAvoidingSmokes = true

        if AiUtility.timeData.roundtime_remaining < 40 then
            isAvoidingSmokes = false
        elseif AiUtility.plantedBomb and AiUtility.bombDetonationTime < 25 then
            isAvoidingSmokes = false
        elseif AiUtility.isBombBeingDefusedByEnemy or AiUtility.isBombBeingPlantedByTeammate then
            isAvoidingSmokes = false
        end

        if isAvoidingSmokes then
            local clientOrigin = AiUtility.client:getOrigin()
            --- @type Entity
            local nearSmoke

            for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
                if clientOrigin:getDistance(smoke:m_vecOrigin()) < 300 then
                    nearSmoke = smoke

                    break
                end
            end

            if nearSmoke then
                self.activity = "Backing up from smoke"
                self.lookAtOccludedOrigin = Trace.getLineAlongCrosshair(AiUtility.traceOptionsAttacking).endPosition

                self.seekCoverTimer:restart()

                local cover = self:getCoverNode(500, self.bestTarget)

                if cover then
                    self.ai.nodegraph:pathfind(cover.origin, {
                        objective = Node.types.ENEMY,
                        task = string.format("Back-up (smoke) from %s", self.bestTarget:getName()),
                        canUseJump = false
                    })
                else
                    self:actionBackUp()
                end
            else
                nearSmoke = nil
            end
        end
    else
        return
    end

    local targetOrigin = self.bestTarget:getOrigin()

    if self.lastBestTargetOrigin and self.bestTarget:getFlag(Player.flags.FL_ONGROUND) and targetOrigin:getDistance(self.lastBestTargetOrigin) > 200 then
       self.ai.nodegraph:clearPath("Enemy moved")
    end

    -- Don't peek the angle. Hold it.
    if self:canHoldAngle() then
        self.activity = "Holding enemy"

        if self.ai.nodegraph.path then
            self.isHoldingAngle = Client.getChance(1)
            self.isHoldingAngleDucked = AiUtility.client:hasSniper() or Client.getChance(4)

            if self.isHoldingAngle then
               self.ai.nodegraph:clearPath("Enemy is around corner")
            end
        end

        self.patienceTimer:ifPausedThenStart()

        -- Jiggling whilst scoped might look stupid.
        if AiUtility.client:isHoldingSniper() then
            Client.scope()
        end

        if self.isHoldingAngleDucked then
            cmd.in_duck = 1
        else
            self:actionJiggle(self.jiggleTime)
        end

        return
    end

    self.activity = "Moving on enemy"

    if self.ai.nodegraph:isIdle() then
        local targetEyeOrigin = self.bestTarget:getEyeOrigin()

        --- @type Node[]
        local selectedNodes = {}
        --- @type Node
        local closestNode
        local closestNodeDistance = math.huge
        local i = 0

        -- Find a nearby node that is visible to the enemy.
        for _, node in pairs(self.ai.nodegraph.nodes) do
            local distance = targetOrigin:getDistance(node.origin)

            -- Determine closest node. This is our backup in case there's no visible nodes.
            if distance < closestNodeDistance then
                closestNodeDistance = distance
                closestNode = node
            end

            -- Find a visible node nearby.
            if distance < 1000 and Client.getChance(0.66) then
                i = i + 1

                if i > 50 then
                    break
                end

                local trace = Trace.getLineToPosition(targetEyeOrigin, node.origin, AiUtility.traceOptionsPathfinding, "AiStateEngage.moveOnBestTarget<FindNodeVisibleToEnemy>")

                if not trace.isIntersectingGeometry then
                    table.insert(selectedNodes, node)
                end
            end
        end

        -- We can pathfind to a node visible to the enemy.
        if not Table.isEmpty(selectedNodes) then
           self.ai.nodegraph:pathfind(Table.getRandom(selectedNodes).origin, {
                objective = Node.types.ENEMY,
                task = string.format("Engage (vis) %s", self.bestTarget:getName()),
                canUseJump = false
            })

            self.lastBestTargetOrigin = targetOrigin

            return
        end

        -- Move to the closest node to the enemy.
        -- The alternative to this is soft-crashing the AI.
        if closestNode then
           self.ai.nodegraph:pathfind(closestNode.origin, {
                objective = Node.types.ENEMY,
                task = string.format("Engage (pxy) %s", self.bestTarget:getName()),
                canUseJump = false
            })

            self.lastBestTargetOrigin = targetOrigin
        end
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:attackBestTarget(cmd)
    if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableAimbot:get() then
        return
    end

    -- Prevent certain generic behaviours.
    self.ai.canUseGear = false
    self.ai.canInspectWeapon = false
    self.ai.nodegraph.isAllowedToAvoidTeammates = false

    -- Prevent reloading/unscoping when enemies are visible.
    if next(AiUtility.visibleEnemies) then
        self.ai.canReload = false
        self.ai.canUnscope = false
    end

    -- Look at occluded origin.
    if self.lookAtOccludedOrigin and not AiUtility.clientThreatenedFromOrigin then
        self.ai.view:lookAtLocation(self.lookAtOccludedOrigin, 4, self.ai.view.noiseType.MINOR, "Engage look-at occlusion")
    end

    local player = AiUtility.client

    -- Spray.
    if self.sprayTimer:isStarted() and not self.sprayTimer:isElapsed(self.sprayTime) then
        self.ai.canReload = false

        if self.bestTarget and not AiUtility.visibleEnemies[self.bestTarget.eid] then
            self:shoot(cmd, self.watchOrigin, self.bestTarget)
        elseif not self.bestTarget then
            self:shoot(cmd, self.watchOrigin)
        end
    end

    -- Reset reaction delay.
    if not self.bestTarget or not self:hasNoticedEnemy(self.bestTarget) then
        self.reactionTimer:stop()
    end

    -- Ignore unnoticed enemies.
    -- I'm like 100% sure that this is completely redundant. How does this attack function even get run
    -- if there's no enemies the AI knows about to attack?
    -- I'm not removing it because every time I change something in this 2000 line file the AI starts doing insane things.
    if not self:hasNoticedEnemies() then
        return
    end

    -- Block overpowered spray transfers.
    if not self.blockTimer:isElapsed(self.blockTime) then
        self.ai.canReload = false

        return
    end

    -- Weapon info.
    local weapon = Entity:create(player:m_hActiveWeapon())
    local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
    local ammo = weapon:m_iClip1()
    local maxAmmo = csgoWeapon.primary_clip_size
    local ammoRatio = ammo / maxAmmo

    -- Swap guns when out of ammo.
    if self.lastPriority == AiPriority.ENGAGE_ACTIVE then
        local ammoLeftRatio = ammo / maxAmmo

        if ammoLeftRatio == 0 then
            if AiUtility.client:isHoldingPrimary() then
                self.equipPistolTimer:start()

                Client.equipPistol()
            end
        end
    elseif self.lastPriority == AiPriority.ENGAGE_PASSIVE then
        -- Ensure bot is holding a weapon.
        if AiUtility.client:hasPrimary() then
            Client.equipPrimary()
        else
            Client.equipPistol()
        end
    end

    -- Don't evade when swapping to pistol, because our code is awful.
    if self.equipPistolTimer:isStarted() and not self.equipPistolTimer:isElapsed(3) then
        self.ai.states.evade.isBlocked = true
    end

    -- Target we intend to engage.
    local enemy = self.bestTarget

    -- Prevent reloading.
    if self.watchTimer:isStarted() and not self.watchTimer:isElapsed(self.watchTime) then
        self.ai.canReload = false
    end

    -- Watch last known position.
    if not enemy then
        self:watchAngle()

        return
    end

    local eyeOrigin = Client.getEyeOrigin()
    local enemyOrigin = enemy:getOrigin()
    local lastSeenEnemyTimer = self.lastSeenTimers[enemy.eid]
    local currentReactionTime = self.reactionTime

    if lastSeenEnemyTimer:isNotElapsed(2) then
        currentReactionTime = self.anticipateTime
    end

    self.currentReactionTime = currentReactionTime

    local shootFov = self:getShootFov(Client.getCameraAngles(), eyeOrigin, enemyOrigin)

    -- Begin reaction timer.
    if self:hasNoticedEnemy(enemy) then
        self.reactionTimer:ifPausedThenStart()
    end

    if AiUtility.visibleEnemies[enemy.eid] then
        self.visibleReactionTimer:ifPausedThenStart()
    else
        self.visibleReactionTimer:stop()
    end

    local offsetModifier = Math.getClampedFloat(eyeOrigin:getDistance(enemyOrigin), 1000, 0, 700)
    local horizontal = self.aimInaccurateOffset
    local vertical = self.aimInaccurateOffset / 3

    self.shootAtOrigin = enemy:getOrigin():offset(0, 0, 48) + Vector3:new(
        Animate.sine(0, horizontal * offsetModifier, 3),
        Animate.sine(0, horizontal * offsetModifier, 2),
        Animate.sine(0, vertical * offsetModifier, 2.5)
    )

    -- Ensure player is holding weapon.
    if not player:isHoldingGun() then
        if AiUtility.client:hasPrimary() then
            Client.equipPrimary()
        else
            Client.equipPistol()
        end
    end

    -- Shoot last position.
    if not next(AiUtility.visibleEnemies) then
        self:watchAngle()
    end

    -- Wide-peek enemies.
    self:strafePeek()

    -- Wallbang and smokebang.
    if not AiUtility.visibleEnemies[enemy.eid] then
        local lastNoticedAgo = self.noticedPlayerTimers[enemy.eid]:get()

        if AiUtility.isBombBeingDefusedByEnemy or (lastNoticedAgo >= 0 and lastNoticedAgo < 1) then
            local bangOrigin = enemy:getOrigin():offset(0, 0, 46)
            local traceEid, traceDamage = eyeOrigin:getTraceBullet(bangOrigin, Client.getEid())
            local isBangable = true

            if player:hasSniper() then
                if ammoRatio < 1 then
                    -- Banging with AWP is often not a great idea.
                    -- So we're only going to allow it if the AI has a full mag.
                    isBangable = false
                elseif traceDamage < 65 then
                    -- We should only wallbang on high damage bangs.
                    isBangable = false
                end
            else
                if ammo < 0.25 then
                    -- Low ammo.
                    isBangable = false
                elseif ammoRatio < 0.5 and traceDamage < 33 then
                    -- Mid-ammo so spare our shots more.
                    isBangable = false
                elseif traceDamage < 10 then
                    -- At least try to damage the enemy.
                    isBangable = false
                end
            end

            local isShooting = false
            local isOccludedBySmoke = eyeOrigin:isRayIntersectingSmoke(bangOrigin)
            local trace = Trace.getLineToPosition(eyeOrigin, bangOrigin, AiUtility.traceOptionsAttacking)
            local isOccludedByWall = trace.isIntersectingGeometry
            local isEnemyTargetable = traceEid == enemy.eid

            if isOccludedByWall then
                -- Wallbang, but only if there isn't a smoke in the way.
                if self.canWallbang and not isOccludedBySmoke and isBangable and isEnemyTargetable then
                    isShooting = true
                end
            elseif isOccludedBySmoke and isBangable then
                -- Smokebang.
                isShooting = true
            elseif self.smokeWallBangHoldTimer:isStarted() and not self.smokeWallBangHoldTimer:isElapsed(1) then
                -- Hold our spray. Prevents dithering.
                isShooting = true
            end

            if isShooting then
                self.smokeWallBangHoldTimer:ifPausedThenStart()

                self:addVisualizer("bang", function()
                    self.shootAtOrigin:drawCircleOutline(12, 2, Color:hsla(30, 1, 0.5, 200))
                end)

                self:shoot(cmd, self.shootAtOrigin)

                -- Do we need to return?
                return
            end
        end
    end

    -- Shoot while blind.
    if Client.isFlashed() and AiUtility.visibleEnemies[enemy.eid] then
        self:shoot(cmd, self.shootAtOrigin, enemy)

        return
    end

    -- Get target hitbox.
    local hitbox, visibleHitboxCount = self:getHitbox(enemy)

    -- Pre-aim angle.
    -- Pre-aim hitbox when peeking.
    if self:hasNoticedEnemy(enemy) and self.reactionTimer:isElapsed(self.reactionTime) then
        self:preAimAboutCorners()
        self:preAimThroughCorners()
    end

    if not hitbox then
        return
    end

    self.isTargetEasilyShot = visibleHitboxCount >= 8

    -- Begin watching last angle.
    if AiUtility.visibleEnemies[enemy.eid] then
        if hitbox then
            self.watchOrigin = enemyOrigin:offset(0, 0, 60)
        end

        self.enemyVisibleTimer:ifPausedThenStart()
    else
        self.enemyVisibleTimer:stop()
    end

    -- Make sure the default mouse movement isn't active while the enemy is visible but the reaction timer hasn't elapsed.
    if AiUtility.visibleEnemies[enemy.eid] and shootFov < 40 then
       self.ai.view:lookAtLocation(hitbox, 2.5, self.ai.view.noiseType.IDLE, "Engage prepare to react")

        self:addVisualizer("hold", function()
            hitbox:drawCircleOutline(12, 2, Color:hsla(50, 1, 0.5, 200))
        end)
    end

    -- React to visible enemy.
    if self.visibleReactionTimer:isElapsed(self.currentReactionTime) and AiUtility.visibleEnemies[enemy.eid] then
        if shootFov < 12 then
            self.sprayTimer:start()
            self.watchTimer:start()
            self.lastSeenTimers[enemy.eid]:start()

            self:noticeEnemy(enemy, 4096, false, "In shoot FoV")
            self:shoot(cmd, hitbox, enemy)
        elseif shootFov < 40 then
           self.ai.view:lookAtLocation(hitbox, self.aimSpeed * 0.8, self.ai.view.noiseType.MINOR, "Engage find enemy under 40 FoV")

            self.watchTimer:start()
            self.lastSeenTimers[enemy.eid]:start()
        elseif shootFov >= 40 and self:hasNoticedEnemy(enemy) then
           self.ai.view:lookAtLocation(hitbox, self.slowAimSpeed, self.ai.view.noiseType.MINOR, "Engage find enemy over 40 FoV")
        end
    end
end

--- @return void
function AiStateEngage:setIsVisibleToBestTarget()
    if not self.bestTarget then
        return
    end

    self.isVisibleToBestTarget = false

    local enemyEyeOrigin = self.bestTarget:getEyeOrigin()

    for _, hitbox in pairs(AiUtility.client:getHitboxPositions({
        Player.hitbox.HEAD,
        Player.hitbox.PELVIS,
        Player.hitbox.LEFT_LOWER_LEG,
        Player.hitbox.RIGHT_LOWER_ARM,
        Player.hitbox.LEFT_LOWER_ARM,
        Player.hitbox.RIGHT_LOWER_LEG,
    })) do
        local trace = Trace.getLineToPosition(enemyEyeOrigin, hitbox, AiUtility.traceOptionsAttacking, "AiState.getCoverNode<FindClientVisibleToEnemy>")

        if not trace.isIntersectingGeometry then
            self.isVisibleToBestTarget = true

            break
        end
    end
end

--- @return boolean
function AiStateEngage:canHoldAngle()
    -- Activates if the enemy is near a corner, but not too close to it.
    if not self.isPreAimViableForHoldingAngle then
        return false
    end

    -- The enemy can see us. It's possible we'd hold an angle where our pelvis or feet are visible, but we cannot see the enemy.
    if self.isVisibleToBestTarget then
        return false
    end

    local isBestTargetVisible = AiUtility.visibleEnemies[self.bestTarget.eid]

    -- The enemy is visible.
    if isBestTargetVisible then
        return false
    end

    -- Check we're not going to hold an angle in a really dumb spot.
    local clientEyeOrigin = Client.getEyeOrigin()
    local traceOptions = Table.getMerged(AiUtility.traceOptionsAttacking, {
        distance = 200
    })

    local losTrace = Trace.getLineAtAngle(clientEyeOrigin, Client.getCameraAngles(), traceOptions)

    -- Line of sight is facing too close to a wall.
    if losTrace.isIntersectingGeometry then
        return false
    end

    if self.bestTarget then
        local trace = Trace.getLineToPosition(clientEyeOrigin, self.bestTarget:getEyeOrigin(), AiUtility.traceOptionsAttacking)

        -- The enemy, from our point of view, is occluded by a smoke.
        -- We shouldn't really push smokes, so we should prefer holding the smoke instead.
        if clientEyeOrigin:isRayIntersectingSmoke(trace.endPosition) then
            return true
        end
    end

    local clientOrigin = AiUtility.client:getOrigin()
    local bounds = Vector3:newBounds(Vector3.align.BOTTOM, 32)
    local hullTrace = Trace.getHullAtPosition(clientOrigin:clone():offset(0, 0, 16), bounds, AiUtility.traceOptionsAttacking)

    -- Our proximity to a wall is too close.
    if hullTrace.isIntersectingGeometry then
        return false
    end

    -- Don't hold if the enemy is planting or has planted the bomb.
    if AiUtility.client:isCounterTerrorist() and not AiUtility.plantedBomb and not AiUtility.isBombBeingPlantedByEnemy then
        -- If we're the closest to enemy, maybe don't permanently hold the angle.
        if self.bestTarget then
            local isClosestToEnemy = true
            local targetOrigin = self.bestTarget:getOrigin()
            local clientDistance = clientOrigin:getDistance(targetOrigin)

            for _, teammate in pairs(AiUtility.teammates) do
                if teammate:getOrigin():getDistance(targetOrigin) < clientDistance then
                    isClosestToEnemy = false

                    break
                end
            end
        end

        return true
    end

    -- We have to have a cooldown, or you can immediately trigger the AI back into holding the angle.
    -- We don't do this for CTs. They can play time most of the time.
    if self.patienceCooldownTimer:isStarted() and not self.patienceCooldownTimer:isElapsed(8) then
        return false
    end

    -- Don't hold if the enemy is defusing the bomb.
    if AiUtility.client:isTerrorist() and not AiUtility.isBombBeingDefusedByEnemy then
        if not AiUtility.plantedBomb then
            -- We don't have much time remaining in the round, so we ought not to stand around.
            if AiUtility.timeData.roundtime_remaining < 30 then
                return false
            end

            -- Don't hold the angle forever.
            if self.patienceTimer:isElapsed(6) then
                self.patienceCooldownTimer:restart()

                return false
            end
        end

        local distanceToSite =self.ai.nodegraph:getNearestSiteNode(clientOrigin).origin:getDistance(clientOrigin)
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

--- @return void
function AiStateEngage:walk()
    local player = AiUtility.client
    local canWalk

    if self.bestTarget and AiUtility.closestEnemy then
        local clientEyeOrigin = Client.getEyeOrigin()
        local predictedEyeOrigin = clientEyeOrigin + player:m_vecVelocity() * 0.8
        local enemyOrigin = AiUtility.closestEnemy:getOrigin()
        local distance = clientEyeOrigin:getDistance(enemyOrigin)
        local trace = Trace.getLineToPosition(predictedEyeOrigin, self.bestTarget:getOrigin():offset(0, 0, 48), AiUtility.traceOptionsAttacking)
        local shootFov = self:getShootFov(self.bestTarget:getCameraAngles(), self.bestTarget:getEyeOrigin(), clientEyeOrigin)

        if distance < 1200 then
            canWalk = true
        end

        if player:isCounterTerrorist() and AiUtility.plantedBomb then
            if AiUtility.bombDetonationTime < 20 then
                canWalk = false
            elseif distance > 350 then
                canWalk = false
            end
        end

        if not trace.isIntersectingGeometry and shootFov < 20 then
            canWalk = false
        end
    end

    if self.walkCheckTimer:isElapsedThenRestart(0.15) then
        self.walkCheckCount = Math.getClamped(self.walkCheckCount - 1, 0, 20)
    end

    if self.walkCheckCount >= 8 then
        canWalk = false
    end

    if AiUtility.isBombBeingDefusedByEnemy then
        canWalk = false
    elseif AiUtility.isBombBeingPlantedByEnemy then
        canWalk = false
    end

    if AiUtility.client:m_bIsScoped() == 1 then
        canWalk = false
    end

    self.isSneaking = canWalk

    if canWalk then
        self.ai.isWalking = true
    end
end

--- @param angle Angle
--- @param vectorA Vector3
--- @param vectorB Vector3
--- @return number
function AiStateEngage:getShootFov(angle, vectorA, vectorB)
    local distance = vectorA:getDistance(vectorB)
    local fov = angle:getFov(vectorA, vectorB)

    return Math.getClamped(Math.getFloat(distance, 512), 0, 90) * fov
end

--- @param cmd SetupCommandEvent
--- @param aimAtBaseOrigin Vector3
--- @param enemy Player
--- @return void
function AiStateEngage:shoot(cmd, aimAtBaseOrigin, enemy)
    self.activity = "Shooting enemy"

    -- Nothing to shoot at.
    if not aimAtBaseOrigin then
        return
    end

    -- Don't shoot when in-air.
    if not AiUtility.client:getFlag(Player.flags.FL_ONGROUND) then
        return
    end

    -- Prevent jumping obstacles. This can kill us.
   self.ai.nodegraph.canJump = false
    self.ai.canLookAwayFromFlash = false

    local distance = AiUtility.client:getOrigin():getDistance(aimAtBaseOrigin)

    -- Update the offset to the shoot origin.
    if distance < 200 then
        self.hitboxOffset = Vector3:new(
            Animate.sine(0, self.aimOffset * 0.2, 3.1),
            Animate.sine(0, self.aimOffset * 0.2, 2.3),
            Animate.sine(0, self.aimOffset * 0.2 / 3, 4)
        )
    else
        self.hitboxOffset = Vector3:new(
            Animate.sine(0, self.aimOffset, 3.1),
            Animate.sine(0, self.aimOffset, 2.3),
            Animate.sine(0, self.aimOffset / 3, 4)
        )
    end

    local resonated

    if enemy then
        resonated = Math.getResonated({
            Math.getClampedInversedFloat(distance, 700, 0, 750),
            Math.getClampedInversedFloat(enemy:m_vecVelocity():getMagnitude(), 145, 100, 450)
        })
    else
        resonated = 1
    end

    self.hitboxOffset = Vector3:new(
        Animate.sine(0, self.aimOffset * resonated, 3.1),
        Animate.sine(0, self.aimOffset * resonated, 2.3),
        Animate.sine(0, (self.aimOffset * resonated) / 2, 4)
    )

    -- Real origin to shoot at.
    local aimAtOrigin = aimAtBaseOrigin + self.hitboxOffset

    -- Draw debugging visualisers.
    self:addVisualizer("shoot",function()
        aimAtBaseOrigin:drawCircle(3, Color:hsla(0, 1, 0.5, 150))
        aimAtOrigin:drawCircleOutline(10, 3, Color:hsla(0, 1, 0.5, 100))
        aimAtOrigin:drawCircle(2, Color:hsla(0, 1, 0.5, 150))
        aimAtBaseOrigin:drawLine(aimAtOrigin, Color:hsla(0, 1, 0.5, 75))
    end)

    local clientEyeOrigin = Client.getEyeOrigin()

    -- We have an actual target to shoot, and not just some point in space.
    if enemy then
        -- Enemy is dormant. They aren't, and cannot be, visible.
        if enemy:isDormant() then
            return
        end

        local trace = Trace.getLineToPosition(clientEyeOrigin, aimAtBaseOrigin, AiUtility.traceOptionsAttacking)

        -- Enemy is behind a wall. We have other code responsible for wallbanging.
        if trace.isIntersectingGeometry then
            return
        end
    end

    -- Avoid shooting at teammates if possible.
    -- This will not be perfect, but it'll help most of the time.
    local distanceToHitbox = clientEyeOrigin:getDistance(aimAtOrigin)
    local correctedAngles = Client.getCameraAngles() + AiUtility.client:m_aimPunchAngle() * 2
    local box = (clientEyeOrigin + correctedAngles:getForward() * distanceToHitbox):getBox(Vector3.align.CENTER, 16)

    for _, vertex in pairs(box) do
        local trace = Trace.getLineToPosition(clientEyeOrigin, vertex, {
            skip = function(eid)
                -- Ignore client.
                if eid == entity.get_local_player() then
                    return true
                end

                -- Ignore non-player entities.
                if eid < 0 or eid > 64 then
                    return true
                end

                -- Collide with teammates.
                if not entity.is_enemy(eid) then
                    return false
                end

                -- Ignore enemies.
                return true
            end,
            mask = Trace.mask.SHOT,
            type = Trace.type.ENTITIES_ONLY
        }, "AiStateEngage.shoot<FindIfTeammatesInFiringCone>")

        -- We're probably going to hit a teammate.
        if trace.isIntersectingGeometry then
            return
        end
    end

    local fov = self:getShootFov(Client.getCameraAngles(), Client.getEyeOrigin(), aimAtOrigin)

    -- Set RCS parameters.
    -- RCS should be off for snipers and shotguns, and on for rifles, SMGs, and pistols.
   self.ai.view.isRcsEnabled = self.isRcsEnabled

    -- Set mouse movement parameters.
   self.ai.view.isCrosshairSmoothed = false
   self.ai.view.isCrosshairUsingVelocity = true

    -- Select which method to use to perform shooting logic.
    local shootModes = {
        [WeaponMode.PISTOL] = AiStateEngage.shootPistol,
        [WeaponMode.LIGHT] = AiStateEngage.shootLight,
        [WeaponMode.SHOTGUN] = AiStateEngage.shootShotgun,
        [WeaponMode.HEAVY] = AiStateEngage.shootHeavy,
        [WeaponMode.SNIPER] = AiStateEngage.shootSniper
    }

    local method = shootModes[self.weaponMode]

    -- Heavy automatic as default weapon type.
    if not method then
        method = AiStateEngage.shootHeavy
    end

    local weapon = Entity:create(AiUtility.client:m_hActiveWeapon())
    local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]

    method(self, cmd, aimAtOrigin, fov, csgoWeapon)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:fireWeapon(cmd)
    if not self.isAimEnabled then
        return
    end

    cmd.in_attack = 1
end

--- @param cmd SetupCommandEvent
--- @param aimAtOrigin Vector3
--- @param fov number
--- @param weapon CsgoWeapon
--- @return void
function AiStateEngage:shootPistol(cmd, aimAtOrigin, fov, weapon)
    local distance = Client.getEyeOrigin():getDistance(aimAtOrigin)
    local isVelocityOk = true

    if distance > 600 then
        cmd.in_duck = 1
    elseif not self.canRunAndShoot then
        self:actionJiggle(self.jiggleTime * 0.33)

        isVelocityOk = AiUtility.client:m_vecVelocity():getMagnitude() < 100
    elseif AiUtility.totalThreats > 1 then
        self:actionBackUp()
    end

    local aimSpeed = self.aimSpeed

    if distance < 600 then
        aimSpeed = self.aimSpeed * 1.5
    end

   self.ai.view:lookAtLocation(aimAtOrigin, aimSpeed, self.aimNoise, "Engage look-at target")

    if fov < 7
        and self.tapFireTimer:isElapsedThenRestart(self.tapFireTime)
        and isVelocityOk
    then
        self:fireWeapon(cmd)
    end
end

--- @param cmd SetupCommandEvent
--- @param aimAtOrigin Vector3
--- @param fov number
--- @param weapon CsgoWeapon
--- @return void
function AiStateEngage:shootLight(cmd, aimAtOrigin, fov, weapon)
    local distance = Client.getEyeOrigin():getDistance(aimAtOrigin)
    local aimSpeed = self.aimSpeed

    if distance < 500 then
        aimSpeed = self.aimSpeed * 1.5
    end

   self.ai.view:lookAtLocation(aimAtOrigin, aimSpeed, self.aimNoise, "Engage look-at target")

    if not self.canRunAndShoot then
        self:actionCounterStrafe(cmd)
    elseif AiUtility.totalThreats > 1 then
        self:actionBackUp()
    end

    if fov < 9
        and self.tapFireTimer:isElapsedThenRestart(self.tapFireTime)
    then
        self:fireWeapon(cmd)
    end
end

--- @param cmd SetupCommandEvent
--- @param aimAtOrigin Vector3
--- @param fov number
--- @param weapon CsgoWeapon
--- @return void
function AiStateEngage:shootShotgun(cmd, aimAtOrigin, fov, weapon)
    local distance = Client.getEyeOrigin():getDistance(aimAtOrigin)
    local aimSpeed = self.aimSpeed

    if distance < 500 then
        aimSpeed = self.aimSpeed * 1.5
    end

   self.ai.view:lookAtLocation(aimAtOrigin, aimSpeed, self.aimNoise, "Engage look-at target")

    if distance > 1000 then
        return
    end

    if AiUtility.totalThreats > 1 then
        self:actionBackUp()
    end

    if fov < 10
        and self.tapFireTimer:isElapsedThenRestart(self.tapFireTime)
    then
        self:fireWeapon(cmd)
    end
end

--- @param cmd SetupCommandEvent
--- @param aimAtOrigin Vector3
--- @param fov number
--- @param weapon CsgoWeapon
--- @return void
function AiStateEngage:shootHeavy(cmd, aimAtOrigin, fov, weapon)
   self.ai.view:lookAtLocation(aimAtOrigin, self.aimSpeed, self.aimNoise, "Engage look-at target")

    if self.isTargetEasilyShot then
        self:actionCounterStrafe(cmd)
    else
        self:actionStop(cmd)
    end

    local isVelocityOk = AiUtility.client:m_vecVelocity():getMagnitude() < 100

    if fov < 8
        and self.tapFireTimer:isElapsedThenRestart(self.tapFireTime)
        and isVelocityOk
    then
        self:fireWeapon(cmd)
    end
end

--- @param cmd SetupCommandEvent
--- @param aimAtOrigin Vector3
--- @param fov number
--- @param weapon CsgoWeapon
--- @return void
function AiStateEngage:shootSniper(cmd, aimAtOrigin, fov, weapon)
    local distance = Client.getEyeOrigin():getDistance(aimAtOrigin)
    local fireDelay = 0.66

    -- Set the delay of our shooting to be roughly accurate as we scope.
    if distance > 1500 then
        fireDelay = 0.4
    elseif distance > 1000 then
        fireDelay = 0.3
    elseif distance > 500 then
        fireDelay = 0.25
    else
        fireDelay = 0.15
    end

    -- Create a "flick" effect when aiming.
    if self.scopedTimer:isElapsed(fireDelay * 0.4) then
       self.ai.view:lookAtLocation(aimAtOrigin, self.aimSpeed * 3, self.aimNoise, "Engage look-at target")
    end

    if fov < 12 then
        Client.scope()
    end

    -- Always come to a complete stop when using snipers.
    self:actionStop(cmd)

    -- We can shoot when we're this slow.
    local fireUnderVelocity = weapon.max_player_speed / 5

    if fov < 4
        and self.scopedTimer:isElapsedThenStop(fireDelay)
        and AiUtility.client:m_bIsScoped() == 1
        and AiUtility.client:m_vecVelocity():getMagnitude() < fireUnderVelocity
    then
        self:fireWeapon(cmd)
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
        local trace = Trace.getLineToPosition(eyeOrigin, hitbox, AiUtility.traceOptionsAttacking, "AiStateEngage.getHitbox<FindTargetableHitbox>")

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

    self.isBestTargetVisible = visibleHitboxCount > 0

    return targetHitbox, visibleHitboxCount
end

--- @return void
function AiStateEngage:actionBackUp()
    if not self.bestTarget then
        return
    end

    -- Move backwards because we don't feel like deliberately peeking the entire enemy team at once.
    local angleToEnemy = Client.getOrigin():getAngle(self.bestTarget:getOrigin())

   self.ai.nodegraph.moveAngle = -angleToEnemy
end

--- @param period number
--- @return void
function AiStateEngage:actionJiggle(period)
    -- Alternate movement directions.
    if self.jiggleTimer:isElapsedThenRestart(period) then
        self.jiggleDirection = self.jiggleDirection == "Left" and "Right" or "Left"
    end

    --- @type Vector3
    local direction

    if self.jiggleDirection == "Left" then
        direction = Client.getCameraAngles():getLeft()
    else
        direction = Client.getCameraAngles():getRight()
    end

   self.ai.nodegraph.moveAngle = direction:getAngleFromForward()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:actionCounterStrafe(cmd)
    if self.isTargetEasilyShot then
        -- Duck for better accuracy.
        cmd.in_duck = 1

        -- Move backwards because we don't feel like deliberately peeking the entire enemy team at once.
        if AiUtility.totalThreats > 1 then
            self:actionBackUp()
        end
    else
        local velocity = AiUtility.client:m_vecVelocity()

        -- Stop moving when our velocity has fallen below threshold.
        if velocity:getMagnitude() < 70 then
            return
        end

        local inverseVelocity = -velocity

        -- Counter our current velocity.
       self.ai.nodegraph.moveAngle = inverseVelocity:getAngleFromForward()
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:actionStop(cmd)
    if self.isTargetEasilyShot then
        -- Duck for better accuracy.
        cmd.in_duck = 1
    end

    local velocity = AiUtility.client:m_vecVelocity()

    -- Stop moving when our velocity has fallen below threshold.
    if velocity:getMagnitude() < 70 then
       self.ai.nodegraph.isAllowedToMove = false

        return
    end

    local inverseVelocity = -velocity

    -- Counter our current velocity.
   self.ai.nodegraph.moveAngle = inverseVelocity:getAngleFromForward()
end

--- @return void
function AiStateEngage:strafePeek()
    self.canWallbang = true
    self.isStrafePeeking = false

    if not self.strafePeekTimer:isElapsed(0.6) then
        self.ai.nodegraph.moveAngle = self.strafePeekMoveAngle

        self.isStrafePeeking = true
        self.canWallbang = false

        return
    end

    local enemy = self.bestTarget

    if not enemy then
        return
    end

    local player = AiUtility.client
    local playerOrigin = player:getOrigin()
    local enemyOrigin = enemy:getOrigin()
    local angleToEnemy = playerOrigin:getAngle(enemyOrigin)

    --- @type Vector3[]
    local directions = {
        Left = angleToEnemy:getLeft(),
        Right = angleToEnemy:getRight()
    }

    local isVisible = false
    --- @type Angle
    local moveAngle
    local eyeOrigin = Client.getEyeOrigin()
    local bounds = Vector3:newBounds(Vector3.align.DOWN, 16, 16, 32)
    local distances = {
        10, 20, 30, 40, 50, 60
    }
    local distance = distances[self.strafePeekIndex]

    if not distance then
        self.strafePeekIndex = 1
        distance = distances[1]
    end

    self.strafePeekIndex = self.strafePeekIndex + 1

    local traceOptions = Table.getMerged({
        distance = distance
    }, AiUtility.traceOptionsAttacking)

    for _, direction in pairs(directions) do
        if isVisible then
            break
        end

        local findOffsetTrace = Trace.getHullInDirection(eyeOrigin, eyeOrigin + direction * 32, bounds, traceOptions)
        local offsetTraceOrigin = findOffsetTrace.endPosition

        for _, hitbox in pairs(enemy:getHitboxPositions({
            Player.hitbox.HEAD,
            Player.hitbox.PELVIS,
            Player.hitbox.LEFT_LOWER_LEG,
            Player.hitbox.RIGHT_LOWER_ARM,
            Player.hitbox.LEFT_LOWER_ARM,
            Player.hitbox.RIGHT_LOWER_LEG,
        })) do
            local findVisibleHitboxTrace = Trace.getLineToPosition(hitbox, offsetTraceOrigin, AiUtility.traceOptionsAttacking)

            if not findVisibleHitboxTrace.isIntersectingGeometry then
                isVisible = true
                moveAngle = direction:getAngleFromForward()

                break
            end
        end
    end

    if moveAngle then
        self.strafePeekMoveAngle = moveAngle
        self.strafePeekTimer:restart()
    end
end

--- @return void
function AiStateEngage:preAimThroughCorners()
    local target = self.bestTarget

    if not target then
        return
    end

    if self.isBestTargetVisible then
        return
    end

    local player = AiUtility.client
    local clientVelocity = player:m_vecVelocity()

    if clientVelocity:getMagnitude() < 50 then
        return
    end

    if not self.preAimThroughCornersBlockTimer:isElapsed(0.8) then
        return
    end

    local playerEid = Client.getEid()
    local playerOrigin = player:getOrigin()
    local hitboxes = target:getHitboxPositions({
        Player.hitbox.HEAD,
        Player.hitbox.LEFT_LOWER_LEG,
        Player.hitbox.RIGHT_LOWER_LEG,
        Player.hitbox.LEFT_LOWER_ARM,
        Player.hitbox.RIGHT_LOWER_ARM,
    })

    -- Determine if we're about to peek the target.
    local testOrigin = Client.getEyeOrigin() + (clientVelocity * 0.4)
    local isPeeking = false

    for _, hitbox in pairs(hitboxes) do
        local trace = Trace.getLineToPosition(testOrigin, hitbox, AiUtility.traceOptionsAttacking, "AiStateEngage.preAimThroughCorners<FindVisibleEnemyHitbox>")

        if not trace.isIntersectingGeometry then
            isPeeking = true

            break
        end
    end

    if not isPeeking then
        return
    end

    -- Don't pre-aim if the enemy is about to peek us.
    local targetVelocity = target:m_vecVelocity()
    local targetSpeed = targetVelocity:getMagnitude()

    if targetSpeed > 100 then
        targetVelocity = targetVelocity * 0.4

        for _, hitbox in pairs(hitboxes) do
            hitbox = hitbox + targetVelocity

            local _, fraction, eid = playerOrigin:getTraceLine(hitbox, playerEid)

            if eid == target.eid or fraction == 1 then
                self.preAimThroughCornersBlockTimer:start()

                return
            end
        end
    end

    if self.preAimThroughCornersUpdateTimer:isElapsedThenRestart(1.2) then
        local hitboxPosition = target:getHitboxPosition(Player.hitbox.HEAD)
        local distance = playerOrigin:getDistance(hitboxPosition)
        local offsetRange = Math.getFloat(Math.getClamped(distance, 0, 1024), 1024) * 100

        self.preAimThroughCornersOrigin = hitboxPosition:offset(
            Client.getRandomFloat(-offsetRange, offsetRange),
            Client.getRandomFloat(-offsetRange, offsetRange),
            Client.getRandomFloat(-8, 2)
        )
    end

    self.preAimTarget = self.bestTarget

   self.ai.view:lookAtLocation(self.preAimThroughCornersOrigin, 6, self.ai.view.noiseType.NONE, "Engage look through corner")

    self:addVisualizer("pre through", function()
        self.preAimThroughCornersOrigin:drawCircleOutline(16, 2, Color:hsla(100, 1, 0.5, 150))
    end)
end

--- @return void
function AiStateEngage:preAimAboutCorners()
    if not self.bestTarget or not self.bestTarget:isAlive() then
        return
    end

    self.preAimAboutCornersCenterOrigin = self.bestTarget:getOrigin():offset(0, 0, 60)

    if not self.preAimAboutCornersCenterOrigin then
        return
    end

    if self.isBestTargetVisible then
        return
    end

    if self.preAimAboutCornersAimOrigin then
        self.ai.canUnscope = false

       self.ai.view:lookAtLocation(self.preAimAboutCornersAimOrigin, self.slowAimSpeed, self.ai.view.noiseType.NONE, "Engage look at corner")

        self:addVisualizer("pre about", function()
            if self.preAimAboutCornersAimOrigin then
                self.preAimAboutCornersAimOrigin:drawCircleOutline(12, 2, Color:hsla(200, 1, 0.5, 200))
            end
        end)
    end

    if not self.preAimAboutCornersUpdateTimer:isElapsedThenRestart(0.33) then
        return
    end

    local eyeOrigin = Client.getEyeOrigin()
    local bands = {
        {
            distance = 40,
            points = 2
        },
        {
            distance = 80,
            points = 4
        },
        {
            distance = 150,
            points = 6
        },
        {
            distance = 200,
            points = 8
        }
    }

    local bandDirection = eyeOrigin:getAngle(self.preAimAboutCornersCenterOrigin):set(0):offset(nil, 90)
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
            local vertex = self.preAimAboutCornersCenterOrigin + (direction:getForward() * band.distance)
            local findWallCollideTrace = Trace.getLineToPosition(self.preAimAboutCornersCenterOrigin, vertex, AiUtility.traceOptionsAttacking, "AiStateEngage.preAimAboutCorners<FindWallCollidePoint>")

            if not findWallCollideTrace.isIntersectingGeometry then
                local findVisibleToClientTrace = Trace.getLineToPosition(eyeOrigin, vertex, AiUtility.traceOptionsAttacking, "AiStateEngage.preAimAboutCorners<FindPointVisibleToClient>")

                if not findVisibleToClientTrace.isIntersectingGeometry then
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

    self.preAimAboutCornersAimOrigin = closestVertex

    if not closestVertex then
        self.isPreAimViableForHoldingAngle = false

        return
    end

    if closestBand == 2 or closestBand == 3 then
        self.isPreAimViableForHoldingAngle = true
    else
        self.isPreAimViableForHoldingAngle = false
    end
end

--- @return void
function AiStateEngage:watchAngle()
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

   self.ai.view:lookAtLocation(self.watchOrigin, self.aimSpeed, self.ai.view.noiseType.IDLE, "Engage watch last spot")

    self:addVisualizer("watch", function()
        if self.watchOrigin then
            self.watchOrigin:drawCircleOutline(16, 2, Color:hsla(300, 1, 0.5, 200))
        end
    end)
end

--- @param skill number
--- @return void
function AiStateEngage:setAimSkill(skill)
    self.skill = skill

    local skillMinimum = {
        reactionTime = 0.4,
        anticipateTime = 0.1,
        sprayTime = 0.5,
        aimSpeed = 5,
        slowAimSpeed = 3,
        recoilControl = 2.5,
        aimOffset = 48,
        aimInaccurateOffset = 144,
        blockTime = 0.3
    }

    local skillMaximum = {
        reactionTime = 0.01,
        anticipateTime = 0.01,
        sprayTime = 0.33,
        aimSpeed = 8,
        slowAimSpeed = 5,
        recoilControl = 2,
        aimOffset = 0,
        aimInaccurateOffset = 64,
        blockTime = 0.04
    }

    local skillPct = skill / self.skillLevelMax
    local skillCurrent = {}

    for field, value in pairs(skillMinimum) do
        skillCurrent[field] = Animate.lerp(value, skillMaximum[field], skillPct)
    end

    for k, v in pairs(skillCurrent) do
        self[k] = v
    end
end

return Nyx.class("AiStateEngage", AiStateEngage, AiState)
--}}}
