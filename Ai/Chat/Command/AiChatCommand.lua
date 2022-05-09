--{{{ Dependencies
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
--}}}

--{{{ AiChatCommand
--- @class AiChatCommand : Class
--- @field cmd string
--- @field requiredArgs number
--- @field isAdminOnly boolean
local AiChatCommand = {}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommand:invoke(ai, sender, args) end

--- @vararg string
--- @return void
function AiChatCommand:bark(...)
    if not Menu.useChatCommands:get() then
        return
    end

    local argsFormatted = table.concat({...}, " ")

    Messenger.send(string.format(" %s %s", self.cmd, argsFormatted), true)
end

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return boolean
function AiChatCommand:isValid(ai, sender, args)
    if self.requiredArgs and #args < self.requiredArgs then

        return false
    end

    local steamId64 = sender:getSteamId64()
    local isSenderAdmin = Config.isAdministrator(steamId64)

    if ai.reaper.isEnabled and ai.reaper.manifest.steamId64Map[steamId64] then
        return true
    end

    if sender:is(AiUtility.client) then
        return false
    end

    if self.isAdminOnly and not isSenderAdmin then
        return false
    end

    if not sender:isTeammate() and not isSenderAdmin then
        return false
    end

    return true
end

return Nyx.class("AiChatCommand", AiChatCommand)
--}}}
