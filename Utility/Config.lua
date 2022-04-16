--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Config
--- @class Config : Class
--- @field administrators string[]
--- @field isDebugging boolean
--- @field isLiveClient boolean
--- @field isEmulatingRealUserInput boolean
--- @field openAiApiKey string
local Config = {
    administrators = {
        -- Add SteamID64 of accounts you wish to have as administrators.
        -- These accounts can use extra chat commands.
    },
    isDebugging = false, -- Enables debugging features.
    isLiveClient = false, -- Enable this when running on the Dominion Service.
    isEmulatingRealUserInput = false, -- Enable this to emulate mouse-keyboard. Results in less accurate movement. Avoids potential bot detection.
    openAiApiKey = nil -- Set this to provide an API key for use with the Open AI chatbot.
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
