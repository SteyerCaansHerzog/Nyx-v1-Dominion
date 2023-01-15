--{{{ Definitions
--- @shape MapInfo
--- @field gamemode string
--- @field bombsiteType string
--- @field bombsiteRotateRadius number
--}}}

--- @type table<string, MapInfo>
local MapInfo = {
	cs_office = {
		gamemode = "hostage",
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
	de_overpass = {
		gamemode = "demolition",
		bombsiteType = "height",
		bombsiteRotateRadius = 1400,
	},
	de_vertigo = {
		gamemode = "demolition",
		bombsiteType = "distance",
		bombsiteRotateRadius = 1400,
	}
}

return MapInfo
