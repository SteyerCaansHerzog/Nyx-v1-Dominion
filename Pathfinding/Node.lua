--{{{ Dependencies
local Color = require "gamesense/Nyx/v1/Api/Color"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ NodeType
--- @class NodeType
local NodeType = {
    RUN = 1,
    CROUCH = 2,
    JUMP = 3,
    SHOOT = 4,
    CROUCH_SHOOT = 5,
    FAKE_DUCK = 6,
    ONE_WAY = 7,
    ONE_WAY_DUCK = 8,
    ONE_WAY_FAKE_DUCK = 9,
    DOOR = 10,
    GOAL = 11,
    BOMB = 12,
    ENEMY = 13,
    OBJECTIVE_A = 14,
    OBJECTIVE_B = 15,
    OBJECTIVE_HOSTAGE = 16,
    MAP_MIDDLE = 17,
    CT_SPAWN = 18,
    T_SPAWN = 19,
    HIDE = 20,
    DEFEND = 21,
    START = 22,
    GAP = 23,
    PLANT = 24,
    HOLD = 25,
    PUSH = 26,
    SMOKE_DEFEND = 27,
    SMOKE_EXECUTE = 28,
    FLASHBANG_DEFEND = 29,
    FLASHBANG_EXECUTE = 30,
    MOLOTOV_DEFEND = 31,
    MOLOTOV_EXECUTE = 32,
    HE_GRENADE_DEFEND = 33,
    HE_GRENADE_EXECUTE = 34,
    RUSH = 35,
    CHOKE = 36,
    CAUTION = 37,
    CHECK = 38,
    DEFEND_DEFUSER = 39,
    SMOKE_HOLD = 40,
    FLASHBANG_HOLD = 41,
    MOLOTOV_HOLD = 42,
    HE_GRENADE_HOLD = 43,
    BLOCK = 44,
    WATCH_RIFLE = 45,
    WATCH_SNIPER = 46,
    SMOKE_RETAKE = 47,
    MOLOTOV_RETAKE = 48,
    HE_GRENADE_RETAKE = 49,
    PUSH_HOSTAGE = 50,
    HOSTAGE = 51,
    DEFEND_HOSTAGE = 52,
}

local NodeDirectional = {
    [NodeType.SHOOT] = true,
    [NodeType.CROUCH_SHOOT] = true,
    [NodeType.FAKE_DUCK] = true,
    [NodeType.ONE_WAY] = true,
    [NodeType.ONE_WAY_DUCK] = true,
    [NodeType.ONE_WAY_FAKE_DUCK] = true,
    [NodeType.DOOR] = true,
    [NodeType.HIDE] = true,
    [NodeType.DEFEND] = true,
    [NodeType.HOLD] = true,
    [NodeType.SMOKE_DEFEND] = true,
    [NodeType.SMOKE_EXECUTE] = true,
    [NodeType.FLASHBANG_DEFEND] = true,
    [NodeType.FLASHBANG_EXECUTE] = true,
    [NodeType.MOLOTOV_DEFEND] = true,
    [NodeType.MOLOTOV_EXECUTE] = true,
    [NodeType.HE_GRENADE_DEFEND] = true,
    [NodeType.HE_GRENADE_EXECUTE] = true,
    [NodeType.CHECK] = true,
    [NodeType.DEFEND_DEFUSER] = true,
    [NodeType.SMOKE_HOLD] = true,
    [NodeType.FLASHBANG_HOLD] = true,
    [NodeType.MOLOTOV_HOLD] = true,
    [NodeType.HE_GRENADE_HOLD] = true,
    [NodeType.PLANT] = true,
    [NodeType.WATCH_RIFLE] = true,
    [NodeType.WATCH_SNIPER] = true,
    [NodeType.SMOKE_RETAKE] = true,
    [NodeType.MOLOTOV_RETAKE] = true,
    [NodeType.HE_GRENADE_RETAKE] = true,
    [NodeType.DEFEND_HOSTAGE] = true,
}

local NodePaired = {
    [NodeType.DEFEND] = true,
    [NodeType.HOLD] = true,
    [NodeType.DEFEND_DEFUSER] = true,
    [NodeType.DEFEND_HOSTAGE] = true
}

local NodeTypeName = {
    [NodeType.RUN] = "Run",
    [NodeType.CROUCH] = "Crouch",
    [NodeType.JUMP] = "Jump",
    [NodeType.SHOOT] = "Shoot",
    [NodeType.CROUCH_SHOOT] = "Crouch-Shoot",
    [NodeType.FAKE_DUCK] = "Fake-Duck",
    [NodeType.ONE_WAY] = "One-Way",
    [NodeType.ONE_WAY_DUCK] = "One-Way Duck",
    [NodeType.ONE_WAY_FAKE_DUCK] = "One-Way Fake-Duck",
    [NodeType.DOOR] = "Door",
    [NodeType.GOAL] = "Goal",
    [NodeType.BOMB] = "Bomb",
    [NodeType.ENEMY] = "Enemy",
    [NodeType.OBJECTIVE_A] = "Objective A",
    [NodeType.OBJECTIVE_B] = "Objective B",
    [NodeType.OBJECTIVE_HOSTAGE] = "Objective Hostage",
    [NodeType.MAP_MIDDLE] = "Map Middle",
    [NodeType.CT_SPAWN] = "CT Spawn",
    [NodeType.T_SPAWN] = "T Spawn",
    [NodeType.HIDE] = "Hide",
    [NodeType.DEFEND] = "Defend",
    [NodeType.START] = "Start",
    [NodeType.GAP] = "Gap",
    [NodeType.PLANT] = "Plant",
    [NodeType.HOLD] = "Hold",
    [NodeType.PUSH] = "Push",
    [NodeType.SMOKE_DEFEND] = "Smoke (Defend)",
    [NodeType.SMOKE_EXECUTE] = "Smoke (Execute)",
    [NodeType.FLASHBANG_DEFEND] = "Flashbang (Defend)",
    [NodeType.FLASHBANG_EXECUTE] = "Flashbang (Execute)",
    [NodeType.MOLOTOV_DEFEND] = "Molotov (Defend)",
    [NodeType.MOLOTOV_EXECUTE] = "Molotov (Execute)",
    [NodeType.HE_GRENADE_DEFEND] = "HE Grenade (Defend)",
    [NodeType.HE_GRENADE_EXECUTE] = "HE Grenade (Execute)",
    [NodeType.RUSH] = "Rush",
    [NodeType.CHOKE] = "Choke",
    [NodeType.CAUTION] = "Caution",
    [NodeType.CHECK] = "Check",
    [NodeType.DEFEND_DEFUSER] = "Defend Defuser",
    [NodeType.SMOKE_HOLD] = "Smoke (Hold)",
    [NodeType.FLASHBANG_HOLD] = "Flashbang (Hold)",
    [NodeType.MOLOTOV_HOLD] = "Molotov (Hold)",
    [NodeType.HE_GRENADE_HOLD] = "HE Grenade (Hold)",
    [NodeType.BLOCK] = "Block",
    [NodeType.WATCH_RIFLE] = "Watch (Rifle)",
    [NodeType.WATCH_SNIPER] = "Watch (Sniper)",
    [NodeType.SMOKE_RETAKE] = "Smoke (Retake)",
    [NodeType.MOLOTOV_RETAKE] = "Molotov (Retake)",
    [NodeType.HE_GRENADE_RETAKE] = "HE Grenade (Retake)",
    [NodeType.PUSH_HOSTAGE] = "Push (Hostage)",
    [NodeType.HOSTAGE] = "Hostage",
    [NodeType.DEFEND_HOSTAGE] = "Defend (Hostage)",
}

--- @type Color[]
local NodeTypeColor = {
    [NodeType.RUN] = Color:hsla(0, 0, 0.6),
    [NodeType.CROUCH] = Color:hsla(50, 0.8, 0.6),
    [NodeType.JUMP] = Color:hsla(120, 0.8, 0.6),
    [NodeType.SHOOT] = Color:hsla(150, 0.8, 0.6),
    [NodeType.CROUCH_SHOOT] = Color:hsla(170, 0.8, 0.6),
    [NodeType.FAKE_DUCK] = Color:hsla(80, 0.8, 0.6),
    [NodeType.ONE_WAY] = Color:hsla(260, 0.8, 0.8),
    [NodeType.ONE_WAY_DUCK] = Color:hsla(260, 0.8, 0.8),
    [NodeType.ONE_WAY_FAKE_DUCK] = Color:hsla(260, 0.8, 0.8),
    [NodeType.DOOR] = Color:hsla(150, 0.8, 0.6),
    [NodeType.GOAL] = Color:hsla(20, 0.8, 0.6),
    [NodeType.BOMB] = Color:hsla(0, 0.8, 0.6),
    [NodeType.ENEMY] = Color:hsla(0, 0.8, 0.6),
    [NodeType.OBJECTIVE_A] = Color:hsla(340, 0.8, 0.6),
    [NodeType.OBJECTIVE_B] = Color:hsla(340, 0.8, 0.6),
    [NodeType.OBJECTIVE_HOSTAGE] = Color:hsla(340, 0.8, 0.6),
    [NodeType.MAP_MIDDLE] = Color:hsla(340, 0.8, 0.6),
    [NodeType.CT_SPAWN] = Color:hsla(210, 0.8, 0.6),
    [NodeType.T_SPAWN] = Color:hsla(30, 0.8, 0.6),
    [NodeType.HIDE] = Color:hsla(50, 0.8, 0.6),
    [NodeType.DEFEND] = Color:hsla(65, 0.8, 0.6),
    [NodeType.START] = Color:hsla(20, 0.8, 0.6),
    [NodeType.GAP] = Color:hsla(100, 0.8, 0.6),
    [NodeType.PLANT] = Color:hsla(350, 0.8, 0.8),
    [NodeType.HOLD] = Color:hsla(55, 0.8, 0.6),
    [NodeType.PUSH] = Color:hsla(320, 0.8, 0.7),
    [NodeType.SMOKE_DEFEND] = Color:hsla(0, 0.0, 0.9),
    [NodeType.SMOKE_EXECUTE] = Color:hsla(0, 0.0, 0.9),
    [NodeType.FLASHBANG_DEFEND] = Color:hsla(200, 0.66, 0.85),
    [NodeType.FLASHBANG_EXECUTE] = Color:hsla(200, 0.66, 0.85),
    [NodeType.MOLOTOV_DEFEND] = Color:hsla(30, 0.66, 0.85),
    [NodeType.MOLOTOV_EXECUTE] = Color:hsla(30, 0.66, 0.85),
    [NodeType.HE_GRENADE_DEFEND] = Color:hsla(0, 0.66, 0.85),
    [NodeType.HE_GRENADE_EXECUTE] = Color:hsla(0, 0.66, 0.85),
    [NodeType.RUSH] = Color:hsla(290, 0.8, 0.7),
    [NodeType.CHOKE] = Color:hsla(275, 0.8, 0.7),
    [NodeType.CAUTION] = Color:hsla(0, 0.8, 0.7),
    [NodeType.CHECK] = Color:hsla(230, 0.8, 0.8),
    [NodeType.DEFEND_DEFUSER] = Color:hsla(75, 0.8, 0.6),
    [NodeType.SMOKE_HOLD] = Color:hsla(0, 0.0, 0.9),
    [NodeType.FLASHBANG_HOLD] = Color:hsla(200, 0.66, 0.85),
    [NodeType.MOLOTOV_HOLD] = Color:hsla(30, 0.66, 0.85),
    [NodeType.HE_GRENADE_HOLD] = Color:hsla(0, 0.66, 0.85),
    [NodeType.BLOCK] = Color:hsla(0, 0.9, 0.6),
    [NodeType.WATCH_RIFLE] = Color:hsla(25, 0.4, 0.45),
    [NodeType.WATCH_SNIPER] = Color:hsla(25, 0.4, 0.45),
    [NodeType.SMOKE_RETAKE] = Color:hsla(0, 0.0, 0.9),
    [NodeType.MOLOTOV_RETAKE] = Color:hsla(30, 0.66, 0.85),
    [NodeType.HE_GRENADE_RETAKE] = Color:hsla(0, 0.66, 0.85),
    [NodeType.PUSH_HOSTAGE] = Color:hsla(320, 0.8, 0.7),
    [NodeType.HOSTAGE] = Color:hsla(340, 0.8, 0.6),
    [NodeType.DEFEND_HOSTAGE] = Color:hsla(65, 0.8, 0.6),
}

local NodeTypeCode = {
    [NodeType.RUN] = "",
    [NodeType.CROUCH] = "DUCK",
    [NodeType.JUMP] = "JUMP",
    [NodeType.SHOOT] = "SHOOT",
    [NodeType.CROUCH_SHOOT] = "DUCK-SHOOT",
    [NodeType.FAKE_DUCK] = "FAKE-DUCK",
    [NodeType.ONE_WAY] = "1-WAY",
    [NodeType.ONE_WAY_DUCK] = "1-WAY DUCK",
    [NodeType.ONE_WAY_FAKE_DUCK] = "1-WAY FAKE-DUCK",
    [NodeType.DOOR] = "DOOR",
    [NodeType.GOAL] = "GOAL",
    [NodeType.BOMB] = "BOMB",
    [NodeType.ENEMY] = "ENEMY",
    [NodeType.OBJECTIVE_A] = "A SITE",
    [NodeType.OBJECTIVE_B] = "B SITE",
    [NodeType.OBJECTIVE_HOSTAGE] = "HOSTAGE",
    [NodeType.MAP_MIDDLE] = "MIDDLE",
    [NodeType.CT_SPAWN] = "CT SPAWN",
    [NodeType.T_SPAWN] = "T SPAWN",
    [NodeType.HIDE] = "HIDE",
    [NodeType.DEFEND] = "DEFEND",
    [NodeType.START] = "START",
    [NodeType.GAP] = "GAP",
    [NodeType.PLANT] = "PLANT",
    [NodeType.HOLD] = "HOLD",
    [NodeType.PUSH] = "PUSH",
    [NodeType.SMOKE_DEFEND] = "SMOKE (DEFEND)",
    [NodeType.SMOKE_EXECUTE] = "SMOKE (EXECUTE)",
    [NodeType.FLASHBANG_DEFEND] = "FLASHBANG (DEFEND)",
    [NodeType.FLASHBANG_EXECUTE] = "FLASHBANG (EXECUTE)",
    [NodeType.MOLOTOV_DEFEND] = "MOLOTOV (DEFEND)",
    [NodeType.MOLOTOV_EXECUTE] = "MOLOTOV (EXECUTE)",
    [NodeType.HE_GRENADE_DEFEND] = "GRENADE (DEFEND)",
    [NodeType.HE_GRENADE_EXECUTE] = "GRENADE (EXECUTE)",
    [NodeType.RUSH] = "RUSH",
    [NodeType.CHOKE] = "CHOKE",
    [NodeType.CAUTION] = "CAUTION",
    [NodeType.CHECK] = "CHECK",
    [NodeType.DEFEND_DEFUSER] = "DEFEND DEFUSER",
    [NodeType.SMOKE_HOLD] = "SMOKE (HOLD)",
    [NodeType.FLASHBANG_HOLD] = "FLASHBANG (HOLD)",
    [NodeType.MOLOTOV_HOLD] = "MOLOTOV (HOLD)",
    [NodeType.HE_GRENADE_HOLD] = "GRENADE (HOLD)",
    [NodeType.BLOCK] = "BLOCK",
    [NodeType.WATCH_RIFLE] = "WATCH (R)",
    [NodeType.WATCH_SNIPER] = "WATCH (S)",
    [NodeType.SMOKE_RETAKE] = "SMOKE (RETAKE)",
    [NodeType.MOLOTOV_RETAKE] = "MOLOTOV (RETAKE)",
    [NodeType.HE_GRENADE_RETAKE] = "GRENADE (RETAKE)",
    [NodeType.PUSH_HOSTAGE] = "PUSH (HOSTAGE)",
    [NodeType.HOSTAGE] = "HOSTAGE",
    [NodeType.DEFEND_HOSTAGE] = "DEFEND (HOSTAGE)",
}
--}}}

--{{{ Node
--- @class Node : Class
--- @field id number
--- @field origin Vector3
--- @field connections Node[]
--- @field type number
--- @field active boolean
--- @field direction Angle
--- @field site string
--- @field pair Node
--- @field offset number
---
--- @field types NodeType
--- @field typesDirectional boolean[]
--- @field typesPaired boolean[]
--- @field typesColor Color[]
--- @field typesCode string[]
--- @field typesName string[]
local Node = {
    types = NodeType,
    typesDirectional = NodeDirectional,
    typesPaired = NodePaired,
    typesColor = NodeTypeColor,
    typesCode = NodeTypeCode,
    typesName = NodeTypeName

}

--- @param fields Node
--- @return Node
function Node:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function Node:__init()
    self.active = true
end

return Nyx.class("Node", Node)
--}}}