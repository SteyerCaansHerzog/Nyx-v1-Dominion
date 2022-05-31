--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandEnabled
--- @class AiChatCommandEnabled : AiChatCommandBase
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
        -- Ignore the possessed Reaper client.
        if ai.reaper.isActive then
            return
        end

        MenuGroup.enableAi:set(true)

        ai.reaper.isAiEnabled = true
        ai.antiAfkEnabled = false
    elseif toggle == "off" then
        MenuGroup.enableAi:set(false)

        ai.reaper.isAiEnabled = false
        ai.antiAfkEnabled = false
    end
end

return Nyx.class("AiChatCommandEnabled", AiChatCommandEnabled, AiChatCommandBase)
--}}}
