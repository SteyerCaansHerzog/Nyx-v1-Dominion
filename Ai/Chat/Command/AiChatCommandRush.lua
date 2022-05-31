--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandRush
--- @class AiChatCommandRush : AiChatCommandBase
local AiChatCommandRush = {
    cmd = "rush",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandRush:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if not AiUtility.client:isCounterTerrorist() then
        return
    end

    if ai.reaper.isActive then
        return
    end

    ai.canBuyThisRound = false

    UserInput.execute("buy p250")

    ai.states.check:activate("t")
end

return Nyx.class("AiChatCommandRush", AiChatCommandRush, AiChatCommandBase)
--}}}
