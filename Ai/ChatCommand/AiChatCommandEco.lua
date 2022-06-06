--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandEco
--- @class AiChatCommandEco : AiChatCommandBase
local AiChatCommandEco = {
    cmd = "eco",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandEco:invoke(ai, sender, args)
    ai.routines.buyGear:blockThisRound()
end

return Nyx.class("AiChatCommandEco", AiChatCommandEco, AiChatCommandBase)
--}}}
