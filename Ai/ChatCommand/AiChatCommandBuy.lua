--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
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

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandBuy:invoke(ai, sender, args)
    if ai.reaper.isActive then
        return self.REAPER_IS_ACTIVE
    end

    local input = args[1]

    if input then
        if input == "on" then
            MenuGroup.enableAutoBuy:set(true)
        elseif input == "off" then
            MenuGroup.enableAutoBuy:set(false)
        elseif input == "reset" then
            ai.routines.buyGear:resetCustomItemList()
        else
            ai.routines.buyGear:setCustomItemList(input)
        end
    else
        Client.fireAfterRandom(0, 1, function()
            ai.routines.buyGear:buyGear()
            ai.routines.buyGear:processQueue()
        end)
    end
end

return Nyx.class("AiChatCommandBuy", AiChatCommandBuy, AiChatCommandBase)
--}}}
