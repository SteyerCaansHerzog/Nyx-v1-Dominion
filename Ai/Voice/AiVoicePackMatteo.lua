--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackMatteo
--- @class AiVoicePackMatteo : AiVoicePackGenericBase
local AiVoicePackMatteo = {
	name = "M / EN-IT - Matteo",
    packPath = "Matteo"
}

--- @param fields AiVoicePackMatteo
--- @return AiVoicePackMatteo
function AiVoicePackMatteo:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackMatteo", AiVoicePackMatteo, AiVoicePackGenericBase)
--}}}
