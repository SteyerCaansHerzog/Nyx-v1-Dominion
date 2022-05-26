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
        -- Friends
        "76561198138748363", -- Adrian
        -- Main accounts
        "76561198816968549", -- Kirsty
        --"76561198373386496", -- Braff v2
        "76561198339559079", -- Britney Spears
        --"76561198991038413", -- dusty
        --"76561198291655919", -- Boxxy
        --"76561198807527047", -- 0DTE
        --"76561198105632069", -- Braff v1

        --"76561199145578388", -- C Low
        --"76561198935227008", -- C Low
        --"76561198971897854", -- C Low
        --"76561199087305425", -- C Low
        --"76561198346253218", -- C Low
    },
    clientFocusVolume = 0.15, -- The volume of a Reaper client that is focused.
    defaultSkillLevel = 4, -- The skill level to set the AI to by default.
    isClearingSteamFriends = true, -- Clear the AI's Steam friend list and any requests.
    isDebugging = false, -- Enables debugging features.
    isEmulatingRealUserInput = false, -- Enable this to emulate mouse-keyboard. Results in less accurate movement. Avoids potential bot detection.
    isLiveClient = false, -- Enable this when running on the Dominion Service.
    isRandomizingCrosshair = false, -- Create random crosshair every time Dominion is initialised.
    openAiApiKey = "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", -- Set this to provide an API key for use with the Open AI chatbot.
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
