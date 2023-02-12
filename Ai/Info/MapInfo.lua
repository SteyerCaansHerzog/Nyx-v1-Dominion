--{{{ Definitions
--- @shape MapInfo
--- @field gamemode string
--- @field bombsiteType string
--- @field bombsiteRotateRadius number
--}}}

--- @type table<string, MapInfo>
local MapInfo = {
	cs_agency = {
		gamemode = "hostage",
	},
	cs_office = {
		gamemode = "hostage",
	},
	de_anubis = {
		gamemode = "demolition",
		bombsiteType = "radius",
		bombsiteRotateRadius = 1400,
	},
	de_ancient = {
		gamemode = "demolition",
		bombsiteType = "radius",
		bombsiteRotateRadius = 1400,
	},
	de_cache = {
		gamemode = "demolition",
		bombsiteType = "radius",
		bombsiteRotateRadius = 1400,
	},
	de_dust2 = {
		gamemode = "demolition",
		bombsiteType = "radius",
		bombsiteRotateRadius = 1400,
	},
	de_inferno = {
		gamemode = "demolition",
		bombsiteType = "distance",
		bombsiteRotateRadius = 1400,
	},
	de_mirage = {
		gamemode = "demolition",
		bombsiteType = "distance",
		bombsiteRotateRadius = 1400,
	},
	de_nuke = {
		gamemode = "demolition",
		bombsiteType = "height",
		bombsiteRotateRadius = 1400,
	},
	de_overpass = {
		gamemode = "demolition",
		bombsiteType = "height",
		bombsiteRotateRadius = 1400,
	},
	de_train = {
		gamemode = "demolition",
		bombsiteType = "radius",
		bombsiteRotateRadius = 1400,
	},
	de_vertigo = {
		gamemode = "demolition",
		bombsiteType = "distance",
		bombsiteRotateRadius = 1400,
	},
}

return MapInfo
