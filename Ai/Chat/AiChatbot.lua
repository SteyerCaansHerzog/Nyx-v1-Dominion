--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ AiChatbot
--- @class AiChatbot : Class
--- @field isEnabled boolean
local AiChatbot = {
	isEnabled = false
}

--- @param fields AiChatbot
--- @return AiChatbot
function AiChatbot:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiChatbot", AiChatbot)
--}}}
