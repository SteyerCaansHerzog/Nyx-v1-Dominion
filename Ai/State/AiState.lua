--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Enums
--- @class AiPriority
local AiPriority = {
    IGNORE = -1,
    SWEEP = 1,
    DEFEND = 2,
    PUSH = 3,
    WATCH = 4,
    PLANT_PASSIVE = 5,
    FLASHBANG = 6,
    MOLOTOV = 7,
    SMOKE = 8,
    HE_GRENADE = 9,
    INTERACT_WITH_CHICKEN = 10,
    PLANT_IGNORE_NADES = 11,
    RUSH = 12,
    PATROL_BOMB = 13,
    DEFEND_ACTIVE = 14,
    ROUND_OVER = 15,
    PATROL = 16,
    PICKUP_WEAPON = 17,
    DEFUSE = 18,
    PICKUP_BOMB = 19,
    KNIFE_POINT = 20,
    CHECK = 21,
    PICKUP_DEFUSER = 22,
    BOOST = 23,
    IN_THROW = 24,
    DEFUSE_EXPEDITE = 25,
    DEFEND_DEFUSER = 26,
    ROUND_OVER_PICKUP_ITEMS = 27,
    EVACUATE = 28,
    ENGAGE_NEARBY = 29,
    PLANT_ACTIVE = 30,
    FOLLOW = 31,
    WAIT = 32,
    GRAFFITI = 33,
    BOOST_ACTIVE = 34,
    DYNAMIC_GRENADE = 35,
    DEFEND_EXPEDITE = 36,
    DEFUSE_ACTIVE = 37,
    SAVE_ROUND = 38,
    ENGAGE_VISIBLE = 39,
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
--- @field activate fun(self: AiState, ai: AiOptions): nil
--- @field assess fun(self: AiState, nodegraph: Nodegraph): number
--- @field lastPriority number
--- @field name string
--- @field nodegraph Nodegraph
--- @field priority AiPriority
--- @field priorityMap string[]
--- @field reactivate boolean
--- @field think fun(self: AiState, ai: AiOptions): nil
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
