--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
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
    if not self:isValid(ai, sender, args) then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        MenuGroup.useChatCommands:set(true)
    elseif toggle == "off" then
        MenuGroup.useChatCommands:set(false)
    end
end

return Nyx.class("AiChatCommandCmd", AiChatCommandCmd, AiChatCommandBase)
--}}}
