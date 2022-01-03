--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ SyncLobby
--- @class SyncLobby : Class
--- @field allocation Allocate
local SyncLobby = {}

--- @param fields SyncLobby
--- @return SyncLobby
function SyncLobby:new(fields)
    return Nyx.new(self, fields)
end

return Nyx.class(SyncLobby, SyncLobby)
--}}}
