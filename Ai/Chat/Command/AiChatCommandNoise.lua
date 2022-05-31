--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
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
    if not self:isValid(ai, sender, args) then
        return
    end

    -- Ignore the possessed Reaper client.
    if ai.reaper.isActive then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        ai.states.engage.aimNoise = View.noise.minor
    elseif toggle == "off" then
        ai.states.engage.aimNoise = View.noise.none
    end
end

return Nyx.class("AiChatCommandNoise", AiChatCommandNoise, AiChatCommandBase)
--}}}
