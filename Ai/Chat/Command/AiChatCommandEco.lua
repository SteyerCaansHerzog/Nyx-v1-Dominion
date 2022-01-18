--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandEco
--- @class AiChatCommandEco : AiChatCommand
local AiChatCommandEco = {
    cmd = "eco",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return nil
function AiChatCommandEco:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    ai.canBuyThisRound = false
end

return Nyx.class("AiChatCommandEco", AiChatCommandEco, AiChatCommand)
--}}}
