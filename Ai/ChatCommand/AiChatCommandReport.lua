--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
--}}}

--{{{ AiChatCommandReport
--- @class AiChatCommandReport : AiChatCommandBase
local AiChatCommandReport = {
    cmd = "report",
    requiredArgs = 1,
    isAdminOnly = true
}

--- @param ai Ai
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return string|nil
function AiChatCommandReport:invoke(ai, sender, args)
    local targetString = Table.getStringFromTableWithDelimiter(args, " ")
    local targets = {}
    local targetNames = {}

    if targetString == "*" then
        -- Report the entire enemy team.
        for _, player in Player.findAll(function(p)
            return p:isEnemy()
        end) do
            table.insert(targets, player)
            table.insert(targetNames, player:getName())
        end
    else
        -- Report specific players.
        for _, player in Player.findAll(function(p)
            return p:isEnemy()
        end) do
            local name = player:getName()

            if name:lower():find(targetString, 0, false) then
                table.insert(targets, player)
                table.insert(targetNames, name)
            end
        end
    end

    if Table.isEmpty(targets) then
        Messenger.send(true, "nobody was reported.")

        return Localization.cmdRejectionReportNoTargets
    end

    for idx, target in pairs(targets) do
        -- Report with a randomised delay to evade potential mass reporting detection.
        Client.fireAfter(idx + Math.getRandomFloat(0, 0.5), function()
            Client.reportPlayer(target, "textabuse, voiceabuse")
        end)
    end

    Messenger.send(true, "reported %s.", Table.getStringFromTableWithDelimiter(targetNames, ", "))
end

return Nyx.class("AiChatCommandReport", AiChatCommandReport, AiChatCommandBase)
--}}}
