--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
--}}}

--{{{ AiChatCommandScramble
--- @class AiChatCommandScramble : AiChatCommandBase
local AiChatCommandScramble = {
    cmd = "scramble",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandScramble:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local site = Client.getChance(2) and "a" or "b"

    Client.fireAfter(Client.getRandomFloat(1, 2), function()
        ai.states.defend:activate(ai, site, false, false)
    end)
end

return Nyx.class("AiChatCommandScramble", AiChatCommandScramble, AiChatCommandBase)
--}}}
