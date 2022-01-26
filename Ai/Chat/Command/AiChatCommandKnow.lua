--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiStateEngage = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEngage"
--}}}

--{{{ AiChatCommandKnow
--- @class AiChatCommandKnow : AiChatCommand
local AiChatCommandKnow = {
    cmd = "know",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandKnow:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    for _, enemy in Player.find(function(p)
        return p:isEnemy() and p:isAlive()
    end) do
        ai.states.engage:noticeEnemy(enemy, 4096)
    end
end

return Nyx.class("AiChatCommandKnow", AiChatCommandKnow, AiChatCommand)
--}}}
