--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandVote
--- @class AiChatCommandVote : AiChatCommandBase
local AiChatCommandVote = {
    cmd = "vote",
    requiredArgs = 1,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandVote:invoke(ai, sender, args)
    local vote = args[1]

    if vote == "yes" then
        UserInput.execute("vote option1")

        return
    elseif vote == "no" then
        UserInput.execute("vote option2")

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandVote", AiChatCommandVote, AiChatCommandBase)
--}}}
