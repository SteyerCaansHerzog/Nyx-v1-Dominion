--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
--}}}

--{{{ AiChatCommandVote
--- @class AiChatCommandVote : AiChatCommandBase
local AiChatCommandVote = {
    cmd = "vote",
    requiredArgs = 1,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandVote:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local vote = args[1]

    if vote == "yes" then
        UserInput.execute("vote option1")
    elseif vote == "no" then
        UserInput.execute("vote option2")
    end
end

return Nyx.class("AiChatCommandVote", AiChatCommandVote, AiChatCommandBase)
--}}}
