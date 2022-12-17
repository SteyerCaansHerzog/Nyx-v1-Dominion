--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGrenadeBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
--}}}

--{{{ AiStateSmoke
--- @class AiStateSmoke : AiStateGrenadeBase
local AiStateSmoke = {
    name = "Smoke",
    priorityLineup = AiPriority.SMOKE_LINEUP,
    priorityThrow = AiPriority.SMOKE_THROW,
    cooldown = 4,
    nodeDefendCt = Node.grenadeSmokeDefendCt,
    nodeDefendT = Node.grenadeSmokeDefendT,
    nodeExecuteT = Node.grenadeSmokeExecuteT,
    nodeRetakeCt = Node.grenadeSmokeRetakeCt,
    weapons = {Weapons.SMOKE},
    isSmoke = true,
    equipFunction = LocalPlayer.equipSmoke,
    rangeThreshold = 3000,
    isCheckingEnemiesRequired = false,
    requiredNodes = {
        Node.grenadeSmokeDefendCt,
        Node.grenadeSmokeDefendT,
        Node.grenadeSmokeExecuteT,
        Node.grenadeSmokeRetakeCt,
    }
}

--- @param fields AiStateSmoke
--- @return AiStateSmoke
function AiStateSmoke:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("AiStateSmoke", AiStateSmoke, AiStateGrenadeBase)
--}}}
