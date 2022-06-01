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

--{{{ AiStateHeGrenade
--- @class AiStateHeGrenade : AiStateGrenadeBase
local AiStateHeGrenade = {
    name = "HE Grenade",
    priority = AiPriority.HE_GRENADE_LINEUP,
    cooldown = 6,
    defendNode = "objectiveHeGrenadeDefend",
    executeNode = "objectivHeGrenadevExecute",
    holdNode = "objectiveHeGrenadeHold",
    retakeNode = "objectiveHeGrenadeRetake",
    weapons = {Weapons.HE_GRENADE},
    equipFunction = LocalPlayer.equipHeGrenade,
    rangeThreshold = 1500,
    isCheckingEnemiesRequired = true,
}

--- @param fields AiStateHeGrenade
--- @return AiStateHeGrenade
function AiStateHeGrenade:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("AiStateHeGrenade", AiStateHeGrenade, AiStateGrenadeBase)
--}}}
