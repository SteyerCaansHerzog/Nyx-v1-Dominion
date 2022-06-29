--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandToggleAi
--- @class AiChatCommandToggleAi : AiChatCommandBase
local AiChatCommandToggleAi = {
    cmd = "ai",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai Ai
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandToggleAi:invoke(ai, sender, args)
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

        Logger.console(2, Localization.cmdToggleAiOff)

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandToggleAi", AiChatCommandToggleAi, AiChatCommandBase)
--}}}
