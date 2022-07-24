--{{{ Definitions
--- @shape AiMap
--- @field gamemode string
--- @field bombsiteType string
--}}}

--- @type table<string, AiMap>
local AiMapInfo = {
	cs_agency = {
		gamemode = "hostage"
	},
	cs_office = {
		gamemode = "hostage",
	},
	de_ancient = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_cache = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_canals = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_cbble = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_dust2 = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_inferno = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_inferno_destruct = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_iris = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_mirage = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_nuke = {
		gamemode = "demolition",
		bombsiteType = "height"
	},
	de_overpass = {
		gamemode = "demolition",
		bombsiteType = "height"
	},
	de_train = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	de_vertigo = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	workshop_182604249_de_overgrown = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	workshop_1131494371_de_grind = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	workshop_1984383383_de_basalt = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	workshop_1986081493_de_mocha = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	workshop_2423926054_de_inferno_destruct = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	workshop_2484335179_de_outferno = {
		gamemode = "demolition",
		bombsiteType = "distance"
	},
	workshop_396269972_de_overpass_d = {
		gamemode = "demolition",
		bombsiteType = "distance"
	}
}

return AiMapInfo
