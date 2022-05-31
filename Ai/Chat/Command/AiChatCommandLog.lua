--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
--}}}

--{{{ AiChatCommandLog
--- @class AiChatCommandLog : AiChatCommandBase
--- @field tabs string[]
--- @field refWeaponTab MenuItem
--- @field refAccuracyBoost MenuItem
--- @field refAccuracyBoostRange MenuItem
local AiChatCommandLog = {
    cmd = "log",
    requiredArgs = 1,
    isAdminOnly = true,
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandLog:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
    elseif toggle == "off" then
    end
end

return Nyx.class("AiChatCommandLog", AiChatCommandLog, AiChatCommandBase)
--}}}
