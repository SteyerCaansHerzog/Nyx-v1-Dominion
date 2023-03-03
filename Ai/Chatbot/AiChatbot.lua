--{{{ AiChatbot
--- @class AiChatbot
local AiChatbot = {
	normal = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/AiChatbotNormal",
	gpt3 = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/AiChatbotGpt3",
	gpt35 = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/AiChatbotGpt35",
}

return AiChatbot
--}}}
