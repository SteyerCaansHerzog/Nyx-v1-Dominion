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
		priority = 6,
		isPrimary = true
	},
	{
		classname = Weapons.G3SG1,
		priority = 6,
		isPrimary = true
	},
	{
		classname = Weapons.AK47,
		priority = 6,
		isPrimary = true
	},
	{
		classname = Weapons.AWP,
		priority = 6,
		isPrimary = true
	},
	{
		classname = Weapons.AUG,
		priority = 5,
		isPrimary = true
	},
	{
		classname = Weapons.M4A1,
		priority = 5,
		isPrimary = true
	},
	{
		classname = Weapons.SG553,
		priority = 4,
		isPrimary = true
	},
	{
		classname = Weapons.FAMAS,
		priority = 4,
		isPrimary = true
	},
	{
		classname = Weapons.GALIL,
		priority = 4,
		isPrimary = true
	},
	{
		classname = Weapons.BIZON,
		priority = 3,
		isPrimary = false
	},
	{
		classname = Weapons.MP7,
		priority = 3,
		isPrimary = false
	},
	{
		classname = Weapons.MP9,
		priority = 3,
		isPrimary = false
	},
	{
		classname = Weapons.P90,
		priority = 3,
		isPrimary = false
	},
	{
		classname = Weapons.UMP45,
		priority = 3,
		isPrimary = false
	},
	{
		classname = Weapons.MAC10,
		priority = 3,
		isPrimary = false
	},
	{
		classname = Weapons.NEGEV,
		priority = 3,
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
function AiWeaponInfo:__setup()
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

	self.dispositions = dispositions
	self.classnames = classnames
	self.primaries = primaries
end

return Nyx.class("WeaponInfo", AiWeaponInfo)
--}}}
