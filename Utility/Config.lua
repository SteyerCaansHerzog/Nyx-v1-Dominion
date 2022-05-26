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
--- @field openAiApiKey string
local Config = {
    administrators = {
        -- Insert SteamID64s here that should be administrative accounts.
    },
    clientFocusVolume = 1.0, -- The volume of a Reaper client that is focused.
    defaultSkillLevel = 4, -- The skill level to set the AI to by default.
    isClearingSteamFriends = false, -- Clear the AI's Steam friend list and any requests.
    isDebugging = false, -- Enables debugging features.
    isEmulatingRealUserInput = false, -- Enable this to emulate mouse-keyboard. Results in less accurate movement. Avoids potential bot detection.
    isLiveClient = false, -- Enable this when running on the Dominion Service.
    isRandomizingCrosshair = false, -- Create random crosshair every time Dominion is initialised.
    openAiApiKey = "", -- Set this to provide an API key for use with the Open AI chatbot.
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
