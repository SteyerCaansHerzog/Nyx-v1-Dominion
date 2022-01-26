--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ AiAction
--- @class AiAction : Class
local AiAction = {}

--- @param fields AiAction
--- @return AiAction
function AiAction:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiAction", AiAction)
--}}}
