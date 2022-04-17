--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGrenadeBase"
--}}}

--{{{ AiStateFlashbang
--- @class AiStateFlashbang : AiStateGrenadeBase
local AiStateFlashbang = {
    name = "Flashbang",
    priority = AiState.priority.FLASHBANG,
    cooldown = 4,
    defendNode = "objectiveFlashbangDefend",
    executeNode = "objectiveFlashbangExecute",
    holdNode = "objectiveFlashbangHold",
    weapons = {Weapons.FLASHBANG},
    equipFunction = Client.equipFlashbang,
    rangeThreshold = 1500
}

--- @return AiStateFlashbang
function AiStateFlashbang:new()
    return Nyx.new(self)
end

return Nyx.class("AiStateFlashbang", AiStateFlashbang, AiStateGrenadeBase)
--}}}
