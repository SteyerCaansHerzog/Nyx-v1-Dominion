--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ LogonSuccess
--- @class LogonSuccess : Class
--- @field token string
local LogonSuccess = {}

return Nyx.class("LogonSuccess", LogonSuccess)
--}}}
