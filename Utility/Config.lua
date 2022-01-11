--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Config
--- @class Config : Class
--- @field administrators string[]
--- @field debug boolean
--- @field joinServer boolean
--- @field autoClosePopups boolean
local Config = {
    administrators = {
        "76561199102984662", -- 0DTE
        "76561198373386496", -- Braff
        "76561198105632069", -- ?
        "76561198991038413" -- dusty
    },
    debug = false,
    joinServer = false
}

return Nyx.class("Config", Config)
--}}}
