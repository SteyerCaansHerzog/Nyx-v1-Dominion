--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
--}}}

--{{{ AiChatCommandDisconnect
--- @class AiChatCommandDisconnect : AiChatCommandBase
local AiChatCommandDisconnect = {
    cmd = "dc",
    requiredArgs = 0,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandDisconnect:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    Client.execute("disconnect")
end

return Nyx.class("AiChatCommandDisconnect", AiChatCommandDisconnect, AiChatCommandBase)
--}}}
