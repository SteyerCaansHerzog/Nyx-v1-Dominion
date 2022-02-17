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
        "76561198373386496", -- Braff
        "76561198339559079", -- Britney Spears
        "76561198991038413" -- dusty
    },
    isDebugging = false,
    isJoiningServerOnStartup = false,
    isLiveClient = false
}

return Nyx.class("Config", Config)
--}}}
