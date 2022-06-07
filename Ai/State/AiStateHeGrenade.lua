--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGrenadeBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
--}}}

--{{{ AiStateHeGrenade
--- @class AiStateHeGrenade : AiStateGrenadeBase
local AiStateHeGrenade = {
    name = "HE Grenade",
    priority = AiPriority.HE_GRENADE_LINEUP,
    cooldown = 6,
    nodeDefendCt = Node.grenadeExplosiveDefendCt,
    nodeDefendT = Node.grenadeExplosiveDefendT,
    nodeExecuteT = Node.grenadeExplosiveExecuteT,
    nodeRetakeCt = Node.grenadeExplosiveRetakeCt,
    weapons = {Weapons.HE_GRENADE},
    equipFunction = LocalPlayer.equipHeGrenade,
    rangeThreshold = 2000,
    isCheckingEnemiesRequired = true,
}

--- @param fields AiStateHeGrenade
--- @return AiStateHeGrenade
function AiStateHeGrenade:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("AiStateHeGrenade", AiStateHeGrenade, AiStateGrenadeBase)
--}}}
