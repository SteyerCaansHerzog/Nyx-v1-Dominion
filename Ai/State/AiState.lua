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
    PLANT_PASSIVE = 4,
    FLASHBANG = 5,
    MOLOTOV = 6,
    SMOKE = 7,
    HE_GRENADE = 8,
    PLANT_IGNORE_NADES = 9,
    RUSH = 10,
    PATROL_BOMB = 11,
    ROUND_OVER = 12,
    PATROL = 13,
    INTERACT_WITH_CHICKEN = 14,
    PICKUP_WEAPON = 15,
    DEFUSE = 16,
    PICKUP_ITEM = 17,
    PICKUP_BOMB = 18,
    KNIFE_POINT = 19,
    CHECK = 20,
    PICKUP_DEFUSER = 21,
    BOOST = 22,
    IN_THROW = 23,
    PLANT_ACTIVE = 24,
    DEFUSE_EXPEDITE = 25,
    DEFEND_DEFUSER = 26,
    ROUND_OVER_IGNORE_BOMB = 27,
    ROUND_OVER_PICKUP_ITEMS = 28,
    EVACUATE = 29,
    AVOID_INFERNO = 30,
    ENGAGE_NEARBY = 31,
    GRAFFITI = 32,
    BOOST_ACTIVE = 33,
    ENGAGE_VISIBLE = 34,
    DEFUSE_COVERED = 35,
    PLANT_COVERED = 36,
    DROP = 37,
    EVADE = 38,
    ENGAGE_PANIC = 39,
    DEVELOPER = 40,
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
