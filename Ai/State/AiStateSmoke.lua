--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGrenadeBase"
--}}}

--{{{ AiStateSmoke
--- @class AiStateSmoke : AiStateGrenadeBase
local AiStateSmoke = {
    name = "Smoke",
    priority = AiState.priority.SMOKE,
    cooldown = 4,
    defendNode = "objectiveSmokeDefend",
    executeNode = "objectiveSmokeExecute",
    holdNode = "objectiveSmokeHold",
    weapons = {Weapons.SMOKE},
    equipFunction = Client.equipSmoke,
}

--- @return AiStateSmoke
function AiStateSmoke:new()
    return Nyx.new(self)
end

return Nyx.class("AiStateSmoke", AiStateSmoke, AiStateGrenadeBase)
--}}}
