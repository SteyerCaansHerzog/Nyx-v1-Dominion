--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBaseGrenadeBase"
--}}}

--{{{ AiStateFlashbang
--- @class AiStateFlashbang : AiStateGrenadeBase
local AiStateFlashbang = {
    name = "Flashbang",
    priority = AiPriority.FLASHBANG_LINEUP,
    cooldown = 4,
    defendNode = "objectiveFlashbangDefend",
    executeNode = "objectiveFlashbangExecute",
    holdNode = "objectiveFlashbangHold",
    retakeNode = "objectiveFlashbangRetake",
    weapons = {Weapons.FLASHBANG},
    equipFunction = LocalPlayer.equipFlashbang,
    rangeThreshold = 1500,
    isCheckingEnemiesRequired = true,
}

--- @param fields AiStateFlashbang
--- @return AiStateFlashbang
function AiStateFlashbang:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("AiStateFlashbang", AiStateFlashbang, AiStateGrenadeBase)
--}}}
