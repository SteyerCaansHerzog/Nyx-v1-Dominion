--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
--}}}

--{{{ AiChatCommandAfk
--- @class AiChatCommandAfk : AiChatCommand
local AiChatCommandAfk = {
    cmd = "afk",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandAfk:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        ai.isAntiAfkEnabled = true

        Menu.enableAi:set(false)
    elseif toggle == "off" then
        ai.isAntiAfkEnabled = false

        Menu.enableAi:set(true)
    end
end

return Nyx.class("AiChatCommandAfk", AiChatCommandAfk, AiChatCommand)
--}}}
