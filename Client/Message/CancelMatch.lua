--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ CancelMatch
--- @class CancelMatch : Class
--- @field reason string
local CancelMatch = {}

--- @param fields CancelMatch
--- @return CancelMatch
function CancelMatch:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("CancelMatch", CancelMatch)
--}}}
