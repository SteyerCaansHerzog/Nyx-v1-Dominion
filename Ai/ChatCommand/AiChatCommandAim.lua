--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandAim
--- @class AiChatCommandAim : AiChatCommandBase
local AiChatCommandAim = {
    cmd = "aim",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandAim:invoke(ai, sender, args)
    local toggle = args[1]

    if toggle == "on" then
        ai.states.engage.isAimEnabled = true

        return
    elseif toggle == "off" then
        ai.states.engage.isAimEnabled = false

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandAim", AiChatCommandAim, AiChatCommandBase)
--}}}
