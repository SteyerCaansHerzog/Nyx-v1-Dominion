--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackAdrian
--- @class AiVoicePackAdrian : AiVoicePackGenericBase
local AiVoicePackAdrian = {
	name = "M / EN-US - Adrian",
    packPath = "Adrian"
}

--- @param fields AiVoicePackAdrian
--- @return AiVoicePackAdrian
function AiVoicePackAdrian:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackAdrian", AiVoicePackAdrian, AiVoicePackGenericBase)
--}}}
