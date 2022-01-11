--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackConnor
--- @class AiVoicePackConnor : AiVoicePack
local AiVoicePackConnor = {
	name = "M / EN-US - Connor",
    packPath = "Connor"
}

--- @param fields AiVoicePackConnor
--- @return AiVoicePackConnor
function AiVoicePackConnor:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackConnor", AiVoicePackConnor, AiVoicePackGenericBase)
--}}}
