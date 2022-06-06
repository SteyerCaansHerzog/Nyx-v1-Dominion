--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandCmd
--- @class AiChatCommandCmd : AiChatCommandBase
local AiChatCommandCmd = {
    cmd = "cmd",
    requiredArgs = 0,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandCmd:invoke(ai, sender, args)
    local toggle = args[1]

    if toggle == "on" then
        MenuGroup.useChatCommands:set(true)

        return
    elseif toggle == "off" then
        MenuGroup.useChatCommands:set(false)

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandCmd", AiChatCommandCmd, AiChatCommandBase)
--}}}
