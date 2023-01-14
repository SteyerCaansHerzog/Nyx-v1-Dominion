--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiRoutineLookAwayFromFlashbangs
--- @class AiRoutineLookAwayFromFlashbangs : AiRoutineBase
--- @field activeFlashbang Entity
--- @field flashbangCollisionHull Vector3[]
--- @field flashbangDetonatesAfter number
--- @field flashbangsDetonateAt number[]
--- @field lookAngles Vector3
local AiRoutineLookAwayFromFlashbangs = {
	flashbangDetonatesAfter = 1.65
}

--- @param fields AiRoutineLookAwayFromFlashbangs
--- @return AiRoutineLookAwayFromFlashbangs
function AiRoutineLookAwayFromFlashbangs:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineLookAwayFromFlashbangs:__init()
	self.flashbangsDetonateAt = {}
	self.flashbangCollisionHull = Vector3:newBounds(Vector3.align.CENTER, 6)

	Callbacks.flashbangDetonate(function(e)
		self.flashbangsDetonateAt[e.entityid] = nil

		-- The active flashbang has detonated.
		if self.activeFlashbang and self.activeFlashbang.eid == e.entityid then
			self.activeFlashbang = nil
		end
	end)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineLookAwayFromFlashbangs:think(cmd)
	local eyeOrigin = LocalPlayer.getEyeOrigin()
	local cameraAngles = LocalPlayer.getCameraAngles()

	for _, flashbang in Entity.find(Weapons.GRENADE_PROJECTILE) do repeat
		-- Valve unfortunately suffers with a debilitating form of "not okay in the head".
		-- As such, flashbangs are grenade projectiles whose damage is "100".
		-- Don't fucking ask.
		if flashbang:m_flDamage() ~= 100 then
			break
		end

		local curtime = Time.getCurtime()

		-- Add all new flashbangs to the list specifying when they detonate.
		if not self.flashbangsDetonateAt[flashbang.eid] then
			self.flashbangsDetonateAt[flashbang.eid] = curtime + self.flashbangDetonatesAfter
		end

		-- We're already avoiding a flash.
		if self.activeFlashbang then
			break
		end

		-- Flash isn't a threat to us yet.
		-- Allows the AI to "time" a flash pop.
		if self.flashbangsDetonateAt[flashbang.eid] - curtime > 0.45 then
			break
		end

		local flashbangOrigin = flashbang:m_vecOrigin()

		local findPredictedFuturePositionTrace = Trace.getHullToPosition(
			flashbangOrigin,
			flashbangOrigin + flashbang:m_vecVelocity(),
			self.flashbangCollisionHull,
			AiUtility.traceOptionsPathfinding,
			"AiRoutineLookAwayFromFlashbangs.think<FindPredictedFlashbangPosition>"
		)

		local distance = eyeOrigin:getDistance(findPredictedFuturePositionTrace.endPosition)
		local fov = cameraAngles:getFov(eyeOrigin, findPredictedFuturePositionTrace.endPosition)

		-- Unlikely to be blinded.
		if distance > 1400 then
			break
		end

		-- Check if the flash is likely to blind us or not.
		if distance > 100 then
			if fov > 65 then
				break
			end
		else
			if fov > 110 then
				break
			end
		end

		local findIsVisibleToClientTrace = Trace.getLineToPosition(
			eyeOrigin,
			findPredictedFuturePositionTrace.endPosition,
			AiUtility.traceOptionsAttacking,
			"AiRoutineLookAwayFromFlashbangs.think<FindIsVisible>"
		)

		-- Flash is not visible.
		if findIsVisibleToClientTrace.isIntersectingGeometry  then
			break
		end

		self.activeFlashbang = flashbang
		self.lookAngles = eyeOrigin:getAngle(findPredictedFuturePositionTrace.endPosition):getBackward():getAngleFromForward()
	until true end

	if not self.activeFlashbang then
		return
	end

	VirtualMouse.isLookSpeedDelayed = false

	LocalPlayer.unscope()
	VirtualMouse.lookAlongAngle(self.lookAngles, 10, VirtualMouse.noise.moving, "Look away from flashbangs")
end

return Nyx.class("AiRoutineLookAwayFromFlashbangs", AiRoutineLookAwayFromFlashbangs, AiRoutineBase)
--}}}
