--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandAfk
--- @class AiChatCommandAfk : AiChatCommandBase
local AiChatCommandAfk = {
    cmd = "afk",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandAfk:invoke(ai, sender, args)
    local toggle = args[1]

    if toggle == "on" then
        MenuGroup.enableAi:set(false)

        ai.isAntiAfkEnabled = true

        return
    elseif toggle == "off" then
        MenuGroup.enableAi:set(true)

        ai.isAntiAfkEnabled = false

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandAfk", AiChatCommandAfk, AiChatCommandBase)
--}}}
