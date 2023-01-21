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
    if ai.reaper.isActive then
        return self.REAPER_IS_ACTIVE
    end

    Client.fireAfterRandom(0, 1, function()
        if LocalPlayer:isCounterTerrorist() then
            ai.states.patrol:reset()
            ai.states.check:invoke("T")
            ai.routines.buyGear:ecoRush()
        end
    end)
end

return Nyx.class("AiChatCommandRush", AiChatCommandRush, AiChatCommandBase)
--}}}
