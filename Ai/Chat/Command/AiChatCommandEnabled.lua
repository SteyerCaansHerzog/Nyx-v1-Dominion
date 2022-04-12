--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
--}}}

--{{{ AiChatCommandEnabled
--- @class AiChatCommandEnabled : AiChatCommand
local AiChatCommandEnabled = {
    cmd = "ai",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandEnabled:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        Menu.enableAi:set(true)

        ai.reaper.isAiEnabled = true
        ai.antiAfkEnabled = false
    elseif toggle == "off" then
        Menu.enableAi:set(false)

        ai.reaper.isAiEnabled = false
        ai.antiAfkEnabled = false
    end
end

return Nyx.class("AiChatCommandEnabled", AiChatCommandEnabled, AiChatCommand)
--}}}
