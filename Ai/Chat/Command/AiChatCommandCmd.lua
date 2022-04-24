--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
--}}}

--{{{ AiChatCommandCmd
--- @class AiChatCommandCmd : AiChatCommand
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
        Menu.useChatCommands:set(true)
    elseif toggle == "off" then
        Menu.useChatCommands:set(false)
    end
end

return Nyx.class("AiChatCommandCmd", AiChatCommandCmd, AiChatCommand)
--}}}
