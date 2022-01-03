--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGrenadeBase"
--}}}
--{{{ AiStateMolotov
--- @class AiStateMolotov : AiStateGrenadeBase
local AiStateMolotov = {
    name = "Molotov",
    priority = AiState.priority.MOLOTOV,
    cooldown = 6,
    defendNode = "objectiveMolotovDefend",
    executeNode = "objectiveMolotovExecute",
    holdNode = "objectiveMolotovHold",
    weapons = {Weapons.MOLOTOV, Weapons.INCENDIARY},
    equipFunction = Client.equipMolotov
}

--- @return AiStateMolotov
function AiStateMolotov:new()
    return Nyx.new(self)
end

return Nyx.class("AiStateMolotov", AiStateMolotov, AiStateGrenadeBase)
--}}}
