--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
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
    if not self:isValid(ai, sender, args) then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        ai.states.engage.isAimEnabled = true
    elseif toggle == "off" then
        ai.states.engage.isAimEnabled = false
    end
end

return Nyx.class("AiChatCommandAim", AiChatCommandAim, AiChatCommandBase)
--}}}
