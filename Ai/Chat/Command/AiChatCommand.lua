--{{{ Dependencies
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
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

--- @param args string[]
--- @return void
function AiChatCommand:execute(args)
    if not Menu.useAiChatCommands:get() then
        return
    end

    local argsFormatted = table.concat(args, " ")

    Messenger.send(string.format("/%s %s", self.cmd, argsFormatted), true)
end

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return boolean
function AiChatCommand:isValid(ai, sender, args)
    if self.requiredArgs and #args < self.requiredArgs then

        return false
    end

    local isSenderAdmin = Table.contains(ai.config.administrators, sender:getSteam64())

    if self.isAdminOnly and not isSenderAdmin then
        return false
    elseif not sender:isTeammate() and not isSenderAdmin then
        return false
    end

    return true
end

return Nyx.class("AiChatCommand", AiChatCommand)
--}}}
