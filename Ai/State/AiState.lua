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
    PLANT_ACTIVE = 25,
    DEFUSE_EXPEDITE = 26,
    DEFEND_DEFUSER = 27,
    ROUND_OVER_IGNORE_BOMB = 28,
    ROUND_OVER_PICKUP_ITEMS = 29,
    EVACUATE = 30,
    AVOID_INFERNO = 31,
    ENGAGE_NEARBY = 32,
    FOLLOW = 33,
    WAIT = 34,
    GRAFFITI = 35,
    BOOST_ACTIVE = 36,
    DYNAMIC_GRENADE = 37,
    ENGAGE_VISIBLE = 38,
    DEFUSE_COVERED = 39,
    PLANT_COVERED = 40,
    DROP = 41,
    EVADE = 42,
    ENGAGE_PANIC = 43,
    DEVELOPER = 44,
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
