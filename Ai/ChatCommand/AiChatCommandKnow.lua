--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandKnow
--- @class AiChatCommandKnow : AiChatCommandBase
local AiChatCommandKnow = {
    cmd = "know",
    requiredArgs = 0,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandKnow:invoke(ai, sender, args)
    for _, enemy in Player.find(function(p)
        return p:isEnemy() and p:isAlive()
    end) do
        ai.states.engage:noticeEnemy(enemy, 4096)
    end
end

return Nyx.class("AiChatCommandKnow", AiChatCommandKnow, AiChatCommandBase)
--}}}
