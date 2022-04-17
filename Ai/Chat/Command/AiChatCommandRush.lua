--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandRush
--- @class AiChatCommandRush : AiChatCommand
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

    ai.commands.go:invoke(ai, sender, "t")
end

return Nyx.class("AiChatCommandRush", AiChatCommandRush, AiChatCommand)
--}}}
