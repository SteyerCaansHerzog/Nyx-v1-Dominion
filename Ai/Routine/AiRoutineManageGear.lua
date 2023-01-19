--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
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
	self.jiggleInspectDurationTimer = Timer:new():startThenElapse()
	self.jiggleIspectHoldTimer = Timer:new():startThenElapse()
	self.jiggleInspectDurationTime = Math.getRandomFloat(1, 6)
	self.jiggleIspectHoldTime = Math.getRandomFloat(0.2, 0.24)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineManageGear:think(cmd)
	self:manageKnife(cmd)
	self:manageWeaponInspection(cmd)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineManageGear:manageKnife(cmd)
	local isKnifeEquippable = true

	if AiUtility.isClientThreatenedMinor then
		isKnifeEquippable = false
	end

	local period = 3

	if AiUtility.enemiesAlive == 0 then
		period = 0.66
	end

	for _, dormantAt in pairs(AiUtility.dormantAt) do
		local dormantTime = Time.getRealtime() - dormantAt

		if dormantTime < period then
			isKnifeEquippable = false

			break
		end
	end

	if Pathfinder.isReplayingMovementRecording then
		isKnifeEquippable = true
	end

	if AiUtility.timeData.roundtime_elapsed < 6 then
		isKnifeEquippable = true
	end

	local isSwingingKnife = false

	if self.swingKnifeIntervalTimer:isElapsedThenRestart(self.swingKnifeIntervalTime) then
		self.swingKnifeIntervalTime = Math.getRandomFloat(10, 40)
		self.swingKnifeDurationTime = Math.getRandomFloat(0.1, 2)

		self.swingKnifeDurationTimer:restart()
	end

	if not self.swingKnifeDurationTimer:isElapsed(self.swingKnifeDurationTime) then
		isSwingingKnife = true
	end

	if isKnifeEquippable then
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
		self.jiggleInspectDurationTimer:restart()

		return
	end

	if self.isJiggleInspecting then
		if not self.jiggleInspectDurationTimer:isElapsed(self.jiggleInspectDurationTime) then
			if self.jiggleIspectHoldTimer:isElapsedThenRestart(self.jiggleIspectHoldTime) then
				self.jiggleIspectHoldTime = Math.getRandomFloat(0.2, 0.24)
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

			self.inspectTimer:restart()
		end
	else
		LocalPlayer.inspectWeapon()

		self.isJiggleInspecting = Math.getChance(1)
		self.inspectTime = Math.getRandomFloat(30, 90)

		self.inspectTimer:restart()
	end
end

return Nyx.class("AiRoutineManageGear", AiRoutineManageGear, AiRoutineBase)
--}}}
