--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandReload
--- @class AiChatCommandReload : AiChatCommandBase
local AiChatCommandReload = {
    cmd = "reload",
    requiredArgs = 0,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandReload:invoke(ai, sender, args)
    Client.reloadApi()
end

return Nyx.class("AiChatCommandReload", AiChatCommandReload, AiChatCommandBase)
--}}}
