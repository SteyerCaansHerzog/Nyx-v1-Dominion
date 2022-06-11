--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandSkipMatch
--- @class AiChatCommandSkipMatch : AiChatCommandBase
local AiChatCommandSkipMatch = {
    cmd = "skipmatch",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandSkipMatch:invoke(ai, sender, args)
    if ai.client and ai.client.allocation then
        ai.client:skipMatch()

        return
    end

    return self.LIVE_CLIENT_REQUIRED
end

return Nyx.class("AiChatCommandSkipMatch", AiChatCommandSkipMatch, AiChatCommandBase)
--}}}
