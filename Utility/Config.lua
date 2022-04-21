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
        -- Main accounts
        "76561198373386496", -- Braff
        "76561198339559079", -- Britney Spears
        "76561198991038413", -- dusty
        "76561198816968549", -- Kirsty
        "76561198291655919" -- Boxxy

    },
    isDebugging = false, -- Enables debugging features.
    isLiveClient = false, -- Enable this when running on the Dominion Service.
    isEmulatingRealUserInput = false, -- Enable this to emulate mouse-keyboard. Results in less accurate movement. Avoids potential bot detection.
    openAiApiKey = "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" -- Set this to provide an API key for use with the Open AI chatbot.
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
