--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Definitions
--- @shape AiWeapon
--- @field classname string
--- @field disposition number
--- @field isPrimary boolean
--}}}

--{{{ WeaponManifest
--- @type table<number, AiWeapon>
local WeaponManifest = {
	{
		classname = Weapons.SCAR20,
		disposition = 6,
		isPrimary = true
	},
	{
		classname = Weapons.G3SG1,
		disposition = 6,
		isPrimary = true
	},
	{
		classname = Weapons.AK47,
		disposition = 6,
		isPrimary = true
	},
	{
		classname = Weapons.AWP,
		disposition = 6,
		isPrimary = true
	},
	{
		classname = Weapons.AUG,
		disposition = 5,
		isPrimary = true
	},
	{
		classname = Weapons.M4A1,
		disposition = 5,
		isPrimary = true
	},
	{
		classname = Weapons.SG553,
		disposition = 4,
		isPrimary = true
	},
	{
		classname = Weapons.FAMAS,
		disposition = 4,
		isPrimary = true
	},
	{
		classname = Weapons.GALIL,
		disposition = 4,
		isPrimary = true
	},
	{
		classname = Weapons.BIZON,
		disposition = 3,
		isPrimary = false
	},
	{
		classname = Weapons.MP7,
		disposition = 3,
		isPrimary = false
	},
	{
		classname = Weapons.MP9,
		disposition = 3,
		isPrimary = false
	},
	{
		classname = Weapons.P90,
		disposition = 3,
		isPrimary = false
	},
	{
		classname = Weapons.UMP45,
		disposition = 3,
		isPrimary = false
	},
	{
		classname = Weapons.MAC10,
		disposition = 3,
		isPrimary = false
	},
	{
		classname = Weapons.NEGEV,
		disposition = 3,
		isPrimary = false
	},
}
--}}}

--{{{ AiWeaponInfo
--- @class AiWeaponInfo : Class
--- @field dispositions number[]
--- @field classnames string[]
--- @field primaries string[]
--- @field manifest AiWeapon[]
local AiWeaponInfo = {}

--- @return void
function AiWeaponInfo.__setup()
	local dispositions = {}
	local classnames = {}
	local primaries = {}

	for _, item in pairs(WeaponManifest) do
		dispositions[item.classname] = item.disposition

		if item.isPrimary then
			table.insert(primaries, item.classname)
		end

		table.insert(classnames, item.classname)
	end

	AiWeaponInfo.dispositions = dispositions
	AiWeaponInfo.classnames = classnames
	AiWeaponInfo.primaries = primaries
end

return Nyx.class("WeaponInfo", AiWeaponInfo)
--}}}
