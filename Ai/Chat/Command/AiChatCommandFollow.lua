--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandFollow
--- @class AiChatCommandFollow : AiChatCommand
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
    if not self:isValid(ai, sender, args) then
        return
    end

    ai.voice.pack:speakAgreement()

    Client.fireAfter(Client.getRandomFloat(0.5, 1.5), function()
        if sender:isAlive() then
            ai.states.follow:follow(sender)
        end
    end)
end

return Nyx.class("AiChatCommandFollow", AiChatCommandFollow, AiChatCommand)
--}}}
