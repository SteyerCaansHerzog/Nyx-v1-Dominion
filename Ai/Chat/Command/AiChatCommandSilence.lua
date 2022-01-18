--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiRadio = require "gamesense/Nyx/v1/Dominion/Ai/AiRadio"
--}}}

--{{{ AiChatCommandSilence
--- @class AiChatCommandSilence : AiChatCommand
local AiChatCommandSilence = {
    cmd = "silence",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return nil
function AiChatCommandSilence:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        AiRadio.enabled = false
    elseif toggle == "off" then
        AiRadio.enabled = true
    end
end

return Nyx.class("AiChatCommandSilence", AiChatCommandSilence, AiChatCommand)
--}}}
