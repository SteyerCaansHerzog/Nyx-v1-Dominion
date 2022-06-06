--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandFollow
--- @class AiChatCommandFollow : AiChatCommandBase
--- @field isTaken boolean
local AiChatCommandFollow = {
    cmd = "follow",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandFollow:invoke(ai, sender, args)
    if not sender:isAlive() then
        return self.SENDER_IS_DEAD
    end

    if not LocalPlayer:isAlive() then
        return self.CLIENT_IS_DEAD
    end

    ai.voice.pack:speakAgreement()

    Client.fireAfterRandom(0.5, 1.5, function()
        if sender:isAlive() then
            ai.states.follow:follow(sender)
        end
    end)
end

return Nyx.class("AiChatCommandFollow", AiChatCommandFollow, AiChatCommandBase)
--}}}
