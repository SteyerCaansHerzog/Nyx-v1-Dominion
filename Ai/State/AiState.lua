--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Enums
--- @class AiPriority
local AiPriority = {
	IGNORE = -1,
	SWEEP = 1,
	DEFEND_GENERIC = 2,
	PUSH = 3,
	WATCH = 4,
	PLANT_GENERIC = 5,
	INTERACT_WITH_CHICKEN = 6,
	PATROL_BOMB = 7,
	DEFEND_PASSIVE = 8,
	ROUND_OVER = 9,
	PATROL = 10,
	PICKUP_WEAPON = 11,
	DEFUSE = 12,
	PICKUP_BOMB = 13,
	CHECK_SPAWN = 14,
	PICKUP_DEFUSER = 15,
	BOOST = 16,
	DEFUSE_EXPEDITE = 17,
	DEFEND_DEFUSER = 18,
	ROUND_OVER_PICKUP_ITEMS = 19,
	EVACUATE = 20,
	ENGAGE_PASSIVE = 21,
	PLANT_PASSIVE = 22,
	DEFEND_ACTIVE = 23,
	FLASHBANG = 24,
	MOLOTOV = 25,
	SMOKE = 26,
	HE_GRENADE = 27,
	PLANT_ACTIVE = 28,
	RUSH = 29,
	FOLLOW = 30,
	WAIT = 31,
	GRAFFITI = 32,
	BOOST_ACTIVE = 33,
	DEFEND_EXPEDITE = 34,
	DEFUSE_ACTIVE = 35,
	PLANT_EXPEDITE = 1,
	SAVE_ROUND = 36,
	ENGAGE_ACTIVE = 37,
	THROWING_GRENADE = 38,
	FLASHBANG_DYNAMIC = 39,
	AVOID_INFERNO = 40,
	ENGAGE_PANIC = 41,
	DEFUSE_COVERED = 42,
	PLANT_COVERED = 43,
	DROP = 44,
	EVADE = 45,
	DEFUSE_STICK = 46,
	DEVELOPER = 47,
}

local priorityMap = {}

for k, v in pairs(AiPriority) do
    priorityMap[v] = k
end
--}}}

--{{{ AiState
--- @class AiState : Class
--- @field activate fun(self: AiState, ai: AiOptions): void
--- @field assess fun(self: AiState, nodegraph: Nodegraph, ai: AiController): number
--- @field lastPriority number
--- @field name string
--- @field activity string
--- @field nodegraph Nodegraph
--- @field priority AiPriority
--- @field priorityMap string[]
--- @field reactivate boolean
--- @field think fun(self: AiState, ai: AiOptions): void
local AiState = {
    priority = AiPriority,
    priorityMap = priorityMap
}

--- @return AiState
function AiState:new()
    return Nyx.new(self)
end

return Nyx.class("AiState", AiState)
--}}}
