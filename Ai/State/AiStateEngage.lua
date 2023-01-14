--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local CsgoWeapons = require "gamesense/csgo_weapons"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
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
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ Definitions
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
--- @field fov number
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
--- @class AiStateEngage : AiStateBase
--- @field activeWeapon string
--- @field aimInaccurateOffset number
--- @field aimNoise ViewNoise
--- @field aimOffset number
--- @field aimSpeed number
--- @field anticipateTime number
--- @field bestTarget Player
--- @field blockMovementAfterPlantTimer Timer
--- @field blockTime number
--- @field blockTimer Timer
--- @field canWallbang boolean
--- @field currentReactionTime number
--- @field defendActionTime number
--- @field defendActionTimer Timer
--- @field defendingAtNode NodeTypeDefend
--- @field defendingLookAt Vector3
--- @field defendLookAtOffset Vector3
--- @field enemySpottedCooldown Timer
--- @field enemyVisibleTime number
--- @field enemyVisibleTimer Timer
--- @field fov number
--- @field hasBackupCover boolean
--- @field hitboxOffset Vector3
--- @field hitboxOffsetTimer Timer
--- @field ignorePlayerAfter number
--- @field isAboutToBeVisibleToBestTarget boolean
--- @field isAimEnabled boolean
--- @field isAllowedToJiggleHold boolean
--- @field isAllowedToNoscope boolean
--- @field isBackingUp boolean
--- @field isBestTargetVisible boolean
--- @field isCrouchingOnDefend boolean
--- @field isDefending boolean
--- @field isHoldingAngle boolean
--- @field isHoldingAngleDucked boolean
--- @field isIgnoringDormancy boolean
--- @field isInJiggleHold boolean
--- @field isJigglingOnDefend boolean
--- @field isPreAimViableForHoldingAngle boolean
--- @field isRcsEnabled boolean
--- @field isRefreshingAttackPath boolean
--- @field isRunAndShootAllowed boolean
--- @field isSneaking boolean
--- @field isStrafePeeking boolean
--- @field isTargetEasilyShot boolean
--- @field isUpdatingDefendingLookAt boolean
--- @field isVisibleToBestTarget boolean
--- @field jiggleHoldCooldownTimer Timer
--- @field jiggleHoldCount number
--- @field jiggleHoldDirection Angle
--- @field jiggleHoldThreshold number
--- @field jiggleHoldTime number
--- @field jiggleHoldTimer Timer
--- @field jiggleShootDirection string
--- @field jiggleShootTime number
--- @field jiggleShootTimer Timer
--- @field lastBestTargetOrigin Vector3
--- @field lastBestTargetValidOrigin Vector3
--- @field lastMoveDirection Vector3
--- @field lastSeenTimers Timer[]
--- @field lastSoundTimer Timer
--- @field lookAtBackingUpOrigin Vector3
--- @field noticedLoudPlayerTimers Timer[]
--- @field noticedPlayerLastKnownOrigin Vector3[]
--- @field noticedPlayerTimers Timer[]
--- @field onGroundTime Timer
--- @field onGroundTimer Timer
--- @field overrideBestTarget Player
--- @field patienceCooldownTimer Timer
--- @field patienceTimer Timer
--- @field pingEnemyTimer Timer
--- @field preAimAboutCornersAimOrigin Vector3
--- @field preAimAboutCornersCenterOrigin Vector3
--- @field preAimAboutCornersCenterOriginZ number
--- @field preAimAboutCornersLastOrigin Vector3
--- @field preAimTarget Player
--- @field preAimThroughCornersBlockTimer Timer
--- @field preAimThroughCornersOrigin Vector3
--- @field preAimThroughCornersUpdateTimer Timer
--- @field prefireReactionTime number
--- @field priorityHitbox number
--- @field randomizeFireDelay number
--- @field randomizeFireDelayTime number
--- @field randomizeFireDelayTimer Timer
--- @field reactionTime number
--- @field reactionTimer Timer
--- @field recoilControl number
--- @field scopedTimer Timer
--- @field seekCoverTimer Timer
--- @field setBestTargetTimer Timer
--- @field shootAtOrigin Vector3
--- @field shootWithinFov number
--- @field skill number
--- @field skillLevelMax number
--- @field skillLevelMin number
--- @field slowAimSpeed number
--- @field smokeWallBangHoldTimer Timer
--- @field sprayTime number
--- @field sprayTimer Timer
--- @field strafePeekDirection string
--- @field strafePeekIndex number
--- @field strafePeekMoveAngle Angle
--- @field strafePeekTimer Timer
--- @field tapFireTime number
--- @field tapFireTimer Timer
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
    isMouseDelayAllowed = false,
    skillLevelMin = 0,
    skillLevelMax = 10,
    isLockable = false
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
    self.ignorePlayerAfter = 35 -- todo replace sensing
    self.isIgnoringDormancy = false
    self.isSneaking = false
    self.jiggleShootDirection = "Left"
    self.jiggleShootTime = Math.getRandomFloat(0.33, 0.66)
    self.jiggleShootTimer = Timer:new():startThenElapse()
    self.lastSoundTimer = Timer:new():start()
    self.noticedPlayerTimers = {}
    self.noticedPlayerLastKnownOrigin = {}
    self.onGroundTime = 0.1
    self.onGroundTimer = Timer:new()
    self.patienceCooldownTimer = Timer:new():startThenElapse()
    self.patienceTimer = Timer:new()
    self.preAimOriginDelayed = Vector3:new()
    self.preAimThroughCornersBlockTimer = Timer:new():startThenElapse()
    self.preAimThroughCornersUpdateTimer = Timer:new():startThenElapse()
    self.reactionTimer = Timer:new()
    self.scopedTimer = Timer:new()
    self.setBestTargetTimer = Timer:new():startThenElapse()
    self.sprayTimer = Timer:new()
    self.tapFireTime = 0.2
    self.tapFireTimer = Timer:new():start()
    self.walkCheckCount = 0
    self.walkCheckTimer = Timer:new():start()
    self.watchTime = 2
    self.watchTimer = Timer:new()
    self.smokeWallBangHoldTimer = Timer:new()
    self.visibleReactionTimer = Timer:new()
    self.visualizerCallbacks = {}
    self.visualizerExpiryTimers = {}
    self.aimNoise = VirtualMouse.noise.moving
    self.seekCoverTimer = Timer:new():startThenElapse()
    self.strafePeekTimer = Timer:new():startThenElapse()
    self.strafePeekIndex = 1
    self.randomizeFireDelayTimer = Timer:new():startThenElapse()
    self.randomizeFireDelayTime = 0
    self.randomizeFireDelay = 0
    self.pingEnemyTimer = Timer:new():startThenElapse()
    self.fov = 0
    self.isAllowedToNoscope = false
    self.jiggleHoldTimer = Timer:new():startThenElapse()
    self.jiggleHoldTime = 0.3
    self.jiggleHoldCount = 0
    self.jiggleHoldCooldownTimer = Timer:new():startThenElapse()
    self.jiggleHoldThreshold = 4
    self.isAllowedToJiggleHold = true
    self.defendActionTimer = Timer:new():startThenElapse()
    self.defendActionTime = 1
    self.defendLookAtOffset = Vector3:new()
    self.blockMovementAfterPlantTimer = Timer:new():startThenElapse()

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

    self:setAimSkill(Config.defaultSkillLevel)
end

--- @return void
function AiStateEngage:initEvents()
    Callbacks.playerFootstep(function(e)
        if e.player:isLocalPlayer() then
            self.lastSoundTimer:restart()
        end

        if e.player:isEnemy() or e.player:isLocalPlayer() then
            return
        end

        if LocalPlayer:getOrigin():getDistance(e.player:getOrigin()) > 600 then
            return
        end

        self.walkCheckCount = self.walkCheckCount + 1
    end)

    Callbacks.weaponFire(function(e)
        if e.player:isLocalPlayer() then
            self.isAllowedToNoscope = Math.getChance(2)

            self.lastSoundTimer:restart()
        end

        if e.player:isEnemy() or e.player:isLocalPlayer() then
            return
        end

        if LocalPlayer:getOrigin():getDistance(e.player:getOrigin()) > 600 then
            return
        end

        self.walkCheckCount = self.walkCheckCount + 1
    end)

    Callbacks.playerSpawned(function(e)
        if e.player:isLocalPlayer() then
            self:reset()
        else
            self:unnoticeEnemy(e.player)
        end
    end)

    Callbacks.roundStart(function()
        self:reset()

        self.defendingLookAt = nil
        self.isIgnoringDormancy = true
        self.jiggleShootTime = Math.getRandomFloat(0.33, 0.66)
        self.defendLookAtOffset = Vector3:new(
            Math.getRandomFloat(-256, 256),
            Math.getRandomFloat(-256, 256),
            Math.getRandomFloat(-10, 10)
        )
    end)

    Callbacks.runCommand(function()
        local bomb = AiUtility.plantedBomb

        if bomb and LocalPlayer:isCounterTerrorist() then
            local bombOrigin = bomb:m_vecOrigin()

            for _, enemy in pairs(AiUtility.enemies) do
                if bombOrigin:getDistance(enemy:getOrigin()) < 512 then
                    self:noticeEnemy(enemy, 500, false, "Near Site")
                end
            end
        end

        if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE and AiUtility.isHostageCarriedByEnemy then
            for _, enemy in pairs(AiUtility.hostageCarriers) do
                self:noticeEnemy(enemy, Vector3.MAX_DISTANCE, true, "Carrying hostage")
            end
        end

        if LocalPlayer:m_bIsScoped() == 1 then
            self.scopedTimer:ifPausedThenStart()
        else
            self.scopedTimer:stop()
        end
    end)

    Callbacks.playerHurt(function(e)
        if not e.victim:isLocalPlayer() then
            return
        end

        self.jiggleHoldCooldownTimer:restart()

        self:noticeEnemy(e.attacker, Vector3.MAX_DISTANCE, true, "Shot by")
    end)

    Callbacks.playerFootstep(function(e)
        local isLoud = LocalPlayer:getOrigin():getDistance(e.player:getOrigin()) < 450

        self:noticeEnemy(e.player, 1100, isLoud, "Stepped")
    end)

    Callbacks.playerJump(function(e)
        self:noticeEnemy(e.player, 700, false, "Jumped")
    end)

    Callbacks.weaponZoom(function(e)
        self:noticeEnemy(e.player, 650, false, "Scoped")
    end)

    Callbacks.weaponReload(function(e)
        self:noticeEnemy(e.player, 800, false, "Reloaded")
    end)

    Callbacks.weaponFire(function(e)
        if e.player:isLocalPlayer() or e.player:is(self.bestTarget) then
            self.jiggleHoldCooldownTimer:restart()
        end

        if CsgoWeapons[e.weapon].is_melee_weapon then
            self:noticeEnemy(e.player, 600, true, "Knifed")

            return
        end

        local range = 2000

        if AiUtility.visibleEnemies[e.player.eid] then
            range = Vector3.MAX_DISTANCE
        end

        self:noticeEnemy(e.player, range, true, "Shot")
    end)

    Callbacks.bulletImpact(function(e)
        if not e.shooter:isEnemy() then
            return
        end

        local eyeOrigin = LocalPlayer.getEyeOrigin()
        local rayIntersection = eyeOrigin:getRayClosestPoint(e.shooter:getEyeOrigin(), e.origin)

        if eyeOrigin:getDistance(rayIntersection) > 450 then
            return
        end

        self:noticeEnemy(e.shooter, Vector3.MAX_DISTANCE, true, "Shot at")
    end)

    Callbacks.bombBeginDefuse(function(e)
        if e.player:isEnemy() then
            self.isRefreshingAttackPath = true
        end

        self:noticeEnemy(e.player, Vector3.MAX_DISTANCE, true, "Began defusing")
    end)

    Callbacks.bombBeginPlant(function(e)
        if e.player:isEnemy() then
            self.isRefreshingAttackPath = true
        end

        self:noticeEnemy(e.player, Vector3.MAX_DISTANCE, true, "Began planting")
    end)

    Callbacks.grenadeThrown(function(e)
        self:noticeEnemy(e.player, 750, true, "Threw grenade")
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isLocalPlayer() then
            self:reset()

            return
        end

        if e.victim:is(self.bestTarget) then
            self.isAllowedToJiggleHold = Math.getChance(2)
        end

        if e.attacker:isLocalPlayer() and e.victim:isEnemy() then
            self.blockTimer:start()
        end

        if e.victim:isTeammate() and LocalPlayer:getOrigin():getDistance(e.victim:getOrigin()) < 1250 then
            self:noticeEnemy(e.attacker, 2000, true, "Teammate killed")
        end

        if e.victim:isEnemy() and self.noticedPlayerTimers[e.victim.eid] then
            self.noticedPlayerTimers[e.victim.eid]:stop()
            self.noticedLoudPlayerTimers[e.victim.eid]:stop()
            self.lastSeenTimers[e.victim.eid]:stop()
        end
    end)

    Callbacks.overrideView(function(view)
    	self.fov = view.fov
    end)

    Callbacks.bombPlanted(function(e)
        if not e.player:isLocalPlayer() then
            return
        end

        self.blockMovementAfterPlantTimer:restart()
    end)
end

--- @return void
function AiStateEngage:assess()
    self:setBestTarget()

    self.sprayTimer:isElapsedThenStop(self.sprayTime)
    self.watchTimer:isElapsedThenStop(self.watchTime)

    local clientOrigin = LocalPlayer:getOrigin()

    -- Do not try to engage people from inside of a smoke.
    -- It looks really dumb.
    for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
        local smokeTick = smoke:m_nFireEffectTickBegin()

        if smokeTick and smokeTick > 0 and clientOrigin:getDistance(smoke:m_vecOrigin()) < 115 then
            return AiPriority.IGNORE
        end
    end

    -- Panic fire while flashbanged.
    if LocalPlayer.isFlashed() and self.bestTarget and AiUtility.visibleEnemies[self.bestTarget.eid] then
        return AiPriority.ENGAGE_PANIC
    end

    if self.overrideBestTarget then
        return AiPriority.ENGAGE_ACTIVE
    end

    -- Engage enemies.
    for _, enemy in pairs(AiUtility.enemies) do
        if AiUtility.visibleEnemies[enemy.eid] and self:isEnemySensed(enemy) then
            if Pathfinder.isInsideInferno then
                return AiPriority.ENGAGE_INSIDE_INFERNO
            end

            return AiPriority.ENGAGE_ACTIVE
        end
    end

    if self.sprayTimer:isStarted() then
        return AiPriority.ENGAGE_ACTIVE
    end

    -- todo this will definitely cause the AI to become stuck if we do not handle pathfinding when the defuser is dormant.
    if AiUtility.isBombBeingDefusedByEnemy then
        return AiPriority.ENGAGE_ACTIVE
    end

    if AiUtility.isBombBeingPlantedByEnemy and AiUtility.bombCarrier then
        return AiPriority.ENGAGE_ACTIVE
    end

    if AiUtility.isHostageCarriedByEnemy and not Table.isEmpty(AiUtility.hostageCarriers) then
        return AiPriority.ENGAGE_ACTIVE
    end

    -- Makes the AI faster when the bomb is down.
    if not AiUtility.plantedBomb then
        if self.reactionTimer:isStarted() then
            return AiPriority.ENGAGE_PASSIVE
        end

        if self.watchTimer:isStarted() then
            return AiPriority.ENGAGE_PASSIVE
        end
    end

    if self:isAnyEnemiesSensed() then
        return AiPriority.ENGAGE_PASSIVE
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateEngage:activate()
    if self.enemySpottedCooldown:isElapsedThenRestart(60) then
        if AiUtility.bombCarrier and AiUtility.bombCarrier:is(self.bestTarget) and LocalPlayer:isCounterTerrorist() then
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
function AiStateEngage:deactivate()
    self.isDefending = false
end

--- @return void
function AiStateEngage:reset()
    self.reactionTimer:stop()
    self.sprayTimer:stop()
    self.watchTimer:stop()
    self.watchOrigin = nil
    self.bestTarget = nil
    self.lastBestTargetOrigin = nil

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
    if not MenuGroup.master:get() or not MenuGroup.enableAi:get() then
        return
    end

    self:handleMovement()
    self:handleAttacking(cmd)
    self:handleCommunications()
    self:handleShiftWalking()
end

--- @return void
function AiStateEngage:handleCommunications()
    if self.pingEnemyTimer:isElapsed(40) then
        self:pingEnemy()
    end
end

--- @return void
function AiStateEngage:pingEnemy()
    if not AiUtility.isClientThreatenedMinor then
        return
    end

    local cameraAngles = LocalPlayer.getCameraAngles()
    local clientEyeOrigin = LocalPlayer.getEyeOrigin()
    local trace = Trace.getLineAlongCrosshair()

    for _, enemy in pairs(AiUtility.enemies) do repeat
        local enemyEyeOrigin = enemy:getEyeOrigin()
        local fov = cameraAngles:getFov(clientEyeOrigin, enemyEyeOrigin)

        if enemyEyeOrigin:getDistance(trace.endPosition) < 500 and fov < 15 then
            LocalPlayer.ping()

            Client.fireAfterRandom(0.12, 0.5, function()
                LocalPlayer.ping()
            end)

            self.pingEnemyTimer:restart()

            return
        end
    until true end
end

--- @param player Player
--- @param range number
--- @param isLoud boolean
--- @param reason string
--- @return void
function AiStateEngage:noticeEnemy(player, range, isLoud, reason)
    if not LocalPlayer:isAlive() then
        return
    end

    if player:isTeammate() then
        return
    end

    local enemyOrigin = player:getOrigin()

    if enemyOrigin:isZero() then
        return
    end

    if LocalPlayer:getOrigin():getDistance(enemyOrigin) > range then
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
function AiStateEngage:isAnyEnemiesSensed()
    for _, enemy in pairs(AiUtility.enemies) do
        if self:isEnemySensed(enemy) then
            return true
        end
    end

    return false
end

--- @param enemy Player
--- @return boolean
function AiStateEngage:isEnemySensed(enemy)
    local timer = self.noticedPlayerTimers[enemy.eid]
    local ignorePlayerAfter = self.ignorePlayerAfter

    if LocalPlayer.isCarryingBomb() then
        ignorePlayerAfter = 4.5
    end

    return timer:isStarted() and not timer:isElapsed(ignorePlayerAfter)
end

--- @param enemy Player
--- @return boolean
function AiStateEngage:isEnemyLoudlySensed(enemy)
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
    if self.overrideBestTarget then
        self.bestTarget = self.overrideBestTarget

        self:setWeaponStats(self.overrideBestTarget)
        self:setIsVisibleToBestTarget()

        return
    end

    --- @type Player
    local selectedEnemy
    local lowestFov = math.huge
    local closestDistance = math.huge
    local origin = LocalPlayer:getOrigin()

    for _, enemy in pairs(AiUtility.enemies) do
        -- The first few if statements ignore the AI's sensing system.

        -- Defuser.
        if enemy:m_bIsDefusing() == 1 then
            selectedEnemy = enemy

            break
        end

        -- Hostage carrier.
        if AiUtility.hostageCarriers[enemy.eid] then
            selectedEnemy = enemy

            break
        end

        -- Picking up a hostage.
        if enemy:m_bIsGrabbingHostage() == 1 then
            selectedEnemy = enemy

            break
        end

        -- Planter.
        if AiUtility.bombCarrier and AiUtility.bombCarrier:is(enemy) and AiUtility.isBombBeingPlantedByEnemy then
            selectedEnemy = enemy

            break
        end

        if self:isEnemySensed(enemy) then
            local distance = origin:getDistance(enemy:getOrigin())

            if distance < closestDistance then
                closestDistance = distance
                selectedEnemy = enemy
            end
        end
    end

    local isUrgent = false

    for _, enemy in pairs(AiUtility.visibleEnemies) do
        -- We run these if statements again.
        -- The AI will defer to attacking visible enemies, but if the visible enemy is doing any of the below,
        -- then we want to focus on them instead.

        -- Defuser.
        if enemy:m_bIsDefusing() == 1 then
            selectedEnemy = enemy

            break
        end

        -- Hostage carrier.
        if AiUtility.hostageCarriers[enemy.eid] then
            selectedEnemy = enemy

            break
        end

        -- Picking up a hostage.
        if enemy:m_bIsGrabbingHostage() == 1 then
            selectedEnemy = enemy

            break
        end

        -- Planter.
        -- Do not prioritse the planter over other visible threats. Pick the best threat instead.

        local fov = AiUtility.enemyFovs[enemy.eid]

        if fov < 55 then
            self:noticeEnemy(enemy, Vector3.MAX_DISTANCE, false, "In field of view")
        end

        if self:isEnemySensed(enemy) and fov < lowestFov then
            lowestFov = fov
            selectedEnemy = enemy
            isUrgent = true
        end
    end

    if self.bestTarget and not self.bestTarget:isAlive() then
        self.watchTimer:stop()
    end

    if self.setBestTargetTimer:isElapsedThenRestart(1) or isUrgent then
        if self.bestTarget and selectedEnemy then
            -- Clear last valid origin as it's no longer for the same target.
            if selectedEnemy:is(self.bestTarget) then
                self.lastBestTargetValidOrigin = nil
            end

            local targetOrigin = self.bestTarget:getOrigin()

            -- Update the last valid origin if it is not zero.
            if targetOrigin and not targetOrigin:isZero() then
                self.lastBestTargetValidOrigin = targetOrigin
            end
        end

        self.bestTarget = selectedEnemy
    end

    if self.bestTarget and AiUtility.visibleEnemies[self.bestTarget.eid] then
        self.watchTimer:ifPausedThenStart()
    end

    self:setWeaponStats(selectedEnemy)
    self:setIsVisibleToBestTarget()
end

--- @param enemy Player
--- @return void
function AiStateEngage:setWeaponStats(enemy)
    if not enemy then
        return
    end

    local weapon = LocalPlayer:getWeapon()
    local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
    --- @type AiStateEngageWeaponStats[]
    local weaponTypes = {
        {
            name = "Auto-Sniper",
            weaponMode = WeaponMode.SNIPER,
            fov = 6,
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
                return LocalPlayer:isHoldingWeapons({
                    Weapons.SCAR20,
                    Weapons.G3SG1
                })
            end
        },
        {
            name = "AWP",
            weaponMode = WeaponMode.SNIPER,
            fov = 3.5,
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
                return LocalPlayer:isHoldingWeapon(Weapons.AWP)
            end
        },
        {
            name = "Scout",
            weaponMode = WeaponMode.SNIPER,
            fov = 3,
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
                return LocalPlayer:isHoldingWeapon(Weapons.SSG08)
            end
        },
        {
            name = "LMG",
            weaponMode = WeaponMode.HEAVY,
            fov = 16,
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
                return LocalPlayer:isHoldingLmg()
            end
        },
        {
            name = "Rifle",
            weaponMode = WeaponMode.HEAVY,
            fov = 16,
            ranges = {
                long = 2000,
                medium = 1500,
                short = 0
            },
            firerates = {
                long = 0.4,
                medium = 0.24,
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
                return LocalPlayer:isHoldingRifle()
            end
        },
        {
            name = "Shotgun",
            weaponMode = WeaponMode.SHOTGUN,
            fov = 5,
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
                return LocalPlayer:isHoldingShotgun()
            end
        },
        {
            name = "SMG",
            weaponMode = WeaponMode.LIGHT,
            fov = 18,
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
                return LocalPlayer:isHoldingSmg()
            end
        },
        {
            name = "Desert Eagle",
            -- The Deagle really cannot use pistol shooting/movement logic.
            weaponMode = WeaponMode.HEAVY,
            fov = 5,
            ranges = {
                long = 700,
                medium = 300,
                short = 0
            },
            firerates = {
                long = 0.65,
                medium = 0.33,
                short = 0.15
            },
            isRcsEnabled = {
                long = true,
                medium = true,
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
            fov = 5,
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
            fov = 9,
            ranges = {
                long = 1200,
                medium = 450,
                short = 0
            },
            firerates = {
                long = 0.26,
                medium = 0.1,
                short = 0
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
            fov = 4.5,
            ranges = {
                long = 1850,
                medium = 600,
                short = 0
            },
            firerates = {
                long = 0.45,
                medium = 0.24,
                short = 0
            },
            isRcsEnabled = {
                long = true,
                medium = true,
                short = true
            },
            runAtCloseRange = true,
            priorityHitbox = Player.hitbox.HEAD,
            evaluate = function()
                return LocalPlayer:isHoldingPistol()
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

    local distance = LocalPlayer:getOrigin():getDistance(enemy:getOrigin())

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

    if self.randomizeFireDelayTimer:isElapsedThenRestart(self.randomizeFireDelayTime) then
        self.randomizeFireDelay = Math.getRandomFloat(-0.1, 0.1)
    end

    if self.tapFireTime > 0.1 then
        self.tapFireTime = self.tapFireTime + self.randomizeFireDelay
    end

    self.weaponMode = selectedWeaponType.weaponMode
    self.activeWeapon = selectedWeaponType.name
    self.priorityHitbox = selectedWeaponType.priorityHitbox
    self.shootWithinFov = selectedWeaponType.fov

    if not self.shootWithinFov then
        self.shootWithinFov = 4
    end

    if selectedWeaponType.runAtCloseRange then
        self.isRunAndShootAllowed = distance < selectedWeaponType.ranges.medium
    else
        self.isRunAndShootAllowed = false
    end
end

--- @return void
function AiStateEngage:render()
    if not MenuGroup.master:get() or not MenuGroup.enableAi:get() or not MenuGroup.enableAimbot:get() then
        return
    end

    for id, callback in pairs(self.visualizerCallbacks) do
        callback()

        if self.visualizerExpiryTimers[id]:isElapsedThenStop(0.1) then
            self.visualizerCallbacks[id] = nil
        end
    end

    if not MenuGroup.visualiseAimbot:get() then
        return
    end

    if not LocalPlayer:isAlive() then
        return
    end

    local screenDimensions = Client.getScreenDimensions()
    local uiPos = Vector2:new(screenDimensions.x - 50, 20)

    local kd = string.format(
        "%i / %i (%i KD)",
        LocalPlayer:m_iKills(), LocalPlayer:m_iDeaths(), LocalPlayer:getKdRatio()
    )

    local kdColor = Color:hsla(0, 0.8, 0.6):setHue(Math.getClamped(Math.getFloat(LocalPlayer:getKdRatio(), 2), 0, 1) * 100)

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

        if AiUtility.visibleEnemies[enemy.eid] and not self:isEnemySensed(enemy) then
            color = Color:hsla(60, 0.8, 0.6)
            status = "(BEHIND)"
        elseif AiUtility.visibleEnemies[enemy.eid] then
            color = Color:hsla(100, 0.8, 0.6)
            status = "(VISIBLE)"
        elseif self:isEnemySensed(enemy) then
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
    local timerColor = Color:hsla(100 * pct, 0.8, 0.6)
    local timerBgColor = Color:hsla(100 * pct, 0.4, 0.2, 100)

    color = color or Color:hsla(0, 0, 0.9)

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

--- @return void
function AiStateEngage:handleMovement()
    self.activity = "About to contact enemy"

    if not self.bestTarget then
        return
    end

    if self:movementHoldAfterPlant() then
        return
    end

    if self:movementPlantSpot() then
        return
    end

    if self:movementJiggleBait() then
        return
    end

    if self:movementDefending() then
        return
    end

    self.isBackingUp = false

    if self.seekCoverTimer:isElapsed(1.5) and Table.isEmpty(AiUtility.visibleEnemies) then
        self:movementBackUpFromThreats()
        self:movementAvoidSmokes()
    end

    if self.isBackingUp then
        if not self.hasBackupCover then
            self:actionBackUp()
        end

        return
    end

    if self:movementHoldAngle() then
        return
    end

    self:movementToTarget()
end

--- @return boolean
function AiStateEngage:movementHoldAngle()
    -- Don't peek the angle. Hold it.
    if self:isAbleToHoldAngle() then
        self.activity = "Holding enemy"

        if Pathfinder.isOnValidPath() then
            self.isHoldingAngle = Math.getChance(1)
            self.isHoldingAngleDucked = LocalPlayer:hasSniper() or Math.getChance(4)

            if self.isHoldingAngle then
                Pathfinder.clearActivePathAndLastRequest()
            end
        end

        self.patienceTimer:ifPausedThenStart()

        -- Jiggling whilst scoped might look stupid.
        if LocalPlayer:isHoldingSniper() and LocalPlayer:m_bIsScoped() == 0 then
            LocalPlayer.scope()
        end

        if self.isHoldingAngleDucked then
            Pathfinder.duck()
        else
            self:actionJiggle(self.jiggleShootTime)
        end

        return true
    end

    return false
end

--- @return boolean
function AiStateEngage:movementHoldAfterPlant()
    if AiUtility.isClientThreatenedMajor
        and not self.isVisibleToBestTarget
        and not self.blockMovementAfterPlantTimer:isElapsed(1.5)
    then
        Pathfinder.duck()
        Pathfinder.standStill()

        return true
    end

    return false
end

--- @return boolean
function AiStateEngage:movementPlantSpot()
    if AiUtility.isClientThreatenedMajor then
        return false
    end

    if not LocalPlayer.isCarryingBomb() then
        return false
    end

    if AiUtility.teammatesAlive == 0 then
        return false
    end

    local clientOrigin = LocalPlayer:getOrigin()
    local nearestBombsite = Nodegraph.getClosestBombsite(clientOrigin)

    if clientOrigin:getDistance(nearestBombsite.origin) > 1500 then
        return false
    end

    Pathfinder.moveToNode(Nodegraph.getClosest(clientOrigin, Node.spotPlant), {
        task = "Engage enemy via plant spot",
        isAllowedToTraverseInactives = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true
    })

    return true
end

--- @return boolean
function AiStateEngage:movementJiggleBait()
    local eyeOrigin = LocalPlayer.getEyeOrigin()
    local enemyEyeOrigin = self.bestTarget:getOrigin():offset(0, 0, 64)

    self.isInJiggleHold = false

    if self.jiggleHoldCount >= self.jiggleHoldThreshold then
        self.jiggleHoldCount = 0
        self.jiggleHoldThreshold = Math.getRandomInt(1, 6)
        self.jiggleHoldCooldownTimer:restart()
    end

    if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
        if LocalPlayer:isCounterTerrorist() then
            if AiUtility.timeData.roundtime_remaining <= 20 then
                return false
            end
        elseif LocalPlayer:isTerrorist() then
            if AiUtility.isHostageBeingPickedUpByEnemy or AiUtility.isHostageCarriedByEnemy then
                return false
            end
        end
    else
        if LocalPlayer:isCounterTerrorist() then
            if AiUtility.isBombBeingPlantedByEnemy then
                return false
            end

            if AiUtility.plantedBomb and AiUtility.bombDetonationTime <= 15 then
                return false
            end
        elseif LocalPlayer:isTerrorist() then
            if AiUtility.isBombBeingDefusedByEnemy then
                return false
            end

            if AiUtility.timeData.roundtime_remaining <= 20 then
                return false
            end
        end
    end

    if not self.bestTarget:isHoldingGun() then
        return false
    end

    if self.bestTarget:isHoldingSniper() and self.bestTarget:m_bIsScoped() == 0 then
        return false
    end

    if not self.jiggleHoldCooldownTimer:isElapsed(2) then
        return false
    end

    if LocalPlayer:getOrigin():getDistance(self.bestTarget:getOrigin()) < 400 then
        return false
    end

    local enemyCameraAngles = self.bestTarget:getCameraAngles()

    if enemyCameraAngles and enemyCameraAngles:getFov(enemyEyeOrigin, eyeOrigin) > 15 then
        return false
    end

    if not self.jiggleHoldTimer:isElapsed(self.jiggleHoldTime) then
        self.activity = "Baiting enemy"
        self.isInJiggleHold = true

        Pathfinder.moveAtAngle(eyeOrigin:getAngle(self.jiggleHoldDirection))

        return true
    end

    if self.isVisibleToBestTarget or self.isAboutToBeVisibleToBestTarget then
        local angleToEnemy = eyeOrigin:getAngle(enemyEyeOrigin)
        local left = eyeOrigin + angleToEnemy:getLeft() * 32
        local right = eyeOrigin + angleToEnemy:getRight() * 32
        local leftTrace = Trace.getLineToPosition(left, enemyEyeOrigin, AiUtility.traceOptionsAttacking)
        local rightTrace = Trace.getLineToPosition(right, enemyEyeOrigin, AiUtility.traceOptionsAttacking)

        if not leftTrace.isStartSolid and not rightTrace.isStartSolid then
            if not leftTrace.isIntersectingGeometry then
                self.jiggleHoldTimer:restart()

                self.jiggleHoldDirection = right
                self.jiggleHoldTime = Math.getRandomFloat(0.2, 0.6)
                self.jiggleHoldCount = self.jiggleHoldCount + 1
            end

            if not rightTrace.isIntersectingGeometry then
                self.jiggleHoldTimer:restart()

                self.jiggleHoldDirection = left
                self.jiggleHoldTime = Math.getRandomFloat(0.2, 0.6)
                self.jiggleHoldCount = self.jiggleHoldCount + 1
            end
        end
    end

    return false
end

--- @return void
function AiStateEngage:movementAvoidSmokes()
    if AiUtility.timeData.roundtime_remaining < 30 then
        return
    end

    if AiUtility.plantedBomb and AiUtility.bombDetonationTime < 25 then
        return
    end

    if AiUtility.isBombBeingDefusedByEnemy or AiUtility.isBombBeingPlantedByTeammate then
        return
    end

    if AiUtility.isHostageCarriedByTeammate or AiUtility.isHostageCarriedByEnemy then
        return
    end

    if AiUtility.totalThreats == 0 then
        return
    end

    --- @type Entity
    local nearSmoke
    local clientOrigin = LocalPlayer:getOrigin()

    for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
        if clientOrigin:getDistance(smoke:m_vecOrigin()) < 400 then
            nearSmoke = smoke

            break
        end
    end

    if nearSmoke then
        local cover = self:getCoverNode(800, self.bestTarget)

        if cover then
            self.activity = "Backing up from smoke"
            self.hasBackupCover = true
            self.lookAtBackingUpOrigin = Trace.getLineAlongCrosshair(AiUtility.traceOptionsAttacking).endPosition
            self.isBackingUp = true

            self.seekCoverTimer:restart()

            Pathfinder.moveToNode(cover, {
                task = "Back up from threats",
                isAllowedToTraverseInactives = true,
                goalReachedRadius = 64
            })
        else
            self.hasBackupCover = false
        end
    else
        nearSmoke = nil
    end
end

--- @return void
function AiStateEngage:movementBackUpFromThreats()
    self.lookAtBackingUpOrigin = nil

    if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
        if AiUtility.totalThreats < 2 then
            return
        elseif self.isStrafePeeking then
            return
        elseif LocalPlayer:isCounterTerrorist() then
            return
        elseif AiUtility.isHostageCarriedByTeammate or AiUtility.isHostageCarriedByEnemy or AiUtility.isHostageBeingPickedUpByEnemy then
            return
        end
    else
        if AiUtility.totalThreats < 2 then
            return
        elseif self.isStrafePeeking then
            return
        elseif LocalPlayer:isCounterTerrorist() then
            if AiUtility.plantedBomb or AiUtility.isBombBeingPlantedByEnemy then
                return
            end

            local bombsiteA = Nodegraph.getBombsite("A")
            local bombsiteB = Nodegraph.getBombsite("B")

            for _, enemy in pairs(AiUtility.enemies) do
                local enemyOrigin = enemy:getOrigin()

                if enemyOrigin:getDistance(bombsiteA.origin) < 800 or enemyOrigin:getDistance(bombsiteB.origin) < 800 then
                    return
                end
            end
        elseif LocalPlayer:isTerrorist() then
            if AiUtility.timeData.roundtime_remaining < 40  then
                return
            elseif not AiUtility.plantedBomb or AiUtility.isBombBeingDefusedByEnemy then
                return
            end
        end
    end

    local cover = self:getCoverNode(500, self.bestTarget)

    if cover then
        self.activity = "Backing up from enemies"
        self.hasBackupCover = true
        self.lookAtBackingUpOrigin = Trace.getLineAlongCrosshair(AiUtility.traceOptionsAttacking).endPosition
        self.isBackingUp = true

        self.seekCoverTimer:restart()

        Pathfinder.moveToNode(cover, {
            task = "Back up from threats",
            isAllowedToTraverseInactives = true,
            goalReachedRadius = 64
        })
    else
        self.hasBackupCover = false
    end
end

--- @return boolean
function AiStateEngage:movementDefending()
    local clientOrigin = LocalPlayer:getOrigin()
    local isAbleToDefend = true
    --- @type NodeTypeDefend
    local defendNode

    if self.isVisibleToBestTarget or self.isAboutToBeVisibleToBestTarget then
        isAbleToDefend = false
    end

    if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
        if LocalPlayer:isTerrorist() then
            defendNode = Node.defendHostageT

            if AiUtility.isHostageCarriedByEnemy or AiUtility.isHostageBeingPickedUpByEnemy then
                isAbleToDefend = false
            end
        else
            isAbleToDefend = false
        end
    else
        local bombsite = Nodegraph.getBombsite(self.ai.states.defend.bombsite)

        defendNode = Node.defendSiteT

        if clientOrigin:getDistance(bombsite.origin) > 1750 then
            isAbleToDefend = false
        elseif LocalPlayer:isTerrorist() then
            if not AiUtility.plantedBomb or AiUtility.isBombBeingDefusedByEnemy or AiUtility.bombDetonationTime <= 15 then
                isAbleToDefend = false
            end
        else
            defendNode = Node.defendSiteCt

            if AiUtility.isBombBeingPlantedByEnemy then
                isAbleToDefend = false
            elseif AiUtility.plantedBomb then
                isAbleToDefend = false
            elseif AiUtility.bombCarrier then
                local bombOrigin = AiUtility.bombCarrier:getOrigin()

                if bombOrigin:getDistance(Nodegraph.getClosestBombsite(bombOrigin).origin) < 650 then
                    isAbleToDefend = false
                end
            end
        end
    end

    if isAbleToDefend and not self.isDefending then
        local nodes = {}

        if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
            nodes = Nodegraph.getWithin(clientOrigin, 1750, defendNode)
        else
            nodes = Nodegraph.getForBombsite(defendNode, self.ai.states.defend.bombsite)
        end

        local targetEyeOrigin = self.bestTarget:getEyeOrigin()
        local selectedNodes = {}

        for _, node in pairs(nodes) do
            local fov = node.direction:getFov(node.lookFromOrigin, targetEyeOrigin)

            if fov < 85 then
                table.insert(selectedNodes, node)
            end
        end

        local node = Table.getRandom(selectedNodes)

        if node then
            self.isDefending = true
            self.defendingAtNode = node
            self.isUpdatingDefendingLookAt = true

            Pathfinder.moveToNode(node, {
                task = "Engage enemy via defensive position",
                isAllowedToTraverseInactives = true,
                isPathfindingToNearestNodeIfNoConnections = true,
                isPathfindingToNearestNodeOnFailure = true
            })
        end
    end

    if not isAbleToDefend then
        self.isDefending = false
        self.ai.states.defend.isSpecificNodeSet = false
        self.defendingAtNode = nil
    end

    if self.isDefending then
        self.activity = string.format("Holding enemy on %s", self.ai.states.defend.bombsite)

        return true
    end

    return false
end

--- @return boolean
function AiStateEngage:movementToTarget()
    self.activity = "Moving on enemy"

    local targetOrigin = self.bestTarget:getOrigin()
    local isEnemyDisplaced = false

    if self.isRefreshingAttackPath then
        self.isRefreshingAttackPath = false

        isEnemyDisplaced = true
    end

    if self.lastBestTargetOrigin and self.bestTarget:getFlag(Player.flags.FL_ONGROUND) and targetOrigin:getDistance(self.lastBestTargetOrigin) > 200 then
        isEnemyDisplaced = true
    end

    if not Pathfinder.isOnValidPath() or isEnemyDisplaced then
        local targetEyeOrigin = targetOrigin:clone():offset(0, 0, 64)

        --- @type NodeTypeTraverse[]
        local selectedNodes = {}
        --- @type NodeTypeTraverse
        local closestNode
        local closestNodeDistance = math.huge
        local i = 0

        -- Find a nearby node that is visible to the enemy.
        for _, node in pairs(Nodegraph.get(Node.traverseGeneric)) do
            local distance = targetOrigin:getDistance(node.origin)

            -- Determine closest node. This is our backup in case there's no visible nodes.
            if distance < closestNodeDistance then
                closestNodeDistance = distance
                closestNode = node
            end

            -- Find a visible node nearby.
            if distance < 1000 then
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

        self.lastBestTargetOrigin = targetOrigin

        local isPushingToEnemyPosition = false

        if AiUtility.isHostageCarriedByEnemy or AiUtility.isHostageBeingPickedUpByEnemy then
            isPushingToEnemyPosition = true
        end

        if AiUtility.isBombBeingPlantedByEnemy or AiUtility.plantedBomb then
            isPushingToEnemyPosition = true
        end

        if LocalPlayer:isTerrorist() and AiUtility.gamemode ~= AiUtility.gamemodes.HOSTAGE and AiUtility.timeData.roundtime_remaining < 25 and not AiUtility.plantedBomb then
            isPushingToEnemyPosition = true
        end

        -- We can pathfind to a node visible to the enemy.
        if isPushingToEnemyPosition then
            self:moveToLocation(self.lastBestTargetValidOrigin)
        else
            self:moveToRandomNodeFrom(selectedNodes, closestNode)
        end
    end
end

--- @param nodes NodeTypeTraverse[]
--- @param closest NodeTypeTraverse
--- @return void
function AiStateEngage:moveToRandomNodeFrom(nodes, closest)
    if Table.isEmpty(nodes) then
        self:moveToClosestNode(closest)

        return
    end

    local node, idx = Table.getRandom(nodes)

    table.remove(nodes, idx)

    Pathfinder.moveToNode(node, {
        task = "Engage enemy via random position",
        isAllowedToTraverseInactives = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        onFailedToFindPath = function()
            self:moveToRandomNodeFrom(nodes)
        end
    })
end

--- @param node NodeTypeTraverse
--- @return void
function AiStateEngage:moveToClosestNode(node)
    Pathfinder.moveToNode(node, {
        task = "Engage enemy via nearest position",
        isAllowedToTraverseInactives = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true
    })
end

--- @param origin Vector3
--- @return void
function AiStateEngage:moveToLocation(origin)
    if not origin then
        return
    end

    Pathfinder.moveToLocation(origin, {
        task = "Engage enemy at their exact location",
        isAllowedToTraverseInactives = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true
    })
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:handleAttacking(cmd)
    self:attackingBlockRoutines()
    self:attackingEquipWeapon()
    self:attackingDefending()
    self:attackingLookAtBackupOrigin()
    self:attackingSprayWeapon(cmd)

    -- Reset reaction delay.
    if not self.bestTarget or not self:isEnemySensed(self.bestTarget) then
        self.reactionTimer:stop()
    end

    -- Ignore unnoticed enemies.
    -- I'm like 100% sure that this is completely redundant. How does this attack function even get run
    -- if there's no enemies the AI knows about to attack?
    -- I'm not removing it because every time I change something in this 4000 line file the AI starts doing something insane.
    if not self:isAnyEnemiesSensed() then
        return
    end

    -- Block overpowered spray transfers.
    if not self.blockTimer:isElapsed(self.blockTime) then
        self.ai.routines.manageWeaponReload:block()

        return
    end

    if self:attackingSwitchToPistol(cmd) then
        return
    end

    -- Watch last known position.
    if not self.bestTarget then
        self:actionWatchAngle()

        return
    end

    -- Not entirely sure why this is called again.
    if Table.isEmpty(AiUtility.visibleEnemies) then
        self:actionWatchAngle()
    end

    self:actionStrafePeek()
    self:attackingSetReactionTime()
    self:attackingSetAimOffset()

    if self:attackingFlashed(cmd) then
        return
    end

    if self:attackingWallAndSmokeBang(cmd) then
        return
    end

    -- Pre-aim angle/hitbox when peeking.
    if self:isEnemySensed(self.bestTarget) and self.reactionTimer:isElapsed(self.reactionTime) then
        self:preAimAboutCorners()
        self:preAimThroughCorners()
    end

    self:attackingBestTarget(cmd)
end

--- @return void
function AiStateEngage:attackingDefending()
    if not self.isDefending then
        return
    end

    local clientOrigin = LocalPlayer:getOrigin()
    --- @type Vector3
    local targetOrigin
    local distance = clientOrigin:getDistance(self.defendingAtNode.origin)

    -- If we can pre-aim, we should do that.
    if self.preAimAboutCornersAimOrigin then
        self.isUpdatingDefendingLookAt = true

        targetOrigin = self.preAimAboutCornersAimOrigin
    elseif self.bestTarget then
        -- We need to update the look at because we're too close to it.
        if self.defendingLookAt and clientOrigin:getDistance(self.defendingLookAt) < 450 then
            self.isUpdatingDefendingLookAt = true
        end

        -- We can look along the defend node's angles.
        if distance < 250 then
            self.defendingLookAt = self.defendingAtNode.lookAtOrigin
        else
            targetOrigin = self.bestTarget:getOrigin():offset(0, 0, 64):offsetByVector(self.defendLookAtOffset)

            local eyeOrigin = LocalPlayer.getEyeOrigin()

            targetOrigin.z = Math.getClamped(targetOrigin.z, eyeOrigin.z - 48, eyeOrigin.z + 48)
        end
    end

    -- We're allowed to update the defend angle.
    if self.isUpdatingDefendingLookAt and targetOrigin and not targetOrigin:isZero() then
        self.isUpdatingDefendingLookAt = false
        self.defendingLookAt = targetOrigin
    end

    -- Look at the defend angle.
    if self.defendingLookAt then
        VirtualMouse.lookAtLocation(self.defendingLookAt, 6, VirtualMouse.noise.moving, "Engage defend against enemy")

        self:addVisualizer("defending", function()
            if not self.defendingLookAt then
                return
            end

            self.defendingLookAt:drawCircleOutline(24, 2, Color:hsla(250, 1, 0.75, 200))
        end)
    end

    -- Random actions. Don't perform them when actually in a fight or they override shoot actions.
    if not self.isVisibleToBestTarget and not self.isAboutToBeVisibleToBestTarget and distance < 100 and not Pathfinder.isOnValidPath() then
        if self.defendActionTimer:isElapsedThenRestart(self.defendActionTime) then
            self.defendActionTime = Math.getRandomFloat(1, 6)
            self.isJigglingOnDefend = Math.getChance(2)
            self.isCrouchingOnDefend = Math.getChance(3)
        end

        if LocalPlayer:isHoldingSniper() and LocalPlayer:m_bIsScoped() == 0 then
            LocalPlayer.scope()
        end

        if self.isJigglingOnDefend then
            self:actionJiggle(0.25, self.defendingAtNode.direction)
        end

        if self.isCrouchingOnDefend and self.defendingAtNode.isAllowedToDuckAt then
            Pathfinder.duck()
        end
    end
end

--- @return void
function AiStateEngage:attackingBlockRoutines()
    -- Prevent certain generic behaviours.
    self.ai.routines.manageGear:block()

    -- Prevent reloading/unscoping when enemies are visible.
    if next(AiUtility.visibleEnemies) then
        self.ai.routines.manageWeaponReload:block()
        self.ai.routines.manageWeaponScope:block()
    end

    -- Prevent reloading.
    if self.watchTimer:isStarted() and not self.watchTimer:isElapsed(self.watchTime) then
        self.ai.routines.manageWeaponReload:block()
    end

    VirtualMouse.blockBuildup()
end

--- @return void
function AiStateEngage:attackingLookAtBackupOrigin()
    -- Look at occluded origin.
    if self.lookAtBackingUpOrigin and not AiUtility.clientThreatenedFromOrigin then
        VirtualMouse.lookAtLocation(self.lookAtBackingUpOrigin, 4, VirtualMouse.noise.moving, "Engage look-at backing up position")
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:attackingSprayWeapon(cmd)
    -- Spray.
    if self.sprayTimer:isStarted() and not self.sprayTimer:isElapsed(self.sprayTime) then
        self.ai.routines.manageWeaponReload:block()

        if self.bestTarget and not AiUtility.visibleEnemies[self.bestTarget.eid] then
            self:shoot(cmd, self.watchOrigin, self.bestTarget)
        elseif not self.bestTarget then
            self:shoot(cmd, self.watchOrigin)
        end
    end
end

--- @return void
function AiStateEngage:attackingEquipWeapon()
    -- Ensure player is holding weapon.
    if not LocalPlayer:isHoldingGun() then
        if LocalPlayer:hasPrimary() then
            LocalPlayer.equipPrimary()
        else
            LocalPlayer.equipPistol()
        end
    end
end

--- @param cmd SetupCommandEvent
--- @return boolean
function AiStateEngage:attackingSwitchToPistol(cmd)
    local weapon = Entity:create(LocalPlayer:m_hActiveWeapon())
    local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
    local ammo = weapon:m_iClip1()
    local maxAmmo = csgoWeapon.primary_clip_size
    local ammoRatio = ammo / maxAmmo
    local isAllowedToEquipPistol = false

    if not LocalPlayer:isReloading() then
        isAllowedToEquipPistol = true
    elseif LocalPlayer:isReloading() and LocalPlayer:getReloadProgress() > 0.3 then
        isAllowedToEquipPistol = true
    end

    if LocalPlayer:isHoldingPrimary() then
        if ammoRatio == 0 and AiUtility.isClientThreatenedMajor and isAllowedToEquipPistol then
            LocalPlayer.equipPistol()
        end
    else
        if ammoRatio == 0 and AiUtility.isClientThreatenedMajor then
            cmd.in_reload = true

            return true
        end

        if not AiUtility.isClientThreatenedMinor then
            LocalPlayer.equipPrimary()
        end
    end

    return false
end

--- @return void
function AiStateEngage:attackingSetReactionTime()
    local lastSeenEnemyTimer = self.lastSeenTimers[self.bestTarget.eid]
    local currentReactionTime = self.reactionTime

    if self.noticedLoudPlayerTimers[self.bestTarget.eid]:isNotElapsed(8) then
        currentReactionTime = self.prefireReactionTime
    end

    if lastSeenEnemyTimer:isNotElapsed(6) then
        currentReactionTime = self.anticipateTime
    end

    self.currentReactionTime = currentReactionTime

    -- Begin reaction timer.
    if self:isEnemySensed(self.bestTarget) then
        self.reactionTimer:ifPausedThenStart()
    end

    if AiUtility.visibleEnemies[self.bestTarget.eid] then
        self.visibleReactionTimer:ifPausedThenStart()
    else
        self.visibleReactionTimer:stop()
    end
end

--- @return void
function AiStateEngage:attackingSetAimOffset()
    local eyeOrigin = LocalPlayer.getEyeOrigin()
    local enemyOrigin = self.bestTarget:getOrigin()
    local offsetModifier = Math.getClampedFloat(eyeOrigin:getDistance(enemyOrigin), 1000, 0, 700)
    local horizontal = self.aimInaccurateOffset
    local vertical = self.aimInaccurateOffset / 3

    self.shootAtOrigin = self.bestTarget:getOrigin():offset(0, 0, 48) + Vector3:new(
        Animate.sine(0, horizontal * offsetModifier, 3),
        Animate.sine(0, horizontal * offsetModifier, 2),
        Animate.sine(0, vertical * offsetModifier, 2.5)
    )
end

--- @param cmd SetupCommandEvent
--- @return boolean
function AiStateEngage:attackingWallAndSmokeBang(cmd)
    local weapon = Entity:create(LocalPlayer:m_hActiveWeapon())
    local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
    local ammo = weapon:m_iClip1()
    local maxAmmo = csgoWeapon.primary_clip_size
    local ammoRatio = ammo / maxAmmo
    local eyeOrigin = LocalPlayer.getEyeOrigin()

    -- Wallbang and smokebang.
    if not AiUtility.visibleEnemies[self.bestTarget.eid] then
        local lastNoticedAgo = self.noticedLoudPlayerTimers[self.bestTarget.eid]:get()

        if AiUtility.isBombBeingDefusedByEnemy or (lastNoticedAgo > 0 and lastNoticedAgo < 1.25) then
            local bangOrigin = self.bestTarget:getOrigin():offset(0, 0, 46)
            local _, traceDamage = eyeOrigin:getTraceBullet(bangOrigin, LocalPlayer.eid)
            local isBangable = true

            if AiUtility.isInsideSmoke then
                isBangable = false
            end

            if LocalPlayer:hasSniper() then
                if ammoRatio < 1 then
                    -- Banging with AWP is often not a great idea.
                    -- So we're only going to allow it if the AI has a full mag.
                    isBangable = false
                elseif traceDamage < 40 then
                    -- We should only wallbang on high damage bangs.
                    isBangable = false
                end
            else
                if ammo < 0.25 then
                    -- Low ammo.
                    isBangable = false
                elseif ammoRatio < 0.4 and traceDamage < 25 then
                    -- Mid-ammo so spare our shots more.
                    isBangable = false
                elseif traceDamage < 15 then
                    -- At least try to damage the enemy.
                    isBangable = false
                end
            end

            local isShooting = false
            local isOccludedBySmoke = eyeOrigin:isRayIntersectingSmoke(bangOrigin)
            local trace = Trace.getLineToPosition(eyeOrigin, bangOrigin, AiUtility.traceOptionsAttacking, "AiStateEngage.attackBestTarget<FindBangable>")
            local isOccludedByWall = trace.isIntersectingGeometry

            if isOccludedByWall then
                -- Wallbang, but only if there isn't a smoke in the way.
                if self.canWallbang and not isOccludedBySmoke and isBangable then
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

                return true
            end
        end
    end

    return false
end

--- @param cmd SetupCommandEvent
--- @return boolean
function AiStateEngage:attackingFlashed(cmd)
    -- Shoot while blind.
    if LocalPlayer.isFlashed() and AiUtility.visibleEnemies[self.bestTarget.eid] then
        self:shoot(cmd, self.shootAtOrigin, self.bestTarget)

        return true
    end

    return false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:attackingBestTarget(cmd)
    local eyeOrigin = LocalPlayer.getEyeOrigin()
    local enemyOrigin = self.bestTarget:getOrigin()
    local shootFov = self:getShootFov(LocalPlayer.getCameraAngles(), eyeOrigin, enemyOrigin)

    -- Get target hitbox.
    local hitbox, visibleHitboxCount = self:getTargetHitbox(self.bestTarget)

    if not hitbox then
        return
    end

    self.isTargetEasilyShot = visibleHitboxCount >= 8

    -- Begin watching last angle.
    if AiUtility.visibleEnemies[self.bestTarget.eid] then
        if hitbox then
            self.watchOrigin = enemyOrigin:offset(0, 0, 60)
        end

        self.enemyVisibleTimer:ifPausedThenStart()
    else
        self.enemyVisibleTimer:stop()
    end

    -- Make sure the default mouse movement isn't active while the enemy is visible but the reaction timer hasn't elapsed.
    if AiUtility.visibleEnemies[self.bestTarget.eid] and shootFov < 60 then
        VirtualMouse.lookAtLocation(hitbox, 2, VirtualMouse.noise.moving, "Engage prepare to react")

        self:addVisualizer("hold", function()
            hitbox:drawCircleOutline(12, 2, Color:hsla(50, 1, 0.5, 200))
        end)
    end

    -- React to visible enemy.
    if not self.isInJiggleHold and self:isEnemySensed(self.bestTarget) and self.visibleReactionTimer:isElapsed(self.currentReactionTime) and AiUtility.visibleEnemies[self.bestTarget.eid] then
        self.sprayTimer:start()
        self.watchTimer:start()
        self.lastSeenTimers[self.bestTarget.eid]:start()

        self:noticeEnemy(self.bestTarget, 4096, false, "In shoot FoV")
        self:shoot(cmd, hitbox, self.bestTarget)
    end
end

--- @return void
function AiStateEngage:setIsVisibleToBestTarget()
    if not self.bestTarget then
        return
    end

    self.isVisibleToBestTarget = false
    self.isAboutToBeVisibleToBestTarget = false

    local enemyEyeOrigin = self.bestTarget:getEyeOrigin()
    local hitboxes = LocalPlayer:getOrigin():offset(0, 0, 48):getBox(Vector3.align.CENTER, 16, 16, 16)

    for _, hitbox in pairs(hitboxes) do
        local trace = Trace.getLineToPosition(enemyEyeOrigin, hitbox, AiUtility.traceOptionsAttacking, "AiStateBase.setIsVisibleToBestTarget<FindClientVisibleToEnemy>")

        if not trace.isIntersectingGeometry then
            self.isVisibleToBestTarget = true
            self.isAboutToBeVisibleToBestTarget = true

            break
        end
    end

    local velocity = LocalPlayer:m_vecVelocity() * 0.11

    for id, hitbox in pairs(hitboxes) do
        hitboxes[id] = hitbox + velocity
    end

    for _, hitbox in pairs(hitboxes) do
        local trace = Trace.getLineToPosition(enemyEyeOrigin, hitbox, AiUtility.traceOptionsAttacking, "AiStateBase.setIsVisibleToBestTarget<FindClientVisibleToEnemy>")

        if not trace.isIntersectingGeometry then
            self.isAboutToBeVisibleToBestTarget = true

            break
        end
    end
end

--- @return boolean
function AiStateEngage:isAbleToHoldAngle()
    -- Activates if the enemy is near a corner, but not too close to it.
    if not self.isPreAimViableForHoldingAngle then
        return false
    end

    -- The enemy can see us. It's possible we'd hold an angle where our pelvis or feet are visible, but we cannot see the enemy.
    if self.isVisibleToBestTarget then
        return false
    end

    -- The enemy is visible.
    if AiUtility.visibleEnemies[self.bestTarget.eid] then
        return false
    end

    -- Check we're not going to hold an angle in a really dumb spot.
    local clientEyeOrigin = LocalPlayer.getEyeOrigin()
    local traceOptions = Table.getMerged(AiUtility.traceOptionsAttacking, {
        distance = 200
    })

    local losTrace = Trace.getHullAtAngle(clientEyeOrigin, LocalPlayer.getCameraAngles(), Vector3:newBounds(Vector3.align.CENTER, 8), traceOptions, "AiStateEngage.canHoldAngle<FindLos>")

    -- Line of sight is facing too close to a wall.
    if losTrace.isIntersectingGeometry then
        return false
    end

    if self.bestTarget and (not AiUtility.isBombBeingDefusedByEnemy and not AiUtility.isHostageCarriedByEnemy and not AiUtility.isHostageCarriedByTeammate) then
        local trace = Trace.getLineToPosition(clientEyeOrigin, self.bestTarget:getEyeOrigin(), AiUtility.traceOptionsAttacking)

        -- The enemy, from our point of view, is occluded by a smoke.
        -- We shouldn't really push smokes, so we should prefer holding the smoke instead.
        if clientEyeOrigin:isRayIntersectingSmoke(trace.endPosition) then
            return true
        end
    end

    local clientOrigin = LocalPlayer:getOrigin()
    local bounds = Vector3:newBounds(Vector3.align.BOTTOM, 32)
    local hullTrace = Trace.getHullAtPosition(clientOrigin:clone():offset(0, 0, 16), bounds, AiUtility.traceOptionsAttacking, "AiStateEngage.canHoldAngle<FindHull>")

    -- Our proximity to a wall is too close.
    if hullTrace.isIntersectingGeometry then
        return false
    end

    -- Don't hold if the enemy is planting or has planted the bomb.
    if LocalPlayer:isCounterTerrorist() and AiUtility.gamemode ~= AiUtility.gamemodes.HOSTAGE and not AiUtility.plantedBomb and not AiUtility.isBombBeingPlantedByEnemy then
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

    if LocalPlayer:isTerrorist() then
        if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
            -- Ts should prefer defense in hostage.
            if not AiUtility.isHostageCarriedByEnemy and not AiUtility.isHostageBeingPickedUpByEnemy then
                return true
            end
        else
            local distanceToSite = Nodegraph.getClosestBombsite(clientOrigin).origin:getDistance(clientOrigin)

            if AiUtility.plantedBomb then
                local isNearPlantedBomb = LocalPlayer:getOrigin():getDistance(AiUtility.plantedBomb:m_vecOrigin()) < 1000

                -- Good enough situation to hold as a T.
                -- We don't do it outside of sites because we should really be pushing the enemy at this stage.
                if isNearPlantedBomb then
                    return true
                end
            else
                -- Push the site before CTs can rotate.
                if distanceToSite < 1250 then
                    return false
                end

                -- We don't have much time remaining in the round, so we ought not to stand around.
                if AiUtility.timeData.roundtime_remaining < 35 then
                    return false
                end

                -- Don't hold the angle forever.
                if self.patienceTimer:isElapsedThenRestart(5) then
                    return false
                end
            end
        end
    end

    -- It's best to just push the enemy.
    return false
end

--- @return void
function AiStateEngage:handleShiftWalking()
    self.isSneaking = false

    if self.bestTarget and AiUtility.closestEnemy then
        local clientEyeOrigin = LocalPlayer.getEyeOrigin()
        local predictedEyeOrigin = clientEyeOrigin + LocalPlayer:m_vecVelocity() * 0.8
        local enemyOrigin = AiUtility.closestEnemy:getOrigin()
        local distance = clientEyeOrigin:getDistance(enemyOrigin)
        local trace = Trace.getLineToPosition(predictedEyeOrigin, self.bestTarget:getOrigin():offset(0, 0, 48), AiUtility.traceOptionsAttacking, "AiStateEngage.walk<FindPredicted>")
        local shootFov = self:getShootFov(self.bestTarget:getCameraAngles(), self.bestTarget:getEyeOrigin(), clientEyeOrigin)

        if distance < 1200 then
            return
        end

        if LocalPlayer:isCounterTerrorist() and AiUtility.plantedBomb then
            if AiUtility.bombDetonationTime < 20 then
                return
            elseif distance > 350 then
                return
            end
        end

        if not trace.isIntersectingGeometry and shootFov < 20 then
            return
        end
    end

    if self.walkCheckTimer:isElapsedThenRestart(0.075) then
        self.walkCheckCount = Math.getClamped(self.walkCheckCount - 1, 0, 20)
    end

    if self.walkCheckCount >= 15 then
        return
    end

    if AiUtility.isBombBeingDefusedByEnemy or AiUtility.isBombBeingPlantedByEnemy then
        return
    end

    if AiUtility.isHostageCarriedByEnemy or AiUtility.isHostageBeingPickedUpByEnemy then
        return
    end

    if LocalPlayer:m_bIsScoped() == 1 then
        return
    end

    if not self.jiggleHoldTimer:isElapsed(self.jiggleHoldTime + 1) then
        return
    end

    if LocalPlayer:isTerrorist() and not AiUtility.plantedBomb and AiUtility.timeData.roundtime_remaining < 12 then
        return
    end

    self.isSneaking = true

    Pathfinder.walk()
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

--- @param angle Angle
--- @param vectorA Vector3
--- @param vectorB Vector3
--- @return number
function AiStateEngage:getDangerFov(angle, vectorA, vectorB)
    local distance = vectorA:getDistance(vectorB)
    local fov = angle:getFov(vectorA, vectorB)

    return Math.getClamped(Math.getFloat(distance, 500), 0, 90) * fov
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
    if not LocalPlayer:getFlag(Player.flags.FL_ONGROUND) then
        return
    end

    -- Prevent jumping obstacles. This can kill us.
    self.ai.routines.lookAwayFromFlashbangs:block()

    -- Prevent the occluder traversal routine overriding our movement.
    self.ai.routines.handleOccluderTraversal:block()

    local distance = LocalPlayer:getOrigin():getDistance(aimAtBaseOrigin)

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

    local clientEyeOrigin = LocalPlayer.getEyeOrigin()

    -- We have an actual target to shoot, and not just some point in space.
    if enemy then
        local trace = Trace.getLineToPosition(clientEyeOrigin, aimAtBaseOrigin, AiUtility.traceOptionsAttacking, "AiStateEngage.shoot<FindShootAtBehindWall>")

        -- Enemy is behind a wall. We have other code responsible for wallbanging.
        if self.sprayTimer:isElapsed(self.sprayTime) and trace.isIntersectingGeometry then
            return
        end
    end

    -- Don't shoot teammates.
    if self:isTeammateInCrosshair(aimAtOrigin) then
        return
    end

    local fov = self:getShootFov(LocalPlayer.getCameraAngles(), LocalPlayer.getEyeOrigin(), aimAtOrigin)

    -- Set RCS parameters.
    -- RCS should be off for snipers and shotguns, and on for rifles, SMGs, and pistols.
    VirtualMouse.isRcsEnabled = self.isRcsEnabled

    -- Set mouse movement parameters.
    VirtualMouse.isCrosshairSmoothed = false
    VirtualMouse.isCrosshairUsingVelocity = true

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

    local weapon = Entity:create(LocalPlayer:m_hActiveWeapon())
    local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]

    method(self, cmd, aimAtOrigin, fov, csgoWeapon)
end

--- @return boolean
function AiStateEngage:isTeammateInCrosshair(aimAtOrigin)
    local clientWeapon = LocalPlayer:getWeapon()
    local weaponSpread = clientWeapon:getSpread()
    local weaponInaccuracy = clientWeapon:getInaccuracy()
    local weaponCombinedSpread = math.max(math.deg(weaponInaccuracy + weaponSpread), 1.5)
    local cameraAngles = LocalPlayer.getCameraAngles() + (LocalPlayer:m_aimPunchAngle() * 2)
    local eyeOrigin = LocalPlayer.getEyeOrigin()
    local clientOrigin = LocalPlayer:getOrigin()
    local isTeammateInDanger = false
    local aimAtDistance = clientOrigin:getDistance(aimAtOrigin)

    for _, teammate in Player.find(function(p)
        return p:isTeammate() and p:isAlive() and not p:isLocalPlayer()
    end) do repeat
        local teammateDistance = clientOrigin:getDistance(teammate:getOrigin())

        -- We may somewhat safely ignore teammates who are behind the target.
        if teammateDistance > aimAtDistance then
            break
        end

        local trace = Trace.getLineToPosition(eyeOrigin, teammate:getEyeOrigin(), AiUtility.traceOptionsAttacking)

        -- The teammate is behind a wall.
        if trace.isIntersectingGeometry then
            break
        end

        local velocity = teammate:m_vecVelocity() * 0.075
        local a = teammate:getHitboxPositions()
        local b = teammate:getHitboxPositions()

        for _, hitbox in pairs(b) do
            table.insert(a, hitbox + velocity)
        end

        for _, hitbox in pairs(a) do
            local fovToHitbox = cameraAngles:getFov(eyeOrigin, hitbox)
            local correctedFovToHitbox = self:getDangerFov(cameraAngles, eyeOrigin, hitbox)
            local realFov = math.min(fovToHitbox, correctedFovToHitbox)

            if realFov <= weaponCombinedSpread then
                isTeammateInDanger = true
            end
        end
    until true end

    return isTeammateInDanger
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:fireWeapon(cmd)
    if not self.isAimEnabled or not MenuGroup.enableAimbot:get() then
        return
    end

    VirtualMouse.fireWeapon()
end

--- @param cmd SetupCommandEvent
--- @param aimAtOrigin Vector3
--- @param fov number
--- @param weapon CsgoWeapon
--- @return void
function AiStateEngage:shootPistol(cmd, aimAtOrigin, fov, weapon)
    local distance = LocalPlayer.getEyeOrigin():getDistance(aimAtOrigin)
    local isVelocityOk = true

    if distance > 600 then
        cmd.in_duck = true
    elseif not self.isRunAndShootAllowed then
        self:actionJiggle(self.jiggleShootTime * 0.33)

        isVelocityOk = LocalPlayer:m_vecVelocity():getMagnitude() < 100
    elseif AiUtility.totalThreats > 1 then
        self:actionBackUp()
    end

    local aimSpeed = self.aimSpeed

    if distance < 600 then
        aimSpeed = self.aimSpeed * 1.5
    end

   VirtualMouse.lookAtLocation(aimAtOrigin, aimSpeed, self.aimNoise, "Engage look-at target")

    if fov < self.shootWithinFov
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
    local distance = LocalPlayer.getEyeOrigin():getDistance(aimAtOrigin)
    local aimSpeed = self.aimSpeed

    if distance < 500 then
        aimSpeed = self.aimSpeed * 1.5
    end

   VirtualMouse.lookAtLocation(aimAtOrigin, aimSpeed, self.aimNoise, "Engage look-at target")

    if not self.isRunAndShootAllowed then
        self:actionCounterStrafe(cmd)
    elseif AiUtility.totalThreats > 1 then
        self:actionBackUp()
    end

    if fov < self.shootWithinFov
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
    local distance = LocalPlayer.getEyeOrigin():getDistance(aimAtOrigin)
    local aimSpeed = self.aimSpeed

    if distance < 500 then
        aimSpeed = self.aimSpeed * 1.5
    end

   VirtualMouse.lookAtLocation(aimAtOrigin, aimSpeed, self.aimNoise, "Engage look-at target")

    if distance > 1000 then
        return
    end

    if AiUtility.totalThreats > 1 then
        self:actionBackUp()
    end

    if fov < self.shootWithinFov
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
   VirtualMouse.lookAtLocation(aimAtOrigin, self.aimSpeed, self.aimNoise, "Engage look-at target")

    if self.isTargetEasilyShot then
        self:actionCounterStrafe(cmd)
    else
        if not self:isAllowedToStrafe() then
            self:actionStop(cmd)
        end
    end

    local isVelocityOk = LocalPlayer:m_vecVelocity():getMagnitude() < 120

    if fov < self.shootWithinFov
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
    local distance = LocalPlayer.getEyeOrigin():getDistance(aimAtOrigin)
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

    local isNoscoping = false

    if self.isAllowedToNoscope and self.isTargetEasilyShot and distance < 350 then
        isNoscoping = true
    end

    -- Create a "flick" effect when aiming.
    if isNoscoping or self.scopedTimer:isElapsed(fireDelay * 0.4) then
        VirtualMouse.lookAtLocation(aimAtOrigin, self.aimSpeed * 3, self.aimNoise, "Engage look-at target")
    else
        VirtualMouse.lookAtLocation(aimAtOrigin, self.aimSpeed, self.aimNoise, "Engage look-at target")
    end

    if not isNoscoping and fov < self.shootWithinFov * 2.5 then
        LocalPlayer.scope()
    end

    -- Always come to a complete stop when using snipers.
    self:actionStop(cmd)

    -- We can shoot when we're this slow.
    local fireUnderVelocity = weapon.max_player_speed / 4

    if fov < self.shootWithinFov
        and (isNoscoping or (self.scopedTimer:isElapsed(fireDelay) and LocalPlayer:m_bIsScoped() == 1))
        and LocalPlayer:m_vecVelocity():getMagnitude() < fireUnderVelocity
    then
        self:fireWeapon(cmd)
    end
end

--- @return boolean
function AiStateEngage:isAllowedToStrafe()
    return (self.tapFireTime - 0.15) - self.tapFireTimer:get() > 0
end

--- @param enemy Player
--- @return Vector3, number
function AiStateEngage:getTargetHitbox(enemy)
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

    local eyeOrigin = LocalPlayer.getEyeOrigin()
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
    local angleToEnemy = LocalPlayer:getOrigin():getAngle(self.bestTarget:getOrigin())

    Pathfinder.moveAtAngle(-angleToEnemy)
end

--- @param angle Angle
--- @param period number
--- @return void
function AiStateEngage:actionJiggle(period, angle)
    -- Alternate movement directions.
    if self.jiggleShootTimer:isElapsedThenRestart(period) then
        self.jiggleShootDirection = self.jiggleShootDirection == "Left" and "Right" or "Left"
    end

    --- @type Vector3
    local direction

    if not angle then
        angle = LocalPlayer.getCameraAngles()
    end

    if self.jiggleShootDirection == "Left" then
        direction = angle:getLeft()
    else
        direction = angle:getRight()
    end

    Pathfinder.moveAtAngle(direction:getAngleFromForward())
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:actionCounterStrafe(cmd)
    if self.isTargetEasilyShot then
        -- Duck for better accuracy.
        cmd.in_duck = true
    end

    if LocalPlayer:m_flDuckSpeed() < 4 then
        if not self:isAllowedToStrafe() then
            Pathfinder.standStill()
        end

        return
    end

    if self.strafePeekDirection and self.bestTarget then
        local angleToEnemy = LocalPlayer:getOrigin():getAngle(self.bestTarget:getOrigin())

        --- @type Vector3
        local moveAngle = Nyx.call(angleToEnemy, "get%s", self.strafePeekDirection)

        Pathfinder.moveAtAngle(moveAngle:getAngleFromForward())
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEngage:actionStop(cmd)
    if self.isTargetEasilyShot then
        -- Duck for better accuracy.
        cmd.in_duck = true
    end

    local velocity = LocalPlayer:m_vecVelocity()

    -- Stop moving when our velocity has fallen below threshold.
    if velocity:getMagnitude() < 70 then
       Pathfinder.standStill()

        return
    end

    local inverseVelocity = -velocity

    -- Counter our current velocity.
    Pathfinder.moveAtAngle(inverseVelocity:getAngleFromForward())
end

--- @return void
function AiStateEngage:actionWatchAngle()
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

    VirtualMouse.lookAtLocation(self.watchOrigin, self.aimSpeed, VirtualMouse.noise.moving, "Engage watch last spot")

    self:addVisualizer("watch", function()
        if self.watchOrigin then
            self.watchOrigin:drawCircleOutline(16, 2, Color:hsla(300, 1, 0.5, 200))
        end
    end)
end

--- @return void
function AiStateEngage:actionStrafePeek()
    self.canWallbang = true
    self.isStrafePeeking = false

    if self.strafePeekTimer:isStarted() and not self.strafePeekTimer:isElapsedThenStop(0.5) then
        Pathfinder.moveAtAngle(self.strafePeekMoveAngle)

        self.isStrafePeeking = true
        self.canWallbang = false

        return
    end

    local enemy = self.bestTarget

    if not enemy then
        return
    end

    local playerOrigin = LocalPlayer:getOrigin()
    local enemyOrigin = enemy:getOrigin()
    local angleToEnemy = playerOrigin:getAngle(enemyOrigin)

    --- @type Vector3[]
    local directions = {
        Left = angleToEnemy:getLeft(),
        Right = angleToEnemy:getRight()
    }

    --- @type Angle
    local moveAngle
    local moveDirection
    local eyeOrigin = LocalPlayer.getEyeOrigin()
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

    local traceOptions = Table.getMerged(AiUtility.traceOptionsAttacking, {
        distance = distance
    })

    local count = 0

    for name, direction in pairs(directions) do
        local findOffsetTrace = Trace.getHullInDirection(eyeOrigin, direction, bounds, traceOptions, "AiStateEngage.strafePeek<FindStrafePeekDirection>")
        local offsetTraceOrigin = findOffsetTrace.endPosition
        local isVisible = false

        for _, hitbox in pairs(enemy:getHitboxPositions({
            Player.hitbox.HEAD,
            Player.hitbox.PELVIS,
            Player.hitbox.LEFT_LOWER_LEG,
            Player.hitbox.RIGHT_LOWER_ARM,
            Player.hitbox.LEFT_LOWER_ARM,
            Player.hitbox.RIGHT_LOWER_LEG,
        })) do
            local findVisibleHitboxTrace = Trace.getLineToPosition(hitbox, offsetTraceOrigin, AiUtility.traceOptionsAttacking, "AiStateEngage.strafePeek<FindVisibleHitbox>")

            if not findVisibleHitboxTrace.isIntersectingGeometry then
                isVisible = true

                break
            end
        end

        if isVisible then
            moveAngle = direction:getAngleFromForward()
            moveDirection = name
            count = count + 1
        end
    end

    if moveAngle then
        if count == 1 then
            self.strafePeekMoveAngle = moveAngle
            self.strafePeekTimer:ifPausedThenStart()

            self.strafePeekDirection = moveDirection
        end
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

    if Pathfinder.isAscendingLadder or Pathfinder.isDescendingLadder then
        return
    end

    local clientVelocity = LocalPlayer:m_vecVelocity()

    if clientVelocity:getMagnitude() < 50 then
        return
    end

    if not self.preAimThroughCornersBlockTimer:isElapsed(0.8) then
        return
    end

    local playerOrigin = LocalPlayer:getOrigin()
    local hitboxes = target:getHitboxPositions({
        Player.hitbox.HEAD,
        Player.hitbox.LEFT_LOWER_LEG,
        Player.hitbox.RIGHT_LOWER_LEG,
        Player.hitbox.LEFT_LOWER_ARM,
        Player.hitbox.RIGHT_LOWER_ARM,
    })

    -- Determine if we're about to peek the target.
    local testOrigin = LocalPlayer.getEyeOrigin() + (clientVelocity * 0.5)
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

            local _, fraction, eid = playerOrigin:getTraceLine(hitbox, LocalPlayer.eid)

            if eid == target.eid or fraction == 1 then
                self.preAimThroughCornersBlockTimer:start()

                return
            end
        end
    end

    if self.preAimThroughCornersUpdateTimer:isElapsedThenRestart(1.2) then
        local hitboxPosition = target:getHitboxPosition(Player.hitbox.HEAD)
        local distance = playerOrigin:getDistance(hitboxPosition)
        local offsetRange = Math.getFloat(Math.getClamped(distance, 0, 1024), 1024) * 150

        self.preAimThroughCornersOrigin = hitboxPosition:offset(
            Math.getRandomFloat(-offsetRange, offsetRange),
            Math.getRandomFloat(-offsetRange, offsetRange),
            Math.getRandomFloat(-8, 2)
        ) - (clientVelocity:clone():set(nil, nil, 0) * 0.15)
    end

    self.preAimTarget = self.bestTarget

   VirtualMouse.lookAtLocation(self.preAimThroughCornersOrigin, 12, VirtualMouse.noise.moving, "Engage look through corner")

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

    if self.bestTarget:getFlag(Player.flags.FL_ONGROUND) then
        self.preAimAboutCornersCenterOriginZ = self.preAimAboutCornersCenterOrigin.z
    end

    if not self.preAimAboutCornersCenterOrigin then
        return
    end

    if self.isBestTargetVisible then
        return
    end

    if self.preAimAboutCornersAimOrigin then
        self.ai.routines.manageWeaponScope:block()

       VirtualMouse.lookAtLocation(self.preAimAboutCornersAimOrigin, self.slowAimSpeed, VirtualMouse.noise.moving, "Engage look at corner")

        self:addVisualizer("pre about", function()
            if self.preAimAboutCornersAimOrigin then
                self.preAimAboutCornersAimOrigin:drawCircleOutline(12, 2, Color:hsla(200, 1, 0.5, 200))
            end
        end)
    end

    local enemyOrigin = self.bestTarget:getOrigin()

    if not self.preAimAboutCornersLastOrigin then
        self.preAimAboutCornersLastOrigin = enemyOrigin
    elseif enemyOrigin:getDistance(self.preAimAboutCornersLastOrigin) < 60 then
        return
    end

    self.preAimAboutCornersLastOrigin = enemyOrigin

    if not self.bestTarget:getFlag(Player.flags.FL_ONGROUND) and self.preAimAboutCornersCenterOriginZ then
        self.preAimAboutCornersCenterOrigin.z = self.preAimAboutCornersCenterOriginZ
    end

    local eyeOrigin = LocalPlayer.getEyeOrigin()
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
            distance = 120,
            points = 6
        },
        {
            distance = 160,
            points = 8
        },
        {
            distance = 200,
            points = 16
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

    if closestVertex then
        local findFloorTrace = Trace.getLineInDirection(closestVertex, Vector3.align.DOWN, AiUtility.traceOptionsPathfinding)
        local newClosestVertex = findFloorTrace.endPosition:offset(0, 0, 60)
        local deltaZ = closestVertex.z - newClosestVertex.z

        if deltaZ > 0 and deltaZ < 128 then
            closestVertex = newClosestVertex
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

--- @param skill number
--- @return void
function AiStateEngage:setAimSkill(skill)
    self.skill = skill

    local skillMinimum = {
        reactionTime = 0.25,
        prefireReactionTime = 0.15,
        anticipateTime = 0.066,
        sprayTime = 0.45,
        aimSpeed = 9,
        slowAimSpeed = 6.5,
        recoilControl = 2.5,
        aimOffset = 48,
        aimInaccurateOffset = 144,
        blockTime = 0.25
    }

    local skillMaximum = {
        reactionTime = 0.01,
        prefireReactionTime = 0.005,
        anticipateTime = 0.01,
        sprayTime = 0.2,
        aimSpeed = 16,
        slowAimSpeed = 9.5,
        recoilControl = 2,
        aimOffset = 0,
        aimInaccurateOffset = 80,
        blockTime = 0.01
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

return Nyx.class("AiStateEngage", AiStateEngage, AiStateBase)
--}}}
