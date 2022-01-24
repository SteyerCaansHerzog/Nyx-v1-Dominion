--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ StartMatch
--- @class StartMatch : Class
local StartMatch = {}

--- @return StartMatch
function StartMatch:new()
    return Nyx.new(self)
end

return Nyx.class("StartMatch", StartMatch)
--}}}
