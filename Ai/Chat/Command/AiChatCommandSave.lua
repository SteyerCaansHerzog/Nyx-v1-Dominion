--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandSave
--- @class AiChatCommandSave : AiChatCommand
local AiChatCommandSave = {
    cmd = "save",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandSave:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if Entity.getGameRules():m_bFreezePeriod() == 1 then
        return
    end

    if AiUtility.enemiesAlive == 0 then
        return
    end

    ai.states.evacuate.isForcedToSave = true
end

return Nyx.class("AiChatCommandSave", AiChatCommandSave, AiChatCommand)
--}}}
