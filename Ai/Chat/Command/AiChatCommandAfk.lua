--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandAfk
--- @class AiChatCommandAfk : AiChatCommandBase
local AiChatCommandAfk = {
    cmd = "afk",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandAfk:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local toggle = args[1]

    if toggle == "on" then
        MenuGroup.enableAi:set(false)
    elseif toggle == "off" then
        MenuGroup.enableAi:set(true)
    end
end

return Nyx.class("AiChatCommandAfk", AiChatCommandAfk, AiChatCommandBase)
--}}}
