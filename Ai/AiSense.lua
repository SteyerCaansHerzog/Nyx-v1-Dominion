--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ Definitions
--- @class AwarenessLevel
local AwarenessLevel = {
	IMMEDIATE_VISIBLE = 0, -- Visible to the client.
	IMMEDIATE_SHALLOW_OCCLUDED = 1, -- Not visible to client, but just made noise, and can peek imminently.
	IMMEDIATE_DEEP_OCCLUDED = 2, -- Not visible to client, but just made noise, and cannot peek imminently.
	IMMEDIATE_PROXY = 3, -- Sensed by (or related to) a teammate, or is far away.
	RECENT_NEARBY = 4, -- Known about recently, but hasn't moved outside of sensed area.
	RECENT_MOVED = 5, -- Known about recently, and has moved outside of sensed area.
	OLD = 6, -- Known about sometime ago. Position is not reliable.
	STALE = 7, -- Was known about sometime ago, but is now stale, and position cannot be known.
	UNKNOWN = 8, -- Not yet known. No information on the player.
}
--}}}

--{{{ AiSense
--- @class AiSense : Class
--- @field awareness AwarenessLevel
--- @field awarenessLevels number[]
--- @field lastAwareIsOriginStale boolean[]
--- @field lastAwareIsProxy boolean[]
--- @field lastAwareOrigins Vector3[]
--- @field lastAwareReason string[]
--- @field lastAwareTimers Timer[]
local AiSense = {
	awareness = AwarenessLevel,
	awarenessStrings = {
		[AwarenessLevel.IMMEDIATE_VISIBLE] = "Visible",
		[AwarenessLevel.IMMEDIATE_SHALLOW_OCCLUDED] = "Shallow Occluded",
		[AwarenessLevel.IMMEDIATE_DEEP_OCCLUDED] = "Deep Occluded",
		[AwarenessLevel.IMMEDIATE_PROXY] = "Proxy",
		[AwarenessLevel.RECENT_NEARBY] = "Nearby",
		[AwarenessLevel.RECENT_MOVED] = "Moved",
		[AwarenessLevel.OLD] = "Old",
		[AwarenessLevel.STALE] = "Stale",
		[AwarenessLevel.UNKNOWN] = "Unknown",
	}
}

--- @return void
function AiSense:__setup()
	AiSense.initFields()
	AiSense.initEvents()
end

--- @return void
function AiSense.initFields()
	AiSense.awarenessLevels = {}
	AiSense.lastAwareIsProxy = {}
	AiSense.lastAwareIsOriginStale = {}
	AiSense.lastAwareOrigins = {}
	AiSense.lastAwareReason = {}
	AiSense.lastAwareTimers = {}
end

--- @return void
function AiSense.initEvents()
	Callbacks.levelInit(function()
		AiSense.initFields()
	end)

	Callbacks.roundStart(function()
		AiSense.initFields()
	end)

	Callbacks.playerSpawned(function(e)
		if e.player:isLocalPlayer() then
			AiSense.initFields()
		end

		AiSense.unsense(e.player)
	end)

	Callbacks.runCommand(function()
		AiSense.think()
	end)

	Callbacks.playerFootstep(function(e)
		AiSense.sense(e.player,  1000, false, "footstep")
	end)

	Callbacks.weaponFire(function(e)
		local range

		if e.weapon:find("knife") then
			range = 550
		elseif e.silenced then
			range = 800
		else
			range = 3500
		end

		local isSensedByProxy = false
		local playerOrigin = e.player:getOrigin()

		if playerOrigin:isZero() or LocalPlayer:getOrigin():getDistance(playerOrigin) > 2000 then
			isSensedByProxy = true
		end

		AiSense.sense(e.player, range, isSensedByProxy, "gunfire")
	end)

	Callbacks.playerJump(function(e)
		AiSense.sense(e.player, 800, false, "jumped")
	end)

	Callbacks.weaponZoom(function(e)
		AiSense.sense(e.player, 650, false, "zoom")
	end)

	Callbacks.weaponReload(function(e)
		AiSense.sense(e.player, 750, false, "reload")
	end)

	Callbacks.bulletImpact(function(e)
		if not e.shooter:isEnemy() then
			return
		end

		local eyeOrigin = LocalPlayer.getEyeOrigin()
		local rayIntersection = eyeOrigin:getRayClosestPoint(e.shooter:getOrigin():offset(0, 0, 64), e.origin)

		if eyeOrigin:getDistance(rayIntersection) > 450 then
			return
		end

		AiSense.sense(e.shooter, Vector3.MAX_DISTANCE, false, "shot at")
	end)

	Callbacks.bombBeginDefuse(function(e)
		AiSense.sense(e.player, 1250, false, "defuse")
	end)

	Callbacks.bombBeginPlant(function(e)
		AiSense.sense(e.player, 1250, false, "plant")
	end)

	Callbacks.playerHurt(function(e)
		if e.victim:isLocalPlayer() then
			AiSense.sense(e.attacker, Vector3.MAX_DISTANCE, false, "hurt by")

			return
		end

		if not e.victim:isTeammate() then
			return
		end

		AiSense.sense(e.attacker, Vector3.MAX_DISTANCE, true, "teammate hurt by")
	end)
end

--- @param player Player
--- @return number, string
function AiSense.getAwareness(player)
	if not player then
		return AwarenessLevel.UNKNOWN, "no info"
	end

	return
		AiSense.awarenessLevels[player.eid] or AwarenessLevel.UNKNOWN,
		AiSense.lastAwareReason[player.eid] or "no info"
end

--- @param player Player
--- @param maxRange number
--- @param isSensedByProxy boolean
--- @param reason string
--- @return void
function AiSense.sense(player, maxRange, isSensedByProxy, reason)
	if not player:isEnemy() then
		return
	end

	local playerOrigin = player:getOrigin()

	if LocalPlayer:getOrigin():getDistance(playerOrigin) > maxRange then
		return
	end

	if not AiSense.lastAwareTimers[player.eid] then
		AiSense.lastAwareTimers[player.eid] = Timer:new()
	end

	-- Don't set sense as proxy if we already have an immediate awareness of the enemy.
	if AiSense.awarenessLevels[player.eid]
		and AiSense.awarenessLevels[player.eid] <= AwarenessLevel.IMMEDIATE_DEEP_OCCLUDED
	then
		isSensedByProxy = false
	end

	AiSense.lastAwareIsOriginStale[player.eid] = false
	AiSense.lastAwareIsProxy[player.eid] = isSensedByProxy
	AiSense.lastAwareOrigins[player.eid] = playerOrigin
	AiSense.lastAwareReason[player.eid] = reason
	AiSense.lastAwareTimers[player.eid]:start()
end

--- @param player Player
--- @return void
function AiSense.unsense(player)
	AiSense.lastAwareIsOriginStale[player.eid] = nil
	AiSense.lastAwareIsProxy[player.eid] = nil
	AiSense.lastAwareOrigins[player.eid] = nil
	AiSense.lastAwareReason[player.eid] = nil
	AiSense.lastAwareTimers[player.eid] = nil
	AiSense.lastAwareTimers[player.eid] = nil
end

--- @param player Player
--- @return void
function AiSense.ifOnScreenThenSense(player)
	if not AiUtility.visibleEnemies[player.eid] then
		return
	end

	if LocalPlayer.getCameraAngles():getFov(LocalPlayer.getEyeOrigin(), player:getEyeOrigin()) > AiUtility.visibleFovThreshold then
		return
	end

	AiSense.sense(player, Vector3.MAX_DISTANCE, false, "on-screen")

	return
end

--- @param player Player
--- @return void
function AiSense.ifCarryingHostageThenSense(player)
	-- Notice hostage carriers to intercept them.
	if AiUtility.mapInfo.gamemode ~= AiUtility.gamemodes.HOSTAGE or not AiUtility.isHostageCarriedByEnemy then
		return
	end

	if not AiUtility.hostageCarriers[player.eid] then
		return
	end

	AiSense.sense(player, Vector3.MAX_DISTANCE, false, "carrying hostage")
end

--- @param player Player
--- @return void
function AiSense.ifNearPlantedBombThenSense(player)
	if not AiUtility.isBombPlanted() then
		return
	end

	if not LocalPlayer:isCounterTerrorist() then
		return
	end

	if player:getOrigin():getDistance(AiUtility.plantedBomb:m_vecOrigin()) > 512 then
		return
	end

	AiSense.sense(player, Vector3.MAX_DISTANCE, false, "near bomb")
end

--- @param player Player
--- @param awarenessLevel number
--- @return void
function AiSense.setAwarenessLevel(player, awarenessLevel)
	AiSense.awarenessLevels[player.eid] = awarenessLevel
end

--- @return void
function AiSense.think()
	for _, enemy in pairs(AiUtility.enemies) do repeat
		AiSense.ifOnScreenThenSense(enemy)
		AiSense.ifCarryingHostageThenSense(enemy)
		AiSense.ifNearPlantedBombThenSense(enemy)
		-- Sensing enemies inside pre-aims zones is handled by AiStateEngage.

		local lastAwareTimer = AiSense.lastAwareTimers[enemy.eid]
		local lastAwareOrigin = AiSense.lastAwareOrigins[enemy.eid]
		local lastAwareIsProxy = AiSense.lastAwareIsProxy[enemy.eid]

		if not lastAwareTimer then
			-- The enemy has never been sensed.
			AiSense.setAwarenessLevel(enemy, AwarenessLevel.UNKNOWN)

			break
		end

		-- The enemy made sound very recently. We will assume that we know their exact location.
		if not lastAwareTimer:isElapsed(4) then
			if AiUtility.visibleEnemies[enemy.eid] then
				-- The enemy would be on-screen if our camera was pointed at them.
				AiSense.setAwarenessLevel(enemy, AwarenessLevel.IMMEDIATE_VISIBLE)

				break
			elseif not lastAwareIsProxy then
				if AiUtility.threats[enemy.eid] then
					-- The enemy is occluded by cover, but they could peek soon.
					AiSense.setAwarenessLevel(enemy, AwarenessLevel.IMMEDIATE_SHALLOW_OCCLUDED)
				else
					-- The enemy is occluded by cover, and they cannot peek soon.
					AiSense.setAwarenessLevel(enemy, AwarenessLevel.IMMEDIATE_DEEP_OCCLUDED)
				end

				break
			else
				-- The enemy is known by proxy, or the enemy is too far away to be a major threat.
				AiSense.setAwarenessLevel(enemy, AwarenessLevel.IMMEDIATE_PROXY)

				break
			end
		end

		local enemyOrigin = enemy:getOrigin()
		local originDelta = enemyOrigin:getDistance(lastAwareOrigin)
		local isOriginStale = AiSense.lastAwareIsOriginStale[enemy.eid]

		if not isOriginStale and originDelta < 350 then
			if not lastAwareTimer:isElapsed(20) then
				-- The enemy has been known about recently, and has remained where they are.
				AiSense.setAwarenessLevel(enemy, AwarenessLevel.RECENT_NEARBY)

				break
			end
		else
			if not lastAwareTimer:isElapsed(12.5) then
				-- The enemy has been known about recently, but has moved from the position we sensed them at.
				AiSense.setAwarenessLevel(enemy, AwarenessLevel.RECENT_MOVED)

				AiSense.lastAwareIsOriginStale[enemy.eid] = true

				break
			end
		end

		if not lastAwareTimer:isElapsed(25) then
			-- We knew about the enemy sometime ago.
			AiSense.setAwarenessLevel(enemy, AwarenessLevel.OLD)

			break
		end

		if lastAwareTimer:isElapsed(30) then
			-- We knew about the enemy a long time ago.
			-- At this point we basically shouldn't consider our information on the player to be actionable.
			AiSense.setAwarenessLevel(enemy, AwarenessLevel.STALE)

			break
		end
	until true end
end

return Nyx.class("AiSense", AiSense)
--}}}
