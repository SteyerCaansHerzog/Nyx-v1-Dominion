--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackTaylor
--- @class AiVoicePackTaylor : AiVoicePackGenericBase
local AiVoicePackTaylor = {
	name = "M / EN-US - Taylor",
    packPath = "Taylor"
}

--- @param fields AiVoicePackTaylor
--- @return AiVoicePackTaylor
function AiVoicePackTaylor:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackTaylor", AiVoicePackTaylor, AiVoicePackGenericBase)
--}}}
