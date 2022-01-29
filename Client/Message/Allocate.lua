--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Allocate
--- @class Allocate : Class
--- @field steamid string
--- @field botSteamids string[]
--- @field host string
--- @field isInGame boolean
--- @field isInLobby boolean
--- @field isInQueue boolean
--- @field voicePacks number[]
local Allocate = {}

return Nyx.class("Allocate", Allocate)
--}}}
