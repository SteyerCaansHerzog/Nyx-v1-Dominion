--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandSkipMatch
--- @class AiChatCommandSkipMatch : AiChatCommand
local AiChatCommandSkipMatch = {
    cmd = "skipmatch",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandSkipMatch:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if ai.client then
        ai.client:skipMatch()
    end
end

return Nyx.class("AiChatCommandSkipMatch", AiChatCommandSkipMatch, AiChatCommand)
--}}}
