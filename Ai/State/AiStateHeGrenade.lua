--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGrenadeBase"
--}}}

--{{{ AiStateHeGrenade
--- @class AiStateHeGrenade : AiStateGrenadeBase
local AiStateHeGrenade = {
    name = "HE Grenade",
    priority = AiState.priority.HE_GRENADE,
    cooldown = 6,
    usableAfter = 15,
    defendNode = "objectiveHeGrenadeDefend",
    executeNode = "objectivHeGrenadevExecute",
    holdNode = "objectiveHeGrenadeHold",
    weapons = {Weapons.HE_GRENADE},
    equipFunction = Client.equipHeGrenade
}

--- @return AiStateHeGrenade
function AiStateHeGrenade:new()
    return Nyx.new(self)
end

return Nyx.class("AiStateHeGrenade", AiStateHeGrenade, AiStateGrenadeBase)
--}}}
