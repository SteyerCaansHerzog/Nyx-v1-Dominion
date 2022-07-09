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
local AiRoutineManageGear = {}

--- @param fields AiRoutineManageGear
--- @return AiRoutineManageGear
function AiRoutineManageGear:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineManageGear:__init()
	self.inspectTime = Math.getRandomFloat(30, 90)
	self.inspectTimer = Timer:new():startThenElapse()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineManageGear:think(cmd)
	self:manageKnife()
	self:manageWeaponInspection()
end

--- @return void
function AiRoutineManageGear:manageKnife()
	local isKnifeEquippable = true

	if AiUtility.isClientThreatenedMinor then
		isKnifeEquippable = false
	end

	local period = 3

	if AiUtility.enemiesAlive == 0 then
		period = 0.25
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

	if isKnifeEquippable then
		LocalPlayer.equipKnife()
	else
		if LocalPlayer:hasPrimary() then
			LocalPlayer.equipPrimary()
		else
			LocalPlayer.equipPistol()
		end
	end
end

--- @return void
function AiRoutineManageGear:manageWeaponInspection()
	if not self.inspectTimer:isElapsedThenRestart(self.inspectTime) then
		return
	end

	self.inspectTime = Math.getRandomFloat(30, 90)

	UserInput.execute("+lookatweapon")

	Client.onNextTick(function()
		UserInput.execute("-lookatweapon")
	end)
end

return Nyx.class("AiRoutineManageGear", AiRoutineManageGear, AiRoutineBase)
--}}}
