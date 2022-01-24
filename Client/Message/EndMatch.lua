--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ EndMatch
--- @class EndMatch : Class
--- @field roundsPlayed number
--- @field isWinner boolean
local EndMatch = {}

--- @param fields EndMatch
--- @return EndMatch
function EndMatch:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("EndMatch", EndMatch)
--}}}
