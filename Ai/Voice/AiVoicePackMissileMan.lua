--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackGenericBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGenericBase"
--}}}

--{{{ AiVoicePackMissileMan
--- @class AiVoicePackMissileMan : AiVoicePackGenericBase
local AiVoicePackMissileMan = {
	name = "TTS / EN-UK - Missile Man",
    packPath = "MissileMan"
}

--- @param fields AiVoicePackMissileMan
--- @return AiVoicePackMissileMan
function AiVoicePackMissileMan:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiVoicePackMissileMan", AiVoicePackMissileMan, AiVoicePackGenericBase)
--}}}
