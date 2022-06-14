--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBaseGrenadeBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
--}}}

--{{{ AiStateFlashbang
--- @class AiStateFlashbang : AiStateGrenadeBase
local AiStateFlashbang = {
    name = "Flashbang",
    priorityLineup = AiPriority.FLASHBANG_LINEUP,
    priorityThrow = AiPriority.FLASHBANG_THROW,
    cooldown = 4,
    nodeDefendCt = Node.grenadeFlashbangDefendCt,
    nodeDefendT = Node.grenadeFlashbangDefendT,
    nodeExecuteT = Node.grenadeFlashbangExecuteT,
    nodeRetakeCt = Node.grenadeFlashbangRetakeCt,
    weapons = {Weapons.FLASHBANG},
    equipFunction = LocalPlayer.equipFlashbang,
    rangeThreshold = 2000,
    isCheckingEnemiesRequired = true,
    requiredNodes = {
        Node.grenadeFlashbangDefendCt,
        Node.grenadeFlashbangDefendT,
        Node.grenadeFlashbangExecuteT,
        Node.grenadeFlashbangRetakeCt,
    }
}

--- @param fields AiStateFlashbang
--- @return AiStateFlashbang
function AiStateFlashbang:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("AiStateFlashbang", AiStateFlashbang, AiStateGrenadeBase)
--}}}
