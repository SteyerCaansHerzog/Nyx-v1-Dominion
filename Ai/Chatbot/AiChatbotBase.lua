--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ AiChatbotBase
--- @class AiChatbotBase : Class
--- @field isEnabled boolean
--- @field ai Ai
local AiChatbotBase = {
	isEnabled = false
}

--- @param fields AiChatbotBase
--- @return AiChatbotBase
function AiChatbotBase:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiChatbotBase", AiChatbotBase)
--}}}
