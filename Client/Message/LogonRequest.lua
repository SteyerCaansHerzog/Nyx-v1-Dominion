--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ LogonRequest
--- @class LogonRequest : Class
--- @field username string
--- @field friendCode string
--- @field rank number
local LogonRequest = {}

--- @param fields LogonRequest
--- @return LogonRequest
function LogonRequest:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class("LogonRequest", LogonRequest)
--}}}
