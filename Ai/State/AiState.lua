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
    PICKUP_WEAPON = 14,
    DEFUSE = 15,
    PICKUP_ITEM = 16,
    PICKUP_BOMB = 17,
    CHECK = 18,
    PICKUP_DEFUSER = 19,
    IN_THROW = 20,
    PLANT_ACTIVE = 21,
    DEFUSE_EXPEDITE = 22,
    DEFEND_DEFUSER = 23,
    ROUND_OVER_IGNORE_BOMB = 24,
    ROUND_OVER_PICKUP_ITEMS = 25,
    EVACUATE = 26,
    ENGAGE_NEARBY = 27,
    GRAFFITI = 28,
    ENGAGE_VISIBLE = 29,
    DEFUSE_COVERED = 30,
    PLANT_COVERED = 31,
    DROP = 32,
    EVADE = 33,
    ENGAGE_PANIC = 34,
}

local priorityMap = {}

for k, v in pairs(AiPriority) do
    priorityMap[v] = k
end
--}}}

--{{{ AiState
--- @class AiState : Class
--- @field activate fun(self: AiState, ai: AiOptions): void
--- @field assess fun(self: AiState, nodegraph: Nodegraph): number
--- @field canDelayActivation boolean
--- @field lastPriority number
--- @field name string
--- @field nodegraph Nodegraph
--- @field priority AiPriority
--- @field priorityMap string[]
--- @field reactivate boolean
--- @field think fun(self: AiState, ai: AiOptions): void
local AiState = {
    canDelayActivation = false,
    priority = AiPriority,
    priorityMap = priorityMap
}

--- @return AiState
function AiState:new()
    return Nyx.new(self)
end

return Nyx.class("AiState", AiState)
--}}}
