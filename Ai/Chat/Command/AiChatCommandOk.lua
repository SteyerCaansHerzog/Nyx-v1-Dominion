--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandOk
--- @class AiChatCommandOk : AiChatCommand
--- @field isTaken boolean
local AiChatCommandOk = {
    cmd = "ok",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandOk:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    ai.commands.boost.isTaken = true
end

return Nyx.class("AiChatCommandOk", AiChatCommandOk, AiChatCommand)
--}}}
