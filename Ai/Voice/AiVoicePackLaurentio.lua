--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackLaurentio
--- @class AiVoicePackLaurentio : AiVoicePackGenericBase
local AiVoicePackLaurentio = {
	name = "M / EN-RO - Laurentio",
    packPath = "Laurentio"
}

--- @param fields AiVoicePackLaurentio
--- @return AiVoicePackLaurentio
function AiVoicePackLaurentio:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackLaurentio", AiVoicePackLaurentio, AiVoicePackGenericBase)
--}}}
