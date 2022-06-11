--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandBase
--- @class AiChatCommandBase : Class
--- @field cmd string
--- @field requiredArgs number
--- @field isAdminOnly boolean
--- @field isValidIfSelfInvoked boolean
--- @field NO_VALID_ARGUMENTS string
--- @field SENDER_IS_DEAD string
--- @field CLIENT_IS_DEAD string
--- @field SENDER_IS_OUT_OF_RANGE string
local AiChatCommandBase = {
    BOMB_IS_PLANTED = "the bomb is currently planted",
    CLIENT_IS_DEAD = "the client is not currently alive",
    COMMAND_IS_DEPRECATED = "the chat command is deprecated",
    FREEZETIME = "the round has not started yet",
    GAMEMODE_IS_NOT_DEMOLITION = "the gamemode is not demolition",
    GAMEMODE_IS_NOT_HOSTAGE = "the gamemode is not hostage",
    LIVE_CLIENT_REQUIRED = "this command is only available for live clients",
    NO_ENEMIES_ALIVE = "no enemies are alive",
    NO_VALID_ARGUMENTS = "no valid arguments were given",
    ONLY_COUNTER_TERRORIST = "the command only applies to counter-terrorists",
    ONLY_TERRORIST = "the command only applies to terrorists",
    REAPER_IS_ACTIVE = "Reaper is currently active",
    SENDER_IS_DEAD = "the invoker is not currently alive",
    SENDER_IS_NOT_TEAMMATE = "the invoker is not a teammate",
    SENDER_IS_OUT_OF_RANGE = "the invoker is too far away",
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return string
function AiChatCommandBase:invoke(ai, sender, args) end

--- @vararg string
--- @return void
function AiChatCommandBase:bark(...)
    if not MenuGroup.useChatCommands:get() then
        return
    end

    local args = {...}
    local argsFormatted = Table.getImploded(args, " ")

    Messenger.send(string.format(" %s %s", self.cmd, argsFormatted), true)
end

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return boolean
function AiChatCommandBase:getRejectionError(ai, sender, args)
    if self.requiredArgs and #args < self.requiredArgs then
        return string.format("requires %i arguments, but only %i were given", self.requiredArgs, #args)
    end

    local steamId64 = sender:getSteamId64()
    local isSenderAdmin = Config.isAdministrator(steamId64)

    if ai.reaper.isEnabled and ai.reaper.manifest.steamId64Map[steamId64] then
        return
    end

    if self.isValidIfSelfInvoked then
        return
    end

    if sender:is(LocalPlayer) then
        return "it cannot be self-invoked"
    end

    if self.isAdminOnly and not isSenderAdmin then
        return "the invoker is not an administrator"
    end

    if not sender:isTeammate() and not isSenderAdmin then
        return self.SENDER_IS_NOT_TEAMMATE
    end
end

return Nyx.class("AiChatCommandBase", AiChatCommandBase)
--}}}
