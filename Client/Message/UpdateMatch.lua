--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ UpdateMatch
--- @class UpdateMatch : Class
--- @field roundsPlayed number
local UpdateMatch = {}

--- @param fields UpdateMatch
--- @return UpdateMatch
function UpdateMatch:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class(UpdateMatch, UpdateMatch)
--}}}
