--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackEdd
--- @class AiVoicePackEdd : AiVoicePackGenericBase
local AiVoicePackEdd = {
	name = "TTS / EN-UK - Edd",
    packPath = "Edd"
}

--- @param fields AiVoicePackEdd
--- @return AiVoicePackEdd
function AiVoicePackEdd:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackEdd", AiVoicePackEdd, AiVoicePackGenericBase)
--}}}
