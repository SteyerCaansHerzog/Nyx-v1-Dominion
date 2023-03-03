--{{{ Dependencies
local CsgoWeapons = require "gamesense/csgo_weapons"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiThreats = require "gamesense/Nyx/v1/Dominion/Ai/AiThreats"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiRoutineManageWeaponReload
--- @class AiRoutineManageWeaponReload : AiRoutineBase
local AiRoutineManageWeaponReload = {}

--- @param fields AiRoutineManageWeaponReload
--- @return AiRoutineManageWeaponReload
function AiRoutineManageWeaponReload:new(fields)
	return Nyx.new(self, fields)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineManageWeaponReload:think(cmd)
	if not Table.isEmpty(AiUtility.visibleEnemies) then
		return
	end

	local weapon = LocalPlayer:getWeapon()

	if not weapon then
		return
	end

	-- Ratio at which the AI should reload its weapon.
	local ratio = AiThreats.threatLevel < AiThreats.threatLevels.MEDIUM and 0.99 or 0.9

	if AiThreats.threatLevel >= AiThreats.threatLevels.EXTREME then
		ratio = 0
	elseif AiThreats.threatLevel >= AiThreats.threatLevels.HIGH then
		ratio = 0.15
	elseif AiUtility.closestEnemy then
		local distance = LocalPlayer:getOrigin():getDistance(AiUtility.closestEnemy:getOrigin())

		if distance > 1500 then
			ratio = 0.75
		elseif distance > 1250 then
			ratio = 0.45
		elseif distance > 1000 then
			ratio = 0.25
		elseif distance > 500 then
			ratio = 0.2
		else
			ratio = 0.15
		end
	end

	local weaponData = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
	local ammo = weapon:m_iClip1()
	local maxAmmo = weaponData.primary_clip_size

	if ammo / maxAmmo > ratio then
		return
	end

	if LocalPlayer:isReloading() then
		self.ai.routines.manageGear:block()
		LocalPlayer.equipAvailableWeapon()
	end

	if LocalPlayer:isHoldingKnife()
		or LocalPlayer:isHoldingBomb()
		or LocalPlayer:isHoldingGrenade()
	then
		return
	end

	cmd.in_reload = true
end

return Nyx.class("AiRoutineManageWeaponReload", AiRoutineManageWeaponReload, AiRoutineBase)
--}}}
