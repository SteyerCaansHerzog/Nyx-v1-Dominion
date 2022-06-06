--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
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
    return self.COMMAND_IS_DEPRECATED
end

return Nyx.class("AiChatCommandLog", AiChatCommandLog, AiChatCommandBase)
--}}}
