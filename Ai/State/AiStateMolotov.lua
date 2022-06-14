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
--{{{ AiStateMolotov
--- @class AiStateMolotov : AiStateGrenadeBase
local AiStateMolotov = {
    name = "Molotov",
    priorityLineup = AiPriority.MOLOTOV_LINEUP,
    priorityThrow = AiPriority.MOLOTOV_THROW,
    cooldown = 6,
    nodeDefendCt = Node.grenadeInfernoDefendCt,
    nodeDefendT = Node.grenadeInfernoDefendT,
    nodeExecuteT = Node.grenadeInfernoExecuteT,
    nodeRetakeCt = Node.grenadeInfernoRetakeCt,
    weapons = {Weapons.MOLOTOV, Weapons.INCENDIARY},
    equipFunction = LocalPlayer.equipMolotov,
    rangeThreshold = 2400,
    isCheckingEnemiesRequired = true,
    requiredNodes = {
        Node.grenadeInfernoDefendCt,
        Node.grenadeInfernoDefendT,
        Node.grenadeInfernoExecuteT,
        Node.grenadeInfernoRetakeCt,
    }
}

--- @param fields AiStateMolotov
--- @return AiStateMolotov
function AiStateMolotov:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("AiStateMolotov", AiStateMolotov, AiStateGrenadeBase)
--}}}
