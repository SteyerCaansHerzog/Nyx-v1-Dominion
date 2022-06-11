--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandRush
--- @class AiChatCommandRush : AiChatCommandBase
local AiChatCommandRush = {
    cmd = "rush",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandRush:invoke(ai, sender, args)
    if not LocalPlayer:isCounterTerrorist() then
        return self.ONLY_COUNTER_TERRORIST
    end

    if ai.reaper.isActive then
        return self.REAPER_IS_ACTIVE
    end

    ai.routines.buyGear:blockThisRound()

    Client.fireAfterRandom(0.5, 2, function()
        ai.routines.buyGear:buyEcoRush()
        ai.states.check:invoke("T")
    end)
end

return Nyx.class("AiChatCommandRush", AiChatCommandRush, AiChatCommandBase)
--}}}
