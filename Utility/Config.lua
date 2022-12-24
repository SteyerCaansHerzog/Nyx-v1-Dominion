--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Config
--- @class Config : Class
--- @field administrators string[]
--- @field clientConfigs AiProcessClientGsConfig
--- @field clientFocusVolume number
--- @field defaultSkillLevel number
--- @field isClearingSteamFriends boolean
--- @field isDebugging boolean
--- @field isEmulatingRealUserInput boolean
--- @field isForceDisconnectingOnMapChange boolean
--- @field isLiveClient boolean
--- @field isRandomizingCrosshair boolean
--- @field isResolvingTextToCommands boolean
--- @field isTextModeAllowed boolean
--- @field isVisualiserEnabled boolean
--- @field language string
--- @field openAiApiKey string
--- @field projectDirectory string
--- @field virtualMouseMode string ridid | dynamic
local Config = {
    administrators = {}, -- List of SteamID64 strings for accounts allowed to use admin chat commands.
    clientConfigs = {
        normal = "Nyx-v1-Dominion", -- GS config to load when in normal mode.
        reaper = "Nyx-v1-Dominion-Reaper", -- GS config to load when in Reaper mode.
    },
    clientFocusVolume = 0.15, -- The volume of a Reaper client that is focused.
    defaultSkillLevel = 4, -- The skill level to set the AI to by default.
    isClearingSteamFriends = false, -- Clear the AI's Steam friend list and any requests.
    isDebugging = false, -- Enables debugging features.
    isEmulatingRealUserInput = true, -- Enable this to emulate mouse-keyboard. Results in less accurate movement. Avoids potential bot detection.
    isForceDisconnectingOnMapChange = true, -- Auto-disconnects instead of loading map. Prevents computer crashes when running many bots.
    isLiveClient = false, -- Enable this when running on the Dominion Service.
    isRandomizingCrosshair = false, -- Create random crosshair every time Dominion is initialised.
    isResolvingTextToCommands = false, -- Try to resolve chat into commands. This is expensive.
    isTextModeAllowed = true, -- Enable this to disable Source engine rendering when applicable.
    isVisualiserEnabled = true, -- Enable this to see AI visualisation information.
    language = "English", -- Language localization for logs and other text.
    openAiApiKey = "", -- Set this to provide an API key for use with the Open AI chatbot.
    projectDirectory = "lua/gamesense/Nyx/v1/Dominion/%s", -- Root project directory for the Dominion folder. Must have /%s at the end.
    virtualMouseMode = "dynamic" -- "rigid" for old method, "dynamic" for smoother new method.
}

--- @return void
function Config:__setup()
    Config.administrators = Table.getMap(Config.administrators)
end

--- @param steamId64 string
--- @return boolean
function Config.isAdministrator(steamId64)
    return Config.administrators[steamId64] ~= nil
end

--- @param pathFragment string
--- @return string
function Config.getPath(pathFragment)
    return string.format(Config.projectDirectory, pathFragment)
end

return Nyx.class("Config", Config)
--}}}
