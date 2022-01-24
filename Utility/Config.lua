--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Config
--- @class Config : Class
--- @field administrators string[]
--- @field isDebugging boolean
--- @field isJoiningServerOnStartup boolean
--- @field isLiveClient boolean When true, this bot will connect to the Nyx Dominion AI Service and act as a client.
local Config = {
    administrators = {
        "76561199102984662", -- 0DTE
        "76561198373386496", -- Braff
        "76561198105632069", -- ?
        "76561198991038413" -- dusty
    },
    isDebugging = false,
    isJoiningServerOnStartup = false,
    isLiveClient = true
}

return Nyx.class("Config", Config)
--}}}
