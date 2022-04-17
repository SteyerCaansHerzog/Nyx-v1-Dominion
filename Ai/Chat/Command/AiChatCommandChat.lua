--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandChat
--- @class AiChatCommandChat : AiChatCommand
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
    if not self:isValid(ai, sender, args) then
        return
    end

    local state = args[1]

    if state == "off" then
        ai.chatbots.normal.isEnabled = false
        ai.chatbots.gpt3.isEnabled = false
    elseif state == "normal" then
        ai.chatbots.normal.isEnabled = true
        ai.chatbots.gpt3.isEnabled = false
    elseif state == "gpt3" then
        ai.chatbots.normal.isEnabled = false
        ai.chatbots.gpt3.isEnabled = true
    elseif state == "both" then
        ai.chatbots.normal.isEnabled = true
        ai.chatbots.gpt3.isEnabled = true
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

    print(ai.chatbots.normal.isEnabled)
    print(ai.chatbots.gpt3.isEnabled)
end

return Nyx.class("AiChatCommandChat", AiChatCommandChat, AiChatCommand)
--}}}
