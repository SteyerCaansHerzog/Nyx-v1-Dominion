--{{{ Dependencies
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
--- @field currentReactionTime number
--- @field enemySpottedCooldown Timer
--- @field enemyVisibleTime number
--- @field enemyVisibleTimer Timer
--- @field hitboxOffset Vector3
--- @field hitboxOffsetTimer Timer
--- @field ignoreDormancyTime number
--- @field ignoreDormancyTimer Timer
--- @field ignorePlayerAfter number
--- @field isIgnoringDormancy boolean
--- @field isSneaking boolean
--- @field lastMoveDirection Vector3
--- @field lastSeenTimers Timer[]
--- @field lastSoundTimer Timer
--- @field noticedPlayerTimers Timer[]
--- @field onGroundTime Timer
--- @field onGroundTimer Timer
--- @field preAimAroundCornersTime number
--- @field preAimAroundCornersTimer Timer
--- @field preAimCornerOrigin Vector3
--- @field preAimOrigin Vector3
--- @field preAimOriginTimer Timer
--- @field preAimTarget Player
--- @field priorityHitbox number
--- @field reactionTime number
--- @field reactionTimer Timer
--- @field recoilControl number
--- @field scopedTimer Timer
--- @field shootAtOrigin Vector3
--- @field shootAtOriginTimer Timer
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
--- @field setBestTargetTimer Timer
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
    self.skill = 1
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
    self.shootAtOriginTimer = Timer:new():startThenElapse()
    self.blockTimer = Timer:new():startThenElapse()
    self.blockTime = 0.25
    self.lastSoundTimer = Timer:new():start()
    self.preAimOriginDelayed = Vector3:new()
    self.preAimOriginTimer = Timer:new():startThenElapse()
    self.setBestTargetTimer = Timer:new():startThenElapse()

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
    Menu.aimSkillLevel = Menu.group:slider("    > Aim Skill Level", 0, 4, {
        default = 2,
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

        if Player.getClient():getOrigin():getDistance(e.player:getOrigin()) > 512 then
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

        if Player.getClient():getOrigin():getDistance(e.player:getOrigin()) > 512 then
            return
        end

        self.walkCheckCount = self.walkCheckCount + 1
    end)

    Callbacks.roundStart(function()
        self:reset()

        self.isIgnoringDormancy = true
        self.ignoreDormancyTimer:stop()
    end)

    Callbacks.roundFreezeEnd(function()
        self.ignoreDormancyTimer:start()
    end)

    Callbacks.runCommand(function()
        local player = Player.getClient()
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

        if Player.getClient():getOrigin():getDistance(e.origin) > 128 then
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
        if e.victim:isClient() then
            self:reset()

            return
        end

        if e.attacker:isClient() and e.victim:isEnemy() then
            self.blockTimer:start()
        end

        if e.victim:isTeammate() and Player.getClient():getOrigin():getDistance(e.victim:getOrigin()) < 1250 then
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

    if AiUtility.plantedBomb then
        self.sprayTimer:isElapsedThenStop(0.2)
        self.watchTimer:isElapsedThenStop(0.5)
    else
        self.sprayTimer:isElapsedThenStop(self.sprayTime)
        self.watchTimer:isElapsedThenStop(self.watchTime)
    end

    for _, enemy in pairs(AiUtility.enemies) do
        if enemy:m_bIsDefusing() == 1 then
            return AiState.priority.ENGAGE_NEARBY
        end
    end

    if self.sprayTimer:isStarted() then
        return AiState.priority.ENGAGE_VISIBLE
    end

    if not AiUtility.plantedBomb then
        if self.reactionTimer:isStarted() then
            return AiState.priority.ENGAGE_VISIBLE
        end

        if self.watchTimer:isStarted() then
            return AiState.priority.ENGAGE_VISIBLE
        end
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
        local player = Player.getClient()

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

    local player = Player.getClient()

    if player:isHoldingWeapon(Weapons.C4) then
        Client.equipWeapon()
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

    local player = Player.getClient()

    if not player:isCounterTerrorist() then
        return
    end

    local playerOrigin = player:getOrigin()

    local nearestBombSite = ai.nodegraph:getNearestBombSite(playerOrigin)
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

        local nearestBombSite = ai.nodegraph:getNearestBombSite(tellEnemy:getOrigin())

        if Menu.useChatCommands:get() then
            Messenger.send(string.format("/go %s", nearestBombSite), true)
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
--- @return void
function AiStateEngage:noticeEnemy(player, range)
    if not Player.getClient():isAlive() or not self.ignoreDormancyTimer:isElapsed(self.ignoreDormancyTime) then
        return
    end

    if player:isTeammate() then
        return
    end

    local enemyOrigin = player:getOrigin()

    if enemyOrigin:isZero() then
        return
    end

    if Player.getClient():getOrigin():getDistance(enemyOrigin) > range then
        return
    end

    self.noticedPlayerTimers[player.eid]:start()

    if self.shootAtOriginTimer:isElapsedThenRestart(1) then
        self.shootAtOrigin = player:getOrigin() + Vector3:new(
            Client.getRandomFloat(-64, 64),
            Client.getRandomFloat(-64, 64),
            Client.getRandomFloat(64, 72)
        )
    end
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
    --- @type Player
    local selectedEnemy
    local lowestFov = math.huge
    local closestDistance = math.huge
    local player = Player.getClient()
    local origin = player:getOrigin()

    for _, enemy in pairs(AiUtility.enemies) do
        if self:hasNoticedEnemy(enemy) then
            local distance = origin:getDistance(enemy:getOrigin())

            if distance < closestDistance then
                closestDistance = distance
                selectedEnemy = enemy
            end
        end
    end

    for _, enemy in pairs(AiUtility.visibleEnemies) do
        local fov = AiUtility.enemyFovs[enemy.eid]
        local timer = self.noticedPlayerTimers[enemy.eid]

        if fov < 55 then
            self:noticeEnemy(enemy, Vector3.MAX_DISTANCE, "In field of view")
        end

        if self:hasNoticedEnemy(enemy) and fov < lowestFov and (timer:isStarted() and not timer:isElapsed(3)) then
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
end

--- @class AiStateEngageWeaponStats
--- @field name string
--- @field ranges table
--- @field firerates table
--- @field runAtCloseRange boolean
--- @field closeRange number
--- @field priorityHitbox number
--- @field isBoltAction boolean
--- @field evaluate fun(): boolean
---
--- @param enemy Player
--- @return void
function AiStateEngage:setWeaponStats(enemy)
    if not enemy then
        return
    end

    local player = Player.getClient()
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
                long = 1250,
                medium = 1000,
                short = 0
            },
            firerates = {
                long = 0.2,
                medium = 0.13,
                short = 0
            },
            runAtCloseRange = false,
            closeRange = 0,
            priorityHitbox = Player.hitbox.NECK,
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
                long = 1000,
                medium = 500,
                short = 0
            },
            firerates = {
                long = 0.2,
                medium = 0.08,
                short = 0.04
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
            runAtCloseRange = false,
            closeRange = 0,
            priorityHitbox = Player.hitbox.SPINE_1,
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
    elseif distance >= selectedWeaponType.ranges.medium then
        self.tapFireTime = selectedWeaponType.firerates.medium
    elseif distance >= selectedWeaponType.ranges.short then
        self.tapFireTime = selectedWeaponType.firerates.short
    else
        self.tapFireTime = 0
    end

    self.activeWeapon = selectedWeaponType.name
    self.priorityHitbox = selectedWeaponType.priorityHitbox
    self.canAutoStop = selectedWeaponType.runAtCloseRange and distance < selectedWeaponType.closeRange
end

--- @return void
function AiStateEngage:render()
    if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableAimbot:get() or not Menu.visualiseAimbot:get() then
        return
    end

    local player = Player.getClient()

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
    local player = Player.getClient()
    local canWalk
    local playerEid = Client.getEid()

    if self.bestTarget then
        local eyeOrigin = Client.getEyeOrigin()
        local predictedEyeOrigin = eyeOrigin + player:m_vecVelocity() * 0.8

        predictedEyeOrigin = eyeOrigin:getTraceLine(predictedEyeOrigin, playerEid)

        local _, _, eid = predictedEyeOrigin:getTraceLine(self.bestTarget:getHitboxPosition(Player.hitbox.NECK), playerEid)
        local enemyOrigin = AiUtility.closestEnemy:getOrigin()
        local distance = eyeOrigin:getDistance(enemyOrigin)

        if player:isCounterTerrorist() and AiUtility.plantedBomb and distance > 350 then
            canWalk = false
        elseif eid == self.bestTarget.eid then
            canWalk = false
        elseif distance < 1200 then
            canWalk = true
        end
    end

    if self.walkCheckTimer:isElapsedThenRestart(0.1) then
        self.walkCheckCount = Math.clamp(self.walkCheckCount - 1, 0, 20)
    end

    if self.walkCheckCount >= 10 then
        canWalk = false
    end

    for _, enemy in pairs(AiUtility.enemies) do
        if enemy:m_bIsDefusing() == 1 then
            canWalk = false
        end
    end

    self.isSneaking = canWalk

    if canWalk then
        ai.controller.isWalking = true
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:engage(ai)
    self:attack(ai)

    if not self.bestTarget then
        return
    end

    local targetOrigin = self.bestTarget:getOrigin()
    local task = ai.priority == AiState.priority.ENGAGE_VISIBLE and "Engaging %s" or "Moving to engage %s"

    -- Enemy is out of reach. Move to nearest node instead.
    if ai.nodegraph.pathfindFails > 0 then
        local node = ai.nodegraph:getClosestNode(targetOrigin)

        ai.nodegraph:pathfind(node.origin, {
            objective = Node.types.GOAL,
            ignore = self.bestTarget.eid,
            task = string.format(task, self.bestTarget:getName()),
            onComplete = function()
                ai.nodegraph:log("Reached target location")
            end
        })
    end

    if ai.nodegraph.path then
        local enemyOrigin = self.bestTarget:getOrigin()

        if self.bestTarget:getFlag(Player.flags.FL_ONGROUND) and enemyOrigin and not enemyOrigin:isZero() then
            if enemyOrigin:getDistance(ai.nodegraph.pathEnd.origin) > 128 then
                ai.nodegraph:clearPath("Enemy moved")
            end
        end
    end

    if not ai.nodegraph.path and ai.nodegraph:canPathfind() then
        if not self.bestTarget:isAlive() then
            self.bestTarget = nil

            return
        end

        local floor = targetOrigin:getTraceLine(targetOrigin + Vector3:new(0, 0, -Vector3.MAX_DISTANCE), self.bestTarget.eid)

        if targetOrigin.z - floor.z > 18 then
            return
        end

        ai.nodegraph:pathfind(self.bestTarget:getOrigin(), {
            objective = Node.types.GOAL,
            ignore = self.bestTarget.eid,
            task = string.format(task, self.bestTarget:getName()),
            onComplete = function()
                ai.nodegraph:log("Reached target location")
            end
        })
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:attack(ai)
    if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableAimbot:get() then
        return
    end

    -- Prevent using knife
    ai.controller.canUseKnife = false

    -- Prevent reloading when enemies visible
    if next(AiUtility.visibleEnemies) then
        ai.controller.canReload = false
        ai.controller.canUnscope = false
    end

    local player = Player.getClient()

    -- Ensure bot is holding a weapon
    if not player:isHoldingGun() then
        Client.equipWeapon()
    end

    -- Prevent weapon inspections
    ai.controller.canInspectWeapon = false

    -- Spray
    if self.sprayTimer:isStarted() and not self.sprayTimer:isElapsed(self.sprayTime) then
        ai.controller.canReload = false

        self:shoot(ai, self.watchOrigin)
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

    -- Shoot through smokes
    local isShootingThroughSmoke = self:shootThroughSmokes(ai, enemy)

    if not isShootingThroughSmoke then
        -- Shoot last position
        if not next(AiUtility.visibleEnemies) and self.watchOrigin then
            self:watchAngle(ai)
        end

        -- Pre-aim angle
        -- Pre-aim hitbox when peeking
        if self:hasNoticedEnemy(enemy) then
            self:preAimAboutCorners(ai)
            self:preAimThroughCorners(ai)
        end
    end

    -- Wide-peek enemies
    self:ferrariPeek(ai)

    -- Get target hitbox
    local hitbox = self:getHitbox(enemy)

    if not hitbox then
        return
    end

    -- Begin watching last angle
    if AiUtility.visibleEnemies[enemy.eid] then
        if hitbox then
            self.watchOrigin = hitbox
        end

        self.watchTimer:ifPausedThenStart()
        self.enemyVisibleTimer:ifPausedThenStart()
    else
        self.enemyVisibleTimer:stop()
    end

    local lastSeenEnemyTimer = self.lastSeenTimers[enemy.eid]

    self.currentReactionTime = (lastSeenEnemyTimer:isStarted() and not lastSeenEnemyTimer:isElapsed(2)) and self.anticipateTime or self.reactionTime

    local eyeOrigin = Client.getEyeOrigin()
    local distance = eyeOrigin:getDistance(hitbox)
    local fov = AiUtility.enemyFovs[enemy.eid]
    local shootFov = Math.clamp(Math.pct(distance, 512), 0, 90) * fov

    -- Ensure player is holding weapon
    if not player:isHoldingGun() then
        Client.equipWeapon()
    end

    -- Begin reaction timer
    if AiUtility.visibleEnemies[enemy.eid] and shootFov < 36 then
        self.reactionTimer:ifPausedThenStart()
    end

    -- Auto-stop
    if shootFov < 33 and self.enemyVisibleTimer:isElapsed(self.enemyVisibleTime) then
        self:autoStop(ai)
    end

    if AiUtility.visibleEnemies[enemy.eid] then
        -- Prevent jumping
        ai.nodegraph.canJump = false

        -- Do not look away from flashbangs
        ai.controller.canLookAwayFromFlash = false
    end

    -- React to visible enemy
    if self.reactionTimer:isElapsed(self.currentReactionTime) and AiUtility.visibleEnemies[enemy.eid] then
        -- Inhibit checking corners
        ai.view.canUseCheckNode = false

        -- Crouch
        if shootFov < 20 then
            ai.cmd.in_duck = 1
        end

        if player:isHoldingSniper() and shootFov < 8 then
            Client.scope()
        elseif player:m_bIsScoped() == 1 and shootFov > 10 then
            Client.unscope()
        end

        if shootFov < 12 then
            self:noticeEnemy(enemy,4096, "In shoot FoV")
            self:shoot(ai, hitbox, shootFov, enemy)

            ai.controller.canLookAwayFromFlash = false

            self.sprayTimer:start()
            self.watchTimer:start()
            self.lastSeenTimers[enemy.eid]:start()
        elseif fov < 40 then
            ai.view:lookAt(hitbox, self.aimSpeed * 0.8)

            self.watchTimer:start()
            self.lastSeenTimers[enemy.eid]:start()
            self:noticeEnemy(enemy,4096, "In React FoV")
        elseif fov >= 40 and self:hasNoticedEnemy(enemy) then
            ai.view:lookAt(hitbox, self.slowAimSpeed)
        end
    end
end

--- @param enemy Player
--- @return Vector3
function AiStateEngage:getHitbox(enemy)
    --- @type Vector3
    local targetHitbox
    local hitboxes = Player.hitbox

    local eid = Client.getEid()
    local eyeOrigin = Client.getEyeOrigin()

    for hitboxId, hitbox in pairs(enemy:getHitboxPositions(hitboxes)) do
        local _, _, hitEid = eyeOrigin:getTraceLine(hitbox, eid)

        if hitboxId == self.priorityHitbox and hitEid == enemy.eid then
            targetHitbox = hitbox

            break
        elseif hitEid == enemy.eid then
            targetHitbox = hitbox
        end
    end

    return targetHitbox
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
        and not self.lastSoundTimer:isElapsed(6)
    then
        local fov = cameraAngles:getFov(eyeOrigin, self.shootAtOrigin)
        local shootFov = Math.clamp(Math.pct(eyeOrigin:getDistance(self.shootAtOrigin), 512), 0, 90) * fov

        if self.noticedPlayerTimers[enemy.eid]:get() < 2 then
            self:shoot(ai, self.shootAtOrigin, shootFov)
        else
            ai.view:lookAt(self.shootAtOrigin, self.slowAimSpeed)
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

    local player = Player.getClient()
    local playerEid = Client.getEid()
    local playerOrigin = player:getOrigin()
    local traceOrigin = player:getOrigin():offset(0, 0, 46)
    local enemyOrigin = enemy:getOrigin()
    local angleToEnemy = playerOrigin:getAngle(enemyOrigin)
    local directions = {
        "Left",
        "Right"
    }
    local steps = 4
    local step = 16
    --- @type Angle
    local moveAngles

    for _, direction in pairs(directions) do
        if moveAngles then
            break
        end

        --- @type Vector3
        local traceDrection = Nyx.call(angleToEnemy, string.format("get%s", direction))

        for i = 1, steps do
            local traceOrigin, fraction = traceOrigin:getTraceLine(traceOrigin + (traceDrection * i * step), playerEid)

            if fraction ~= 1 then
                break
            end

            local isVisible = false

            for _, hitbox in pairs(enemy:getHitboxPositions({
                Player.hitbox.HEAD,
                Player.hitbox.SPINE_0,
                Player.hitbox.SPINE_2,
                Player.hitbox.PELVIS,
                Player.hitbox.LEFT_LOWER_LEG,
                Player.hitbox.RIGHT_LOWER_LEG,
                Player.hitbox.LEFT_LOWER_ARM,
                Player.hitbox.RIGHT_LOWER_ARM,
            })) do
                local _, _, eid = traceOrigin:getTraceLine(hitbox, playerEid)

                if eid == enemy.eid then
                    isVisible = true

                    break
                end
            end

            if isVisible then
                moveAngles = playerOrigin:getAngle(traceOrigin)

                break
            end
        end
    end

    if moveAngles then
        ai.nodegraph.moveSpeed = 450
        ai.nodegraph.moveYaw = moveAngles.y
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:preAimThroughCorners(ai)
    local target = self.bestTarget

    if not target then
        return
    end

    local isVisible = false

    -- enemy is already visible
    if AiUtility.visibleEnemies[target.eid] then
        isVisible = true
    end

    local player = Player.getClient()
    local eid = Client.getEid()
    local playerOrigin = player:getOrigin()

    if not isVisible then
        local playerVelocity = player:m_vecVelocity()
        local box = playerOrigin:getBox(16, 16, 72, Vector3.align.BOTTOM)

        -- don't generate multiple boxes if we're standing still.
        -- adjusted this since we never really need more than 1 step.
        local steps = 1

        -- our "smear" of boxes producing a series of boxes extending out in our movement direction.
        local smear = {}

        -- how far the smear extends.
        local distance = 0.1

        -- create the smear in reverse-distance order, as the farthest box is most likely to see the enemy.
        for i = steps, 1, -1 do
            for _, vertex in pairs(box) do
                table.insert(smear, vertex + playerVelocity * distance * i)
            end
        end

        local hitboxes = target:getHitboxPositions({
            Player.hitbox.HEAD,
            Player.hitbox.PELVIS,
            Player.hitbox.LEFT_LOWER_ARM,
            Player.hitbox.RIGHT_LOWER_ARM,
            Player.hitbox.LEFT_UPPER_LEG,
            Player.hitbox.RIGHT_UPPER_LEG,
        })

        for _, hitbox in pairs(hitboxes) do
            hitbox = hitbox + target:m_vecVelocity() * 0.3

            local _, fraction = hitbox:getTraceLine(playerOrigin, eid)

            if fraction == 1 then
                return
            end
        end

        for _, vertex in pairs(smear) do
            if isVisible then
                break
            end

            for _, hitbox in pairs(hitboxes) do
                local _, fraction, eid = vertex:getTraceLine(hitbox, eid)

                if fraction == 1 or eid == target.eid then
                    isVisible = true

                    break
                end
            end
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

    if self.preAimTarget and not self.bestTarget:is(self.preAimTarget) then
        self.preAimAroundCornersTimer:stop()
    end

    if isVisible then
        self.preAimAroundCornersTimer:start()
    end

    if self.preAimAroundCornersTimer:isStarted() and not self.preAimAroundCornersTimer:isElapsed(self.preAimAroundCornersTime) then
        self.preAimTarget = self.bestTarget

        ai.view:lookAt(self.preAimCornerOrigin, self.slowAimSpeed)
    end
end

--- @param ai AiOptions
--- @return void
function AiStateEngage:preAimAboutCorners(ai)
    if not self.bestTarget or not self.bestTarget:isAlive() then
        return
    end

    local playerOrigin = Player.getClient():getOrigin()
    local distance = playerOrigin:getDistance2(self.bestTarget:getOrigin())

    -- Pre-aim angle
    local radius = math.min(128, distance * 0.66)
    local density = math.max(2, 750 / distance)
    local idealCount = 45
    local count = idealCount / density
    local countInto = 180 / idealCount
    local bands = 1
    local offsets = 6
    local eyeOrigin = Client.getEyeOrigin()
    local enemy = self.bestTarget
    local startPitch = eyeOrigin:getAngle(enemy:getEyeOrigin()).p + (bands * offsets) / 2

    if self.preAimOriginTimer:isElapsedThenRestart(0.5) then
        self.preAimOrigin = enemy:getOrigin():offset(0, 0, 60)
    end

    local start = eyeOrigin:getAngle(self.preAimOrigin):getRight():getAngle(Vector3:new())

    --- @type Vector3
    local closestVertex
    local closestDistance = math.huge

    for i = 1, bands do
        for j = 1, count  do
            local vertexIdeal = self.preAimOrigin + start:clone():offset((i * offsets) - startPitch, j * density * countInto):getForward() * radius

            local vertex = self.preAimOrigin:getTraceLine(vertexIdeal, enemy.eid)
            local _, fraction = eyeOrigin:getTraceLine(vertex, Client.getEid())

            if fraction == 1 and not eyeOrigin:isRayIntersectingSmoke(vertex) then
                local distance = eyeOrigin:getDistance(vertex)

                if distance < closestDistance then
                    closestDistance = distance
                    closestVertex = vertex
                end
            end
        end
    end

    if closestVertex then
        ai.controller.canUnscope = false

        self.watchOrigin = closestVertex

        self.watchTimer:start()

        ai.view:lookAt(closestVertex, self.slowAimSpeed)
    end
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

    if self.watchTimer:isElapsedThenStop(self.watchTime) and self.sprayTimer:isElapsedThenStop(self.sprayTime) then
        self.watchOrigin = nil
    end

    ai.view:lookAt(self.watchOrigin, self.aimSpeed)
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

    if self.hitboxOffsetTimer:isElapsedThenRestart(0.66) then
        self.hitboxOffset = Vector3:newRandom(-self.aimOffset, self.aimOffset) + Vector3:new(0, 0, -self.aimOffset / 2)
    end

    local eyeOrigin = Client.getEyeOrigin()
    local player = Player.getClient()
    local aimAt = hitbox + self.hitboxOffset
    local viewAngles = eyeOrigin:getAngle(aimAt)

    if enemy then
        local _, _, eid = eyeOrigin:getTraceLine(hitbox, Client.getEid())

        if eid ~= enemy.eid then
            return
        end
    end

    ai.view:lookAt(aimAt, self.aimSpeed)

    -- Do not shoot teammates
    local weapon = Entity:create(player:m_hActiveWeapon())
    local ammo = weapon:m_iClip1()
    local _, _, eid = Client.getCameraTraceLine(eyeOrigin + viewAngles:getForward() * Vector3.MAX_DISTANCE)

    if eid and Player.isPlayer(eid) and Player:new(eid):isTeammate() then
        return
    end

    if player:m_vecVelocity():getMagnitude() > 100 then
        return
    end

    if player:isHoldingSniper() then
        local fireUnderVelocity = CsgoWeapons[weapon:m_iItemDefinitionIndex()].max_player_speed / 5

        local fireDelay = 0.3

        if eyeOrigin:getDistance(hitbox) > 750 then
            fireDelay = 0.4
        end

        if player:m_vecVelocity():getMagnitude() < fireUnderVelocity and
            self.scopedTimer:isElapsed(fireDelay) and
            player:m_bIsScoped() == 1 and
            (fov and fov < 3) then
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
        return
    end

    local player = Player.getClient()

    if player:isHoldingSniper() then
        ai.nodegraph.moveSpeed = 0

        return
    end

    local inverseVelocity = -player:m_vecVelocity()

    if inverseVelocity:getMagnitude() < 75 then
        ai.nodegraph.moveSpeed = 0

        return
    end

    local velocityAngles = inverseVelocity:normalize():getAngleFromForward()

    ai.nodegraph.moveYaw = velocityAngles.y
    ai.nodegraph.moveSpeed = 450
end

--- @param skill number
--- @return void
function AiStateEngage:setAimSkill(skill)
    self.skill = skill

    local skills = {
        [0] = {
            reactionTime = 0.3,
            anticipationTime = 0.01,
            sprayTime = 0.45,
            aimSpeed = 4,
            slowAimSpeed = 4,
            recoilControl = 2.4,
            aimOffset = 20,
        },
        [1] = {
            reactionTime = 0.2,
            anticipationTime = 0.01,
            sprayTime = 0.45,
            aimSpeed = 6,
            slowAimSpeed = 6,
            recoilControl = 2,
            aimOffset = 15,
        },
        [2] = {
            reactionTime = 0.1,
            anticipationTime = 0.01,
            sprayTime = 0.45,
            aimSpeed = 8,
            slowAimSpeed = 8,
            recoilControl = 2,
            aimOffset = 10,
        },
        [3] = {
            reactionTime = 0.075,
            anticipationTime = 0.01,
            sprayTime = 0.45,
            aimSpeed = 10,
            slowAimSpeed = 10,
            recoilControl = 2,
            aimOffset = 5,
        },
        [4] = {
            reactionTime = 0.05,
            anticipationTime = 0.01,
            sprayTime = 0.45,
            aimSpeed = 12,
            slowAimSpeed = 10,
            recoilControl = 2,
            aimOffset = 0,
        }
    }

    for k, v in pairs(skills[skill]) do
        self[k] = v
    end
end

--- @param skill number
--- @return void
function AiStateEngage:setAimSkillOld(skill)
    skill = Math.clamp(skill * 0.01, 0, 1)

    local skillValues = {
        reactionTime = Math.clamp((1 - skill) * 0.2, 0.05, 0.2),
        anticipationTime = Math.clamp((1 - skill) * 0.066, 0.15, 0.066),
        sprayTime = Math.clamp((1 - skill) * 1, 0.5, 1),
        aimSpeed = Math.clamp(22 * skill, 4, 22),
        slowAimSpeed = Math.clamp(15 * skill, 3, 15),
        recoilControl = Math.clamp((2 - skill) * 2, 1.8, 2),
        aimOffset = Math.clamp((1 - skill) * 15, 0.1, 10)
    }

    for k, v in pairs(skillValues) do
        self[k] = v
    end
end

return Nyx.class("AiStateEngage", AiStateEngage, AiState)
--}}}
