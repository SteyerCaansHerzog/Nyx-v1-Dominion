--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ Definitions
local WeaponWeights = {
	DEFAULT = 1,
	[Weapons.SCAR20] = 4,
	[Weapons.G3SG1] = 4,
}
--}}}

--{{{ AiRoutineHandleGunfireAvoidance
--- @class AiRoutineHandleGunfireAvoidance : AiRoutineBase
--- @field cooldownTimer Timer
--- @field expireGunshotsTimer Timer
--- @field playerGunshots number[]
--- @field maxGunshots number
--- @field expireGunshotsAfter number
--- @field gunfireSprayThreshold number
--- @field playerBulletRays table<number, Vector3[]>
--- @field sprayRangeWithin number
local AiRoutineHandleGunfireAvoidance = {}

--- @param fields AiRoutineHandleGunfireAvoidance
--- @return AiRoutineHandleGunfireAvoidance
function AiRoutineHandleGunfireAvoidance:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineHandleGunfireAvoidance:__init()
	self.maxGunshots = 8
	self.gunfireSprayThreshold = 4
	self.expireGunshotsAfter = 0.2
	self.cooldownTimer = Timer:new():startThenElapse()
	self.expireGunshotsTimer = Timer:new():start()
	self.sprayRangeWithin = 185

	Callbacks.init(function()
		self.playerGunshots = Table.populateForMaxPlayers(function()
			return 0
		end)

		self.playerBulletRays = Table.populateForMaxPlayers(function()
			return {}
		end)
	end)

	Callbacks.playerHurt(function(e)
		if not e.victim:isLocalPlayer() then
			return
		end

		if not e.attacker:isEnemy() then
			return
		end

		self.cooldownTimer:start()
	end)

	Callbacks.bulletImpact(function(e)
		if not e.shooter:isEnemy() then
			return
		end

		self.playerBulletRays[e.shooter.eid] = {
			e.shooter:getOrigin():offset(0, 0, 64),
			e.origin
		}
	end)

	Callbacks.weaponFire(function(e)
		if self.playerGunshots[e.player.eid] >= self.maxGunshots then
			return
		end

		local weaponWeight = WeaponWeights[e.player:getWeaponClass()]

		if not weaponWeight then
			weaponWeight = WeaponWeights.DEFAULT
		end

		self.playerGunshots[e.player.eid] = self.playerGunshots[e.player.eid] + weaponWeight
	end)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineHandleGunfireAvoidance:think(cmd)
	if self.expireGunshotsTimer:isElapsedThenRestart(self.expireGunshotsAfter) then
		for eid, _ in pairs(self.playerGunshots) do
			if self.playerGunshots[eid] > 0 then
				self.playerGunshots[eid] = self.playerGunshots[eid] - 1
			end
		end
	end

	-- Do not bait nearby teammates.
	if AiUtility.closestTeammate and AiUtility.closestTeammateDistance < 100 then
		return
	end

	if not Pathfinder.isOnValidPath() then
		return
	end

	if not self.cooldownTimer:isElapsed(3) then
		return
	end

	local eyeOrigin = LocalPlayer.getEyeOrigin()

	for _, enemy in pairs(AiUtility.enemies) do repeat
		local gunshots = self.playerGunshots[enemy.eid]

		if gunshots < self.gunfireSprayThreshold then
			break
		end

		local ray = self.playerBulletRays[enemy.eid]

		if eyeOrigin:getRayClosestPoint(ray[1], ray[2]):getDistance(eyeOrigin) > self.sprayRangeWithin then
			break
		end

		local angleToEnemy = eyeOrigin:getAngle(ray[1])
		local angleToNextPathNode = eyeOrigin:getAngle(Pathfinder.path.node.origin)
		local maxDiff = angleToEnemy:getMaxDiff(angleToNextPathNode)

		if maxDiff > 90 then
			return
		end

		local skeleton = LocalPlayer:getHitboxPositions()
		local isVisible = false
		local enemyEyeOrigin = ray[1]
		local predictedEnemyEyeOrigin = enemyEyeOrigin:offsetByVector(enemy:m_vecVelocity() * 0.15)

		for _, vertex in pairs(skeleton) do
			local traceEnemyEyeOrigin = Trace.getLineToPosition(enemyEyeOrigin, vertex, AiUtility.traceOptionsVisible, "AiRoutineHandleGunfireAvoidance.think<FindVisibleLocalPlayerHitbox>")
			local tracePredictedEnemyEyeOrigin = Trace.getLineToPosition(predictedEnemyEyeOrigin, vertex, AiUtility.traceOptionsVisible, "AiRoutineHandleGunfireAvoidance.think<FindVisibleLocalPlayerHitbox>")

			if not traceEnemyEyeOrigin.isIntersectingGeometry or not tracePredictedEnemyEyeOrigin.isIntersectingGeometry then
				isVisible = true

				break
			end
		end

		if isVisible then
			break
		end

		Pathfinder.standStill()
	until true end
end

return Nyx.class("AiRoutineHandleGunfireAvoidance", AiRoutineHandleGunfireAvoidance, AiRoutineBase)
--}}}
