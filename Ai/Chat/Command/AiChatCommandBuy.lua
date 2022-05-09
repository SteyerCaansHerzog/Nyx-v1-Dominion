--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
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

    if ai.reaper.isActive then
        return
    end

    local toggle = args[1]

    if toggle then
        if toggle == "on" then
            ai.isAutoBuyEnabled = true
        elseif toggle == "off" then
            ai.isAutoBuyEnabled = false
        end
    else
        ai:autoBuy(true)
    end
end

return Nyx.class("AiChatCommandBuy", AiChatCommandBuy, AiChatCommand)
--}}}
