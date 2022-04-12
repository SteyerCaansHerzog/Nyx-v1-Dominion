--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Config
--- @class Config : Class
--- @field administrators string[]
--- @field isDebugging boolean
--- @field isJoiningServerOnStartup boolean
--- @field isLiveClient boolean When true, the bot will connect to the Nyx Dominion AI Service and act as a client.
--- @field isUserInputSafe boolean When true, the bot will emulate the keyboard. Results in less accurate movement.
local Config = {
    administrators = {
        -- Friends
        "76561198138748363",
        -- Main accounts
        "76561198373386496", -- Braff
        "76561198339559079", -- Britney Spears
        "76561198991038413", -- dusty
        "76561198816968549", -- Kirsty

        -- Reaper
        "76561198391892203",
        "76561198249845606"
    },
    isDebugging = false,
    isJoiningServerOnStartup = false,
    isLiveClient = false,
    isUserInputSafe = true
}

--- @return void
function Config:__setup()
    Config.administrators = Table.getMap(Config.administrators)
end

--- @param steamId64 string
--- @return boolean
function Config.isAdministrator(steamId64)
    return Config.administrators[steamId64]
end

return Nyx.class("Config", Config)
--}}}
