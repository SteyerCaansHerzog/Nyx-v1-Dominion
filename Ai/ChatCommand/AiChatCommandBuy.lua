--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandBuy
--- @class AiChatCommandBuy : AiChatCommandBase
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
    if ai.reaper.isActive then
        return self.REAPER_IS_ACTIVE
    end

    local toggle = args[1]

    if toggle then
        if toggle == "on" then
            MenuGroup.enableAutoBuy:set(true)
        elseif toggle == "off" then
            MenuGroup.enableAutoBuy:set(false)
        end
    else
        ai.routines.buyGear:buyGear()
    end
end

return Nyx.class("AiChatCommandBuy", AiChatCommandBuy, AiChatCommandBase)
--}}}
