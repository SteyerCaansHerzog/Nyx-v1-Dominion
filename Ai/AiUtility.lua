--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local DrawDebug = require "gamesense/Nyx/v1/Api/DrawDebug"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
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
local GamemodeInfo = require "gamesense/Nyx/v1/Dominion/Ai/Info/GamemodeInfo"
local MapInfo = require "gamesense/Nyx/v1/Dominion/Ai/Info/MapInfo"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
--}}}

--{{{ AiUtility
--- @class AiUtility : Class
--- @field bomb Entity
--- @field bombCarrier Player
--- @field bombDetonationTime number
--- @field canDefuse boolean
--- @field clientNodeOrigin Vector3
--- @field clientThreatenedBy Player
--- @field clientThreatenedFromOrigin Vector3
--- @field clientThreatenedFromOriginPlayer Player
--- @field closestEnemy Player
--- @field closestEnemyDistance number
--- @field closestTeammate Player
--- @field closestTeammateDistance number
--- @field closestThreat Player
--- @field defuseTimer Timer
--- @field dormantAt number[]
--- @field enemies Player[]
--- @field enemiesAlive number
--- @field enemiesTotal number
--- @field enemyDistances number[]
--- @field enemyFovs number[]
--- @field enemyHitboxes table<number, Vector3[]>
--- @field gamemodes GamemodeInfo
--- @field gameRules GameRules
--- @field hostageCarriers Player[]
--- @field ignorePresenceAfter number
--- @field isBombBeingDefusedByEnemy boolean
--- @field isBombBeingDefusedByTeammate boolean
--- @field isBombBeingPlantedByEnemy boolean
--- @field isBombBeingPlantedByTeammate boolean
--- @field isClientPlanting boolean
--- @field isClientThreatenedMajor boolean
--- @field isClientThreatenedMinor boolean
--- @field isEnemyVisible boolean
--- @field isHostageBeingPickedUpByEnemy boolean
--- @field isHostageBeingPickedUpByTeammate boolean
--- @field isHostageCarriedByEnemy boolean
--- @field isHostageCarriedByTeammate boolean
--- @field isInsideSmoke boolean
--- @field isLastAlive boolean
--- @field isPerformingCalculations boolean
--- @field isRoundOver boolean
--- @field lastPresenceTimers Timer[]
--- @field lastThreatenedAgo Timer
--- @field lastVisibleEnemyTimer Timer
--- @field mapInfo MapInfo
--- @field plantedAtBombsite string
--- @field plantedBomb Entity
--- @field position number
--- @field randomBombsite string
--- @field teammates Player[]
--- @field teammatesAlive number
--- @field teammatesAndClient Player[]
--- @field teammatesTotal number
--- @field threatLastOrigins Vector3[]
--- @field threats boolean[]
--- @field threatUpdateTimer Timer
--- @field threatZs number[]
--- @field timeData GameStateTimeData
--- @field totalThreats number
--- @field traceOptionsPathfinding TraceOptions
--- @field traceOptionsVisible TraceOptions
--- @field updateThreatsCache table
--- @field updateThreatsIndex number
--- @field visibleEnemies Player[]
--- @field visibleFovThreshold number
local AiUtility = {
    gamemodes = GamemodeInfo
}

--- @return void
function AiUtility:__setup()
    AiUtility.initFields()
    AiUtility.initEvents()
end

--- @return void
function AiUtility.seedPrng()
    -- This must be executed as the very first setupCommand event that runs. Before everything else.
    -- It is responsible for ensuring RNG between AI clients on the same server are properly randomised.
    if entity.get_local_player() then
        for _ = 0, entity.get_local_player() * 100 do
            client.random_float(0, 1)
        end
    end
end

--- @return void
function AiUtility:initFields()
    AiUtility.isPerformingCalculations = true
    AiUtility.clientNodeOrigin = LocalPlayer:getOrigin():offset(0, 0, 18)
    AiUtility.visibleEnemies = {}
    AiUtility.lastVisibleEnemyTimer = Timer:new()
    AiUtility.enemyDistances = Table.populateForMaxPlayers(math.huge)
    AiUtility.enemyFovs = Table.populateForMaxPlayers(math.huge)
    AiUtility.ignorePresenceAfter = Math.getRandomFloat(10, 15)
    AiUtility.lastPresenceTimers = {}
    AiUtility.visibleFovThreshold = 53
    AiUtility.updateThreatsIndex = 0
    AiUtility.updateThreatsCache = {}
    AiUtility.lastThreatenedAgo = Timer:new():startThenElapse()

    for i = 1, 64 do
        AiUtility.lastPresenceTimers[i] = Timer:new():startThenElapse()
    end

    AiUtility.defuseTimer = Timer:new()
    AiUtility.dormantAt = {}
    AiUtility.enemies = {}
    AiUtility.teammates = {}
    AiUtility.teammatesAndClient = {}
    AiUtility.enemiesAlive = 0
    AiUtility.teammatesAlive = 0
    AiUtility.threatZs = {}
    AiUtility.threatLastOrigins = {}
    AiUtility.totalThreats = 0
    AiUtility.threatUpdateTimer = Timer:new():startThenElapse()
    AiUtility.gameRules = Entity.getGameRules()
    AiUtility.randomBombsite = Math.getChance(2) and "A" or "B"

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

    local solidVisibleEntities = {
        CFuncBrush = true,
        CBaseEntity = true,
        CPropDoorRotating = true,
        CFuncBrush = true
    }

    AiUtility.traceOptionsVisible = {
        skip = function(eid, contents)
            local entity = Entity:create(eid)

            if solidVisibleEntities[entity.classname] then
                return false
            end

            if bit.band(Trace.contents.WINDOW, contents) == Trace.contents.WINDOW then
                return true
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
        AiUtility.plantedAtBombsite = nil
        AiUtility.canDefuse = nil
        AiUtility.visibleEnemies = {}
        AiUtility.enemyDistances = Table.populateForMaxPlayers(math.huge)
        AiUtility.enemyFovs = Table.populateForMaxPlayers(math.huge)
        AiUtility.dormantAt = {}

        AiUtility.defuseTimer:stop()
    end)

    Callbacks.roundEnd(function()
        AiUtility.isRoundOver = true
    end)

    Callbacks.init(function()
        local map = Server.getMapName()

        if not map then
            return
        end

        map = map:gsub("/", "_")

        if map and MapInfo[map] then
            AiUtility.mapInfo = MapInfo[map]
        end

        AiUtility.timeData = Table.fromPanorama(Panorama.GameStateAPI.GetTimeDataJSO())
    end)

    Callbacks.roundStart(function()
        local roundsPlayed = AiUtility.gameRules:m_totalRoundsPlayed()

        if not roundsPlayed then
            return
        end

        Logger.console(Logger.ALERT, Localization.aiUtilityNewRound, roundsPlayed + 1)
    end)

    Callbacks.roundPrestart(function(e)
        AiUtility.isRoundOver = false
        AiUtility.isBombBeingDefusedByEnemy = false
        AiUtility.isBombBeingDefusedByTeammate = false
        AiUtility.isBombBeingPlantedByEnemy = false
        AiUtility.isBombBeingPlantedByTeammate = false
        AiUtility.isClientPlanting = false
        AiUtility.randomBombsite = Math.getChance(2) and "A" or "B"
    end)

    Callbacks.bombBeginPlant(function(e)
        AiUtility.plantedAtBombsite = AiUtility.getBombsiteFromIdx(e.site)

        if e.player:isLocalPlayer() then
            AiUtility.isClientPlanting = true
        elseif e.player:isTeammate() then
            AiUtility.isBombBeingPlantedByTeammate = true
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingPlantedByEnemy = true
            AiUtility.lastPresenceTimers[e.player.eid]:start()
        end
    end)

    Callbacks.bombAbortPlant(function(e)
        AiUtility.plantedAtBombsite = nil

        if e.player:isLocalPlayer() then
            AiUtility.isClientPlanting = false
        elseif e.player:isTeammate() then
            AiUtility.isBombBeingPlantedByTeammate = false
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingPlantedByEnemy = false
        end
    end)

    Callbacks.bombPlanted(function(e)
        AiUtility.plantedAtBombsite = AiUtility.getBombsiteFromIdx(e.site)
        AiUtility.isClientPlanting = false
        AiUtility.isBombBeingPlantedByEnemy = false
        AiUtility.isBombBeingPlantedByTeammate = false

        if e.player:isEnemy() then
            AiUtility.lastPresenceTimers[e.player.eid]:start()
        end
    end)

    Callbacks.bombBeginDefuse(function(e)
        if e.player:isLocalPlayer() then
            AiUtility.defuseTimer:start()
        end

        if not e.player:isLocalPlayer() and e.player:isTeammate() then
            AiUtility.isBombBeingDefusedByTeammate = true
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingDefusedByEnemy = true

            AiUtility.lastPresenceTimers[e.player.eid]:start()
        end
    end)

    Callbacks.bombAbortDefuse(function(e)
        if e.player:isLocalPlayer() then
            AiUtility.defuseTimer:stop()
        end

        if not e.player:isLocalPlayer() and e.player:isTeammate() then
            AiUtility.isBombBeingDefusedByTeammate = false
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingDefusedByEnemy = false
        end
    end)

    Callbacks.bombDefused(function(e)
        if e.player:isLocalPlayer() then
            AiUtility.defuseTimer:stop()
        end

        if not e.player:isLocalPlayer() and e.player:isTeammate() then
            AiUtility.isBombBeingDefusedByTeammate = false
        elseif e.player:isEnemy() then
            AiUtility.isBombBeingDefusedByEnemy = false

            AiUtility.lastPresenceTimers[e.player.eid]:start()
        end
    end)

    Callbacks.playerDeath(function(e)
        if e.victim:isLocalPlayer() then
            AiUtility.canDefuse = nil
            AiUtility.visibleEnemies = {}
            AiUtility.enemyDistances = Table.populateForMaxPlayers(math.huge)
            AiUtility.enemyFovs = Table.populateForMaxPlayers(math.huge)
            AiUtility.dormantAt = {}
        end

        if e.attacker:isEnemy() then
            local timer = AiUtility.lastPresenceTimers[e.attacker.eid]

            if timer then
                timer:start()
            end
        end
    end)

    Callbacks.weaponFire(function(e)
        AiUtility.lastPresenceTimers[e.player.eid]:start()
    end)

    Callbacks.playerFootstep(function(e)
        if LocalPlayer:getOrigin():getDistance(e.player:getOrigin()) > 3000 then
            return
        end

        AiUtility.lastPresenceTimers[e.player.eid]:start()
    end)

    Callbacks.weaponReload(function(e)
        if LocalPlayer:getOrigin():getDistance(e.player:getOrigin()) > 3000 then
            return
        end

        AiUtility.lastPresenceTimers[e.player.eid]:start()
    end)

    Callbacks.weaponZoom(function(e)
        if LocalPlayer:getOrigin():getDistance(e.player:getOrigin()) > 2000 then
            return
        end

        AiUtility.lastPresenceTimers[e.player.eid]:start()
    end)

    Callbacks.netUpdateEnd(function()
        AiUtility.updateAllPlayers()

        if not AiUtility.isPerformingCalculations then
            return
        end

        AiUtility.seedPrng()
        AiUtility.updateMisc()
        AiUtility.updateEnemies()
        AiUtility.updateThreats()
    end, false)
end

--- @return void
function AiUtility.updateMisc()
    AiUtility.clientNodeOrigin = LocalPlayer:getOrigin():offset(0, 0, 18)
    AiUtility.bomb = Entity.findOne("CC4")
    AiUtility.plantedBomb = Entity.findOne("CPlantedC4")
    AiUtility.gameRules = Entity.getGameRules()
    AiUtility.timeData = Table.fromPanorama(Panorama.GameStateAPI.GetTimeDataJSO())

    local i = 0

    for _, player in Table.sortedPairs(Player.get(function(p)
        return p:isTeammate()
    end), function(a, b)
        return a.eid < b.eid
    end) do
        i = i + 1

        if player:isLocalPlayer() then
            AiUtility.position = i

            break
        end
    end

    local clientOrigin = LocalPlayer:getOrigin()

    AiUtility.isInsideSmoke = false

    for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
        if clientOrigin:getDistance(smoke:m_vecOrigin()) < 150 then
            AiUtility.isInsideSmoke = true
        end
    end
end

--- @return void
function AiUtility.updateAllPlayers()
    AiUtility.teammates = {}
    AiUtility.teammatesAndClient = {}
    AiUtility.enemiesAlive = 0
    AiUtility.teammatesAlive = 0
    AiUtility.enemiesTotal = 0
    AiUtility.teammatesTotal = 0
    AiUtility.isHostageCarriedByEnemy = false
    AiUtility.isHostageCarriedByTeammate = false
    AiUtility.hostageCarriers = {}
    AiUtility.bombCarrier = nil
    AiUtility.closestTeammate = nil
    AiUtility.closestTeammateDistance = nil
    AiUtility.isLastAlive = false
    AiUtility.enemies = {}
    AiUtility.visibleEnemies = {}
    AiUtility.closestEnemy = nil
    AiUtility.closestEnemyDistance = nil
    AiUtility.isEnemyVisible = false
    AiUtility.isHostageBeingPickedUpByEnemy = false
    AiUtility.isHostageBeingPickedUpByTeammate = false

    local clientOrigin = LocalPlayer:getOrigin()
    local closestTeammate
    local closestTeammateDistance = math.huge
    local playerResource = entity.get_player_resource()

    for eid = 1, globals.maxplayers() do repeat
        local player = Player:new(eid)

        if not player:isValid() then
            break
        end

        local playerXuid = player:getSteamId64()
        local isEnemy = player:isEnemy()
        local isAlive = Panorama.GameStateAPI.IsPlayerAlive(playerXuid)

        if isAlive then
            local isValidOrigin = not player:getOrigin():isZero()

            if isValidOrigin and entity.get_prop(playerResource, "m_iPlayerC4") == eid then
                AiUtility.bombCarrier = player
            end
        end

        if isEnemy then
            AiUtility.enemiesTotal = AiUtility.enemiesTotal + 1

            if not isAlive then
                break
            end

            AiUtility.enemiesAlive = AiUtility.enemiesAlive + 1

            -- Disable GS's braindead AA detection.
            plist.set(eid, "Correction active", false)

            if player:m_hCarriedHostage() ~= nil then
                AiUtility.isHostageCarriedByEnemy = true
                AiUtility.hostageCarriers[eid] = player
            end

            if player:m_bIsGrabbingHostage() == 1 then
                AiUtility.isHostageBeingPickedUpByEnemy = true
            end
        else
            AiUtility.teammatesTotal = AiUtility.teammatesTotal + 1

            if not isAlive then
                break
            end

            AiUtility.teammatesAndClient[player.eid] = player
            AiUtility.teammatesAlive = AiUtility.teammatesAlive + 1

            if player:isLocalPlayer() then
                break
            end

            AiUtility.teammates[player.eid] = player

            if player:m_hCarriedHostage() ~= nil then
                AiUtility.isHostageCarriedByTeammate = true
                AiUtility.hostageCarriers[eid] = player
            end

            if player:m_bIsGrabbingHostage() == 1 then
                AiUtility.isHostageBeingPickedUpByTeammate = true
            end

            local distance = player:getOrigin():getDistance(clientOrigin)

            if distance < closestTeammateDistance then
                closestTeammateDistance = distance
                closestTeammate = player
            end
        end
    until true end

    if closestTeammate then
        AiUtility.closestTeammate = closestTeammate
        AiUtility.closestTeammateDistance = closestTeammateDistance
    end

    -- We remove 1 to remove the local player. Then check if more than 1 teammate is alive.
    if LocalPlayer:isAlive() and (AiUtility.teammatesAlive - 1) == 0 then
        AiUtility.isLastAlive = true
    end
end

--- @return void
function AiUtility.updateEnemies()
    local clientOrigin = LocalPlayer:getOrigin()
    local clientEyeOrigin = LocalPlayer.getEyeOrigin()
    local cameraAngles = LocalPlayer.getCameraAngles()

    local closestEnemy
    local closestDistance = math.huge

    for _, enemy in Player.find(function(p)
        return p:isEnemy() and p:isAlive()
    end) do
        AiUtility.enemies[enemy.eid] = enemy

        if not enemy:isDormant() then
            AiUtility.dormantAt[enemy.eid] = Time.getRealtime()
        end

        local enemyOrigin = enemy:getOrigin()
        local distance = clientOrigin:getDistance(enemyOrigin)
        local fov = cameraAngles:getFov(clientEyeOrigin, enemy:getHitboxPosition(Player.hitbox.SPINE_1))

        AiUtility.enemyFovs[enemy.eid] = fov

        if distance < closestDistance then
            closestDistance = distance
            closestEnemy = enemy
        end

        AiUtility.enemyDistances[enemy.eid] = distance

        local isVisible = false

        if not enemy:isDormant() then
            for _, hitbox in pairs(enemy:getHitboxPositions({
                Player.hitbox.HEAD,
                Player.hitbox.PELVIS,
                Player.hitbox.LEFT_LOWER_LEG,
                Player.hitbox.RIGHT_LOWER_ARM,
                Player.hitbox.LEFT_LOWER_ARM,
                Player.hitbox.RIGHT_LOWER_LEG,
            })) do
                if not clientEyeOrigin:isRayIntersectingSmoke(hitbox) then
                    local trace = Trace.getLineToPosition(clientEyeOrigin, hitbox, AiUtility.traceOptionsVisible, "AiUtility.updateEnemies<FindPointVisibleToClient>")

                    if not trace.isIntersectingGeometry then
                        isVisible = true

                        break
                    end
                end
            end
        end

        if isVisible then
            AiUtility.visibleEnemies[enemy.eid] = enemy
            AiUtility.isEnemyVisible = true
        elseif enemy:m_bIsDefusing() == 1 then
            AiUtility.visibleEnemies[enemy.eid] = enemy
        end
    end

    if closestEnemy then
        AiUtility.closestEnemy = closestEnemy
        AiUtility.closestEnemyDistance = closestDistance
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

        local playerHasKit = LocalPlayer:m_bHasDefuser() == 1
        local defuseTime = 10

        if playerHasKit then
            defuseTime = 5
        end

        AiUtility.canDefuse = time > defuseTime
    end
end

--- @return void
function AiUtility.updateThreats()
    -- Don't update the threat origin too often, or it'll be obvious this is effectively wallhacking.
    if not AiUtility.threatUpdateTimer:isElapsedThenRestart(0.15) then
        return
    end

    AiUtility.threats = {}
    AiUtility.clientThreatenedFromOrigin = nil
    AiUtility.isClientThreatenedMinor = false
    AiUtility.isClientThreatenedMajor = false

    local eyeOrigin = LocalPlayer.getEyeOrigin() + LocalPlayer:m_vecVelocity():set(nil, nil, 0) * 0.33
    local threats = 0
    local clientPlane = eyeOrigin:getPlane(Vector3.align.CENTER, 120)
    local clientOrigin = LocalPlayer:getOrigin()
    --- @type Player
    local closestThreat
    local closestThreatDistance = math.huge
    local clientThreatenedFromOrigin
    local clientThreatenedFromOriginPlayer

    -- Threat points above head.
    table.insert(clientPlane, clientOrigin:clone():offset(0, 0, 120))

    -- Prevent our own plane from clipping thin walls.
    -- It can look very wrong when pre-aiming through certain geometry.
    for id, vertex in pairs(clientPlane) do
        local trace = Trace.getLineToPosition(eyeOrigin, vertex, AiUtility.traceOptionsVisible, "AiUtility.updateThreats<FindClientPlaneWallCollidePoint>")

        clientPlane[id] = trace.endPosition
    end

    for _, enemy in Table.sortedPairs(AiUtility.enemies, function(a, b)
    	return a.eid < b.eid
    end) do repeat
        if AiUtility.visibleEnemies[enemy.eid] then
            AiUtility.isClientThreatenedMinor = true
            AiUtility.isClientThreatenedMajor = true
            AiUtility.clientThreatenedFromOrigin = enemy:getOrigin():offset(0, 0, 64)
            AiUtility.clientThreatenedFromOriginPlayer = enemy
            AiUtility.threats[enemy.eid] = true

            break
        end

        local enemyOrigin = enemy:getOrigin()
        local canSetThreatenedFromOrigin = false

        if enemy:isFlagActive(Player.flags.FL_ONGROUND) then
            AiUtility.threatZs[enemy.eid] = enemyOrigin.z
        elseif AiUtility.threatZs[enemy.eid] then
            enemyOrigin.z = AiUtility.threatZs[enemy.eid]
        end

        if not AiUtility.threatLastOrigins[enemy.eid] then
            AiUtility.threatLastOrigins[enemy.eid] = enemyOrigin
        end

        if enemyOrigin:getDistance(AiUtility.threatLastOrigins[enemy.eid]) < 80 then
            enemyOrigin = AiUtility.threatLastOrigins[enemy.eid]:clone()
        else
            AiUtility.threatLastOrigins[enemy.eid] = enemyOrigin:clone()
        end

        if not AiUtility.lastPresenceTimers[enemy.eid]:isElapsed(AiUtility.ignorePresenceAfter) then
            canSetThreatenedFromOrigin = true
        elseif clientOrigin:getDistance(enemyOrigin) > 400 then
            canSetThreatenedFromOrigin = true
        end

        local enemyOffset = enemyOrigin:offset(0, 0, 50)
        local bandAngle = eyeOrigin:getAngle(enemyOffset):set(0):offset(0, 90)
        local enemyAngle = eyeOrigin:getAngle(enemyOffset)
        local steps = 6
        local stepDistance = 180 / steps
        local isClientThreatenedMinor = false
        local isClientThreatenedMajor = false
        local absPitch = math.abs(enemyAngle.p)
        local traceExtension = 1 - Math.getFloat(Math.getClamped(absPitch, 0, 75), 90)
        local traceDistance = 320 * traceExtension
        local lowestFov = math.huge

        for _ = 1, steps do
            local collideIdealOrigin = enemyOffset + bandAngle:getForward() * traceDistance * 0.66
            local uncollideIdealOrigin = enemyOffset + bandAngle:getForward() * traceDistance
            local findWallCollideTrace = Trace.getLineToPosition(enemyOffset, collideIdealOrigin, AiUtility.traceOptionsVisible, "AiUtility.updateThreats<FindWallCollidePoint>")

            for _, vertex in pairs(clientPlane) do
                local findCollidedPointVisibleToEnemyTrace = Trace.getLineToPosition(findWallCollideTrace.endPosition, vertex, AiUtility.traceOptionsVisible, "AiUtility.updateThreats<FindCollidedPointVisibleToEnemy>")

                if not findCollidedPointVisibleToEnemyTrace.isIntersectingGeometry then
                    isClientThreatenedMinor = true

                    if not eyeOrigin:isRayIntersectingSmoke(findCollidedPointVisibleToEnemyTrace.endPosition) then
                        isClientThreatenedMajor = true
                    end

                    local fov = enemyAngle:getFov(eyeOrigin, findWallCollideTrace.endPosition)

                    if canSetThreatenedFromOrigin and fov < lowestFov and fov < 20 then
                        lowestFov = fov

                        clientThreatenedFromOrigin = findWallCollideTrace.endPosition
                        clientThreatenedFromOriginPlayer = enemy
                    end
                end

                if findCollidedPointVisibleToEnemyTrace.isIntersectingGeometry and not isClientThreatenedMinor and not isClientThreatenedMajor then
                    local findUncollidedPointVisibleToEnemyTrace = Trace.getLineToPosition(uncollideIdealOrigin, vertex, AiUtility.traceOptionsVisible, "AiUtility.updateThreats<FindUncollidedPointVisibleToEnemy>")

                    if not findUncollidedPointVisibleToEnemyTrace.isIntersectingGeometry then
                        isClientThreatenedMinor = true
                    end
                end
            end

            bandAngle:offset(0, stepDistance)
        end

        if isClientThreatenedMinor or isClientThreatenedMajor then
            AiUtility.isClientThreatenedMinor = true
            AiUtility.isClientThreatenedMajor = isClientThreatenedMajor
            AiUtility.clientThreatenedBy = enemy
            AiUtility.threats[enemy.eid] = true

            local distance = clientOrigin:getDistance(enemyOrigin)

            if distance < closestThreatDistance then
                closestThreatDistance = distance
                closestThreat = enemy
            end

            threats = threats + 1
        end
    until true end

    if clientThreatenedFromOrigin then
        local predictedEyeOrigin = eyeOrigin + LocalPlayer:m_vecVelocity() * 0.4
        local findVisibleTrace = Trace.getLineToPosition(eyeOrigin, clientThreatenedFromOrigin, AiUtility.traceOptionsVisible)
        local findPredictedVisibleTrace = Trace.getLineToPosition(predictedEyeOrigin, clientThreatenedFromOrigin, AiUtility.traceOptionsVisible)

        if not findVisibleTrace.isIntersectingGeometry or not findPredictedVisibleTrace.isIntersectingGeometry then
            AiUtility.clientThreatenedFromOrigin = clientThreatenedFromOrigin
            AiUtility.clientThreatenedFromOriginPlayer = clientThreatenedFromOriginPlayer
        end

        -- If it's too close, we can end up looking at the position in a weird manner.
        if eyeOrigin:getDistance(clientThreatenedFromOrigin) < 100 then
            AiUtility.clientThreatenedFromOrigin = nil
            AiUtility.clientThreatenedFromOriginPlayer = nil
        end
    end

    AiUtility.closestThreat = closestThreat
    AiUtility.totalThreats = threats

    if AiUtility.isClientThreatenedMinor or AiUtility.isClientThreatenedMajor then
        AiUtility.lastThreatenedAgo:start()
    end
end

--- @return boolean
function AiUtility.isBombPlanted()
    return AiUtility.plantedBomb ~= nil
end

--- @return boolean
function AiUtility.isBombDefused()
    if not AiUtility.isBombPlanted() then
        return false
    end

    return AiUtility.plantedBomb:m_bBombDefused() == 1
end

--- @param idx number
--- @return string
function AiUtility.getBombsiteFromIdx(idx)
    local playerResource = Entity.getPlayerResource()
    local bombsite = Entity:create(idx)
    local centerA = playerResource:m_bombsiteCenterA()
    local centerB = playerResource:m_bombsiteCenterB()
    local mins, maxs = bombsite:m_vecMins(), bombsite:m_vecMaxs()
    local center = mins:getLerp(maxs, 0.5)
    local distanceToA, distanceToB = center:getDistance(centerA), center:getDistance(centerB)

    return distanceToB > distanceToA and "A" or "B"
end

--- Use this at round start. Don't use this elsewhere, thanks in advance.
---
--- @param chance number
--- @return boolean
function AiUtility.getPredictableChance(chance)
    local rng = 0

    for _, player in Player.findAll() do
        rng = rng + player:m_iKills()
        rng = rng + player:m_iDeaths()
        rng = rng + player:m_iAssists()
    end

    rng = rng + AiUtility.gameRules:m_totalRoundsPlayed()

    return rng % chance == 0
end

return Nyx.class("AiUtility", AiUtility)
--}}}
