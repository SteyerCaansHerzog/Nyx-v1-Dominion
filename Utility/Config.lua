--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Config
--- @class Config : Class
--- @field administrators string[]
--- @field clientFocusVolume number
--- @field defaultSkillLevel number
--- @field isClearingSteamFriends boolean
--- @field isDebugging boolean
--- @field isEmulatingRealUserInput boolean
--- @field isLiveClient boolean
--- @field isRandomizingCrosshair boolean
--- @field isTextModeAllowed boolean
--- @field language string
--- @field openAiApiKey string
--- @field projectDirectory string
local Config = {
    administrators = {
        -- Friends
        "76561198138748363", -- Adrian
        -- Main accounts
        "76561198339559079", -- Data
        "76561198373386496", -- Bropp
        "76561198816968549", -- Kirsty
        "76561198866118626", -- Michael
        "76561198283352893", -- Comm banned
        "76561199241945029" -- Digital Spring
    },
    clientFocusVolume = 0.15, -- The volume of a Reaper client that is focused.
    defaultSkillLevel = 4, -- The skill level to set the AI to by default.
    isClearingSteamFriends = true, -- Clear the AI's Steam friend list and any requests.
    isDebugging = false, -- Enables debugging features.
    isEmulatingRealUserInput = true, -- Enable this to emulate mouse-keyboard. Results in less accurate movement. Avoids potential bot detection.
    isLiveClient = false, -- Enable this when running on the Dominion Service.
    isRandomizingCrosshair = false, -- Create random crosshair every time Dominion is initialised.
    isTextModeAllowed = true, -- Enable this to disable Source engine rendering when applicable.
    language = "English", -- Language localization for logs and other text.
    openAiApiKey = "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", -- Set this to provide an API key for use with the Open AI chatbot.
    projectDirectory = "lua/gamesense/Nyx/v1/Dominion/%s" -- Root project directory for the Dominion folder. Must have /%s at the end.
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

--- @param pathFragment string
--- @return string
function Config.getPath(pathFragment)
    return string.format(Config.projectDirectory, pathFragment)
end

return Nyx.class("Config", Config)
--}}}
