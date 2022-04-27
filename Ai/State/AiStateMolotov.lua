--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGrenadeBase"
--}}}
--{{{ AiStateMolotov
--- @class AiStateMolotov : AiStateGrenadeBase
local AiStateMolotov = {
    name = "Molotov",
    priority = AiPriority.MOLOTOV_LINEUP,
    cooldown = 6,
    defendNode = "objectiveMolotovDefend",
    executeNode = "objectiveMolotovExecute",
    retakeNode = "objectiveMolotovRetake",
    holdNode = "objectiveMolotovHold",
    weapons = {Weapons.MOLOTOV, Weapons.INCENDIARY},
    equipFunction = Client.equipMolotov,
    rangeThreshold = 1200
}

--- @param fields AiStateMolotov
--- @return AiStateMolotov
function AiStateMolotov:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("AiStateMolotov", AiStateMolotov, AiStateGrenadeBase)
--}}}
