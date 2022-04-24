--{{{ Dependencies
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
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

    if ai.reaper.isEnabled then
        if self.isAdminOnly and not isSenderAdmin then
            if ai.reaper.manifest.steamId64Map[steamId64] then
                return true
            end

            return false
        elseif not sender:isTeammate() and not isSenderAdmin then
            return false
        end
    else
        if sender:is(AiUtility.client) then
            return false
        end

        if self.isAdminOnly and not isSenderAdmin then
            return false
        elseif not sender:isTeammate() and not isSenderAdmin then
            return false
        end
    end

    return true
end

return Nyx.class("AiChatCommand", AiChatCommand)
--}}}
