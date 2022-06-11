--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandOk
--- @class AiChatCommandOk : AiChatCommandBase
--- @field isTaken boolean
local AiChatCommandOk = {
    cmd = "ok",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandOk:invoke(ai, sender, args)
    ai.commands.boost.isTaken = true
end

return Nyx.class("AiChatCommandOk", AiChatCommandOk, AiChatCommandBase)
--}}}
