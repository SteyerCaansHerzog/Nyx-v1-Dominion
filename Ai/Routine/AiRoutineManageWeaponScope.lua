--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
--}}}

--{{{ AiRoutineManageWeaponScope
--- @class AiRoutineManageWeaponScope : AiRoutineBase
--- @field unscopeTime number
--- @field unscopeTimer Timer
local AiRoutineManageWeaponScope = {}

--- @param fields AiRoutineManageWeaponScope
--- @return AiRoutineManageWeaponScope
function AiRoutineManageWeaponScope:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineManageWeaponScope:__init()
	self.unscopeTime = 1.6
	self.unscopeTimer = Timer:new():startThenElapse()

	Callbacks.weaponFire(function(e)
		if not e.player:isLocalPlayer() then
			return
		end

		if not LocalPlayer:isHoldingBoltActionRifle() then
			return
		end

		LocalPlayer.quickSwap()
	end)
end

--- @return void
function AiRoutineManageWeaponScope:whileBlocked()
	-- Reset unscope delay.
	self.unscopeTimer:restart()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineManageWeaponScope:think(cmd)
	local isScoped = LocalPlayer:m_bIsScoped() == 1

	if isScoped then
		self.unscopeTimer:ifPausedThenStart()
	else
		self.unscopeTimer:stop()
	end

	if isScoped and self.unscopeTimer:isElapsed(self.unscopeTime) then
		LocalPlayer.unscope(true)
	end
end

return Nyx.class("AiRoutineManageWeaponScope", AiRoutineManageWeaponScope, AiRoutineBase)
--}}}
