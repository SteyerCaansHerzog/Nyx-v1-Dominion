--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiThreats = require "gamesense/Nyx/v1/Dominion/Ai/AiThreats"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiRoutineManageGear
--- @class AiRoutineManageGear : AiRoutineBase
--- @field inspectTime number
--- @field inspectTimer Timer
--- @field isJiggleInspecting boolean
--- @field jiggleInspectDurationTime number
--- @field jiggleInspectDurationTimer Timer
--- @field jiggleInspectState boolean
--- @field jiggleIspectHoldTime number
--- @field jiggleIspectHoldTimer Timer
--- @field swingKnifeDurationTime number
--- @field swingKnifeDurationTimer Timer
--- @field swingKnifeIntervalTime number
--- @field swingKnifeIntervalTimer Timer
--- @field holdGunTimer Timer
--- @field isAllowedToKnifeWalls boolean
--- @field knifeWallsCooldownTimer Timer
--- @field knifeWallsCooldownDuration number
local AiRoutineManageGear = {}

--- @param fields AiRoutineManageGear
--- @return AiRoutineManageGear
function AiRoutineManageGear:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineManageGear:__init()
	self.inspectTime = Math.getRandomFloat(30, 90)
	self.inspectTimer = Timer:new():start()
	self.swingKnifeIntervalTimer = Timer:new():start()
	self.swingKnifeDurationTimer = Timer:new():startThenElapse()
	self.swingKnifeIntervalTime = Math.getRandomFloat(10, 40)
	self.swingKnifeDurationTime = Math.getRandomFloat(0.1, 2)
	self.isJiggleInspecting = true
	self.jiggleInspectState = false
	self.isAllowedToKnifeWalls = true
	self.jiggleInspectDurationTimer = Timer:new():startThenElapse()
	self.jiggleIspectHoldTimer = Timer:new():startThenElapse()
	self.holdGunTimer = Timer:new():startThenElapse()
	self.jiggleInspectDurationTime = Math.getRandomFloat(1, 6)
	self.jiggleIspectHoldTime = Math.getRandomFloat(0.45, 0.6)
	self.knifeWallsCooldownTimer = Timer:new():startThenElapse()
	self.knifeWallsCooldownDuration = Math.getRandomFloat(0.33, 12)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineManageGear:think(cmd)
	self:manageKnife(cmd)
	self:manageKnifeWalls()
	self:manageWeaponInspection(cmd)
end

--- @return void
function AiRoutineManageGear:manageKnifeWalls()
	if not self.isAllowedToKnifeWalls then
		self.isAllowedToKnifeWalls = true

		return
	end

	if not LocalPlayer:isHoldingKnife() then
		return
	end

	if AiUtility.closestTeammateDistance < 75 then
		return
	end

	if not self.knifeWallsCooldownTimer:isElapsedThenRestart(self.knifeWallsCooldownDuration) then
		return
	end

	local trace = Trace.getHullAlongCrosshair(Vector3:newBounds(Vector3.align.CENTER, 24, 24, 24), {
		skip = LocalPlayer.eid,
		distance = 24
	})

	if not trace.isIntersectingGeometry then
		return
	end

	self.knifeWallsCooldownDuration = Math.getRandomFloat(0.33, 12)

	VirtualMouse.fireWeapon()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineManageGear:manageKnife(cmd)
	local isKnifeEquippable = true

	if AiThreats.threatLevel >= AiThreats.threatLevels.LOW then
		isKnifeEquippable = false
	end

	if AiUtility.enemiesAlive > 0 and LocalPlayer:isReloading() then
		isKnifeEquippable = false
	end

	if Pathfinder.isReplayingMovementRecording then
		isKnifeEquippable = true
	end

	local isSwingingKnife = false

	if self.swingKnifeIntervalTimer:isElapsedThenRestart(self.swingKnifeIntervalTime) then
		self.swingKnifeIntervalTime = Math.getRandomFloat(10, 40)
		self.swingKnifeDurationTime = Math.getRandomFloat(0.1, 2)

		self.swingKnifeDurationTimer:start()
	end

	if not self.swingKnifeDurationTimer:isElapsed(self.swingKnifeDurationTime) then
		isSwingingKnife = true
	end

	if not isKnifeEquippable then
		self.holdGunTimer:start()
	end

	if isKnifeEquippable and self.holdGunTimer:isElapsed(1) then
		LocalPlayer.equipKnife()

		if isSwingingKnife and LocalPlayer:isHoldingKnife() and AiUtility.closestTeammate and AiUtility.closestTeammateDistance > 150 then
			cmd.in_attack = true
		end
	else
		if LocalPlayer:hasPrimary() then
			LocalPlayer.equipPrimary()
		else
			LocalPlayer.equipPistol()
		end
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineManageGear:manageWeaponInspection(cmd)
	local inspectTime = self.inspectTime

	if LocalPlayer:isHoldingKnife() then
		inspectTime = inspectTime * 0.25
	end

	if not self.inspectTimer:isElapsed(self.inspectTime) then
		self.jiggleInspectDurationTimer:start()

		return
	end

	if self.isJiggleInspecting then
		if not self.jiggleInspectDurationTimer:isElapsed(self.jiggleInspectDurationTime) then
			if self.jiggleIspectHoldTimer:isElapsedThenRestart(self.jiggleIspectHoldTime) then
				self.jiggleIspectHoldTime = Math.getRandomFloat(0.3, 0.45)
				self.jiggleInspectState = not self.jiggleInspectState

				if self.jiggleInspectState then
					LocalPlayer.inspectWeapon()
				else
					cmd.in_reload = true
				end
			end
		else
			self.jiggleInspectDurationTime = Math.getRandomFloat(1, 6)
			self.isJiggleInspecting = Math.getChance(1)
			self.inspectTime = Math.getRandomFloat(30, 90)

			self.inspectTimer:start()
		end
	else
		LocalPlayer.inspectWeapon()

		self.isJiggleInspecting = Math.getChance(1)
		self.inspectTime = Math.getRandomFloat(30, 90)

		self.inspectTimer:start()
	end
end

return Nyx.class("AiRoutineManageGear", AiRoutineManageGear, AiRoutineBase)
--}}}
