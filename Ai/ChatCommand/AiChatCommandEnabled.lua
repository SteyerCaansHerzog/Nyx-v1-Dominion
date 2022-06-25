--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandEnabled
--- @class AiChatCommandEnabled : AiChatCommandBase
local AiChatCommandEnabled = {
    cmd = "ai",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai Ai
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandEnabled:invoke(ai, sender, args)
    local toggle = args[1]

    if toggle == "on" then
        -- Ignore the possessed Reaper client.
        if ai.reaper.isActive then
            return
        end

        MenuGroup.enableAi:set(true)

        ai.reaper.isAiEnabled = true
        ai.antiAfkEnabled = false

        return
    elseif toggle == "off" then
        MenuGroup.enableAi:set(false)

        ai.reaper.isAiEnabled = false
        ai.antiAfkEnabled = false

        Logger.console(2, "The AI has been disabled. To re-enable the AI, use the '/ai on' chat command, or check 'Enable AI' in the menu.")

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandEnabled", AiChatCommandEnabled, AiChatCommandBase)
--}}}
