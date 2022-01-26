--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandReload
--- @class AiChatCommandReload : AiChatCommand
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
    if not self:isValid(ai, sender, args) then
        return
    end

    Client.reloadApi()
end

return Nyx.class("AiChatCommandReload", AiChatCommandReload, AiChatCommand)
--}}}
