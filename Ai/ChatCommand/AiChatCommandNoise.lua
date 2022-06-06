--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiChatCommandNoise
--- @class AiChatCommandNoise : AiChatCommandBase
local AiChatCommandNoise = {
    cmd = "noise",
    requiredArgs = 1,
    isAdminOnly = true,
    isValidIfSelfInvoked = true
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandNoise:invoke(ai, sender, args)
    -- Ignore the possessed Reaper client.
    if ai.reaper.isActive then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        ai.states.engage.aimNoise = View.noise.minor

        return
    elseif toggle == "off" then
        ai.states.engage.aimNoise = View.noise.none

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandNoise", AiChatCommandNoise, AiChatCommandBase)
--}}}
