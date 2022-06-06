--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ AiProcessBase
--- @class AiProcessBase : Class
--- @field ai AiController
local AiProcessBase = {}

--- @param fields AiProcessBase
--- @return AiProcessBase
function AiProcessBase:new(fields)
	return Nyx.new(self, fields)
end

return Nyx.class("AiProcessBase", AiProcessBase)
--}}}
