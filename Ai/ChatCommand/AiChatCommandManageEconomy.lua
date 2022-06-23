--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandManageEconomy
--- @class AiChatCommandManageEconomy : AiChatCommandBase
local AiChatCommandManageEconomy = {
    cmd = "mecon",
    requiredArgs = 0,
    isAdminOnly = true,
    isValidIfSelfInvoked = true
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandManageEconomy:invoke(ai, sender, args)
    local toggle = args[1]

    if toggle == "on" then
        ai.routines.manageEconomy.isEnabled = true

        return
    elseif toggle == "off" then
        ai.routines.manageEconomy.isEnabled = false

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandManageEconomy", AiChatCommandManageEconomy, AiChatCommandBase)
--}}}
