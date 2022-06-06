--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
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
    local site = Math.getChance(2) and "a" or "b"

    Client.fireAfterRandom(1, 2, function()
        ai.states.defend:activate(ai, site, false, false)
    end)
end

return Nyx.class("AiChatCommandScramble", AiChatCommandScramble, AiChatCommandBase)
--}}}
