--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ ApplyCooldown
--- @class ApplyCooldown : Class
--- @field expiresAt number
--- @field reason string
local ApplyCooldown = {}

--- @param fields ApplyCooldown
--- @return ApplyCooldown
function ApplyCooldown:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class(ApplyCooldown, ApplyCooldown)
--}}}
