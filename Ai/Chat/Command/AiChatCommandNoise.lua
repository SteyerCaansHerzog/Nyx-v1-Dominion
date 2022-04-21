--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
--}}}

--{{{ AiChatCommandNoise
--- @class AiChatCommandNoise : AiChatCommand
local AiChatCommandNoise = {
    cmd = "noise",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandNoise:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    -- Ignore the possessed Reaper client.
    if ai.reaper.isActive then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        ai.states.engage.aimNoise = ai.view.noiseType.MINOR
    elseif toggle == "off" then
        ai.states.engage.aimNoise = ai.view.noiseType.NONE
    end
end

return Nyx.class("AiChatCommandNoise", AiChatCommandNoise, AiChatCommand)
--}}}
