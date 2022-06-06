--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
--}}}

--{{{ AiChatCommandChat
--- @class AiChatCommandChat : AiChatCommandBase
local AiChatCommandChat = {
    cmd = "chat",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return void
function AiChatCommandChat:invoke(ai, sender, args)
    local state = args[1]
    local isChanged = false

    if state == "off" then
        ai.chatbots.normal.isEnabled = false
        ai.chatbots.gpt3.isEnabled = false

        isChanged = true
    elseif state == "normal" then
        ai.chatbots.normal.isEnabled = true
        ai.chatbots.gpt3.isEnabled = false

        isChanged = true
    elseif state == "gpt3" then
        ai.chatbots.normal.isEnabled = false
        ai.chatbots.gpt3.isEnabled = true

        isChanged = true
    elseif state == "both" then
        ai.chatbots.normal.isEnabled = true
        ai.chatbots.gpt3.isEnabled = true

        isChanged = true
    end

    if not isChanged  then
        return self.NO_VALID_ARGUMENTS
    end

    -- Handle Reaper mode clients.
    if ai.reaper.isActive then
        ai.reaper.savedCommunicationStates = {
            chatbotNormal = ai.chatbots.normal.isEnabled,
            chatbotGpt3 = ai.chatbots.gpt3.isEnabled
        }

        ai.chatbots.normal.isEnabled = false
        ai.chatbots.gpt3.isEnabled = false
    end
end

return Nyx.class("AiChatCommandChat", AiChatCommandChat, AiChatCommandBase)
--}}}
