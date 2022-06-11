--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandSave
--- @class AiChatCommandSave : AiChatCommandBase
local AiChatCommandSave = {
    cmd = "save",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandSave:invoke(ai, sender, args)
    if AiUtility.gameRules:m_bFreezePeriod() == 1 then
        return self.FREEZETIME
    end

    if AiUtility.enemiesAlive == 0 then
        return self.NO_ENEMIES_ALIVE
    end

    ai.states.evacuate.isForcedToSave = true
end

return Nyx.class("AiChatCommandSave", AiChatCommandSave, AiChatCommandBase)
--}}}
