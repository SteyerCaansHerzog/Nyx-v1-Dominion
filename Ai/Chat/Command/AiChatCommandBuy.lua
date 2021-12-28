--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandBuy
--- @class AiChatCommandBuy : AiChatCommand
local AiChatCommandBuy = {
    cmd = "buy",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandBuy:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    ai:autoBuy()
end

return Nyx.class("AiChatCommandBuy", AiChatCommandBuy, AiChatCommand)
--}}}
