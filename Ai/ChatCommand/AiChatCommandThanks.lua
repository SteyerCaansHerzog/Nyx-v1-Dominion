--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandThanks
--- @class AiChatCommandThanks : AiChatCommandBase
--- @field isTaken boolean
local AiChatCommandThanks = {
    cmd = "thanks",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandThanks:invoke(ai, sender, args)
    if sender:is(ai.states.boostTeammate.boostPlayer) then
        ai.states.boostTeammate:reset()
    end
end

return Nyx.class("AiChatCommandThanks", AiChatCommandThanks, AiChatCommandBase)
--}}}
