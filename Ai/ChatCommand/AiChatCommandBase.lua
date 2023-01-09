--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandBase
--- @class AiChatCommandBase : Class
--- @field cmd string
--- @field requiredArgs number
--- @field isAdminOnly boolean
--- @field isValidIfSelfInvoked boolean
local AiChatCommandBase = {
    BOMB_IS_PLANTED = Localization.cmdRejectionBombIsPlanted,
    CLIENT_IS_DEAD = Localization.cmdRejectionClientIsDead,
    COMMAND_IS_DEPRECATED = Localization.cmdRejectionCommandIsDeprecated,
    FREEZETIME = Localization.cmdRejectionFreezetime,
    GAMEMODE_IS_NOT_DEMOLITION = Localization.cmdRejectionGamemodeIsNotDemolition,
    GAMEMODE_IS_NOT_HOSTAGE = Localization.cmdRejectionGamemodeIsNotHostage,
    LIVE_CLIENT_REQUIRED = Localization.cmdRejectionLiveClientRequired,
    NO_ENEMIES_ALIVE = Localization.cmdRejectionNoEnemiesAlive,
    NO_VALID_ARGUMENTS = Localization.cmdRejectionNoValidArguments,
    ONLY_COUNTER_TERRORIST = Localization.cmdRejectionOnlyCounterTerrorist,
    ONLY_TERRORIST = Localization.cmdRejectionOnlyTerrorist,
    REAPER_IS_ACTIVE = Localization.cmdRejectionReaperIsActive,
    SENDER_IS_DEAD = Localization.cmdRejectionSenderIsDead,
    SENDER_IS_NOT_TEAMMATE = Localization.cmdRejectionSenderIsNotTeammate,
    SENDER_IS_OUT_OF_RANGE = Localization.cmdRejectionSenderIsOutOfRange,
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
    local argsFormatted = Table.getImplodedTable(args, " ")

    Messenger.send(string.format(" %s %s", self.cmd, argsFormatted), true)
end

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return boolean
function AiChatCommandBase:getRejectionError(ai, sender, args)
    if self.requiredArgs and #args < self.requiredArgs then
        return string.format(Localization.cmdRejectionArgsMissing, self.requiredArgs, #args)
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
        return Localization.cmdRejectionSelfInvoked
    end

    if self.isAdminOnly and not isSenderAdmin then
        return Localization.cmdRejectionNotAdmin
    end

    if not sender:isTeammate() and not isSenderAdmin then
        return self.SENDER_IS_NOT_TEAMMATE
    end
end

return Nyx.class("AiChatCommandBase", AiChatCommandBase)
--}}}
