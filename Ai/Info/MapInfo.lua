--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Definitions
--- @shape AiMap
--- @field gamemode string
--- @field siteDeterminator "distance" | "height"
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
		siteDeterminator = "distance"
	},
	de_cache = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_canals = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_cbble = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_dust2 = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_inferno = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_inferno_destruct = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_iris = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_mirage = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_nuke = {
		gamemode = "demolition",
		siteDeterminator = "height"
	},
	de_overpass = {
		gamemode = "demolition",
		siteDeterminator = "height"
	},
	de_train = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	de_vertigo = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	workshop_182604249_de_overgrown = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	workshop_1131494371_de_grind = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	workshop_1984383383_de_basalt = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	workshop_1986081493_de_mocha = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	workshop_2423926054_de_inferno_destruct = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
	workshop_2484335179_de_outferno = {
		gamemode = "demolition",
		siteDeterminator = "distance"
	},
}

return AiMapInfo
