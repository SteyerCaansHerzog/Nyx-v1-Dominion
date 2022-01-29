--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackBenji
--- @class AiVoicePackBenji : AiVoicePackGenericBase
local AiVoicePackBenji = {
	name = "M / EN-DE - Benji",
    packPath = "Benji"
}

--- @param fields AiVoicePackBenji
--- @return AiVoicePackBenji
function AiVoicePackBenji:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackBenji", AiVoicePackBenji, AiVoicePackGenericBase)
--}}}
