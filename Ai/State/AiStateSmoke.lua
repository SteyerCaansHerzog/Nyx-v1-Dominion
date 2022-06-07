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

--{{{ AiStateSmoke
--- @class AiStateSmoke : AiStateGrenadeBase
local AiStateSmoke = {
    name = "Smoke",
    priority = AiPriority.SMOKE_LINEUP,
    cooldown = 4,
    nodeDefendCt = Node.grenadeSmokeDefendCt,
    nodeDefendT = Node.grenadeSmokeDefendT,
    nodeExecuteT = Node.grenadeSmokeExecuteT,
    nodeRetakeCt = Node.grenadeSmokeRetakeCt,
    weapons = {Weapons.SMOKE},
    equipFunction = LocalPlayer.equipSmoke,
    rangeThreshold = 2000,
    isCheckingEnemiesRequired = false,
}

--- @param fields AiStateSmoke
--- @return AiStateSmoke
function AiStateSmoke:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("AiStateSmoke", AiStateSmoke, AiStateGrenadeBase)
--}}}
