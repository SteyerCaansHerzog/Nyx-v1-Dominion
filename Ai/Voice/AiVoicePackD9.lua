--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackD9
--- @class AiVoicePackD9 : AiVoicePackGenericBase
local AiVoicePackD9 = {
	name = "TTS / EN-UK - D9",
    packPath = "D9"
}

--- @param fields AiVoicePackD9
--- @return AiVoicePackD9
function AiVoicePackD9:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackD9", AiVoicePackD9, AiVoicePackGenericBase)
--}}}
