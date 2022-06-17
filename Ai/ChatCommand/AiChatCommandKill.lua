--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandKill
--- @class AiChatCommandKill : AiChatCommandBase
local AiChatCommandKill = {
    cmd = "reload",
    requiredArgs = 0,
    isAdminOnly = true
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandKill:invoke(ai, sender, args)
    Client.execute("kill")
end

return Nyx.class("AiChatCommandKill", AiChatCommandKill, AiChatCommandBase)
--}}}
