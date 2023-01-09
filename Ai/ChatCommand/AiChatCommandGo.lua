--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
--}}}

--{{{ AiChatCommandGo
--- @class AiChatCommandGo : AiChatCommandBase
local AiChatCommandGo = {
    cmd = "go",
    requiredArgs = 1,
    isAdminOnly = false,
    isValidIfSelfInvoked = true
}

--- @param ai Ai
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandGo:invoke(ai, sender, args)
    if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
        return self.GAMEMODE_IS_NOT_DEMOLITION
    end

    if ai.reaper.isActive then
        return self.REAPER_IS_ACTIVE
    end

    if AiUtility.plantedBomb then
        return self.BOMB_IS_PLANTED
    end

    local objective = args[1]

    objective = objective:upper()

    if not Table.contains({"CT", "T", "A", "B"}, objective) then
        return Localization.cmdRejectionNoValidSpawnOrBombsite
    end

    Client.fireAfterRandom(1, 2, function()
        ai.states.patrol:reset()

        if objective == "CT" or objective == "T" then
            ai.states.check:invoke(objective)
            ai.voice.pack:speakAgreement()

        elseif objective == "A" or objective == "B" then
            if sender:isLocalPlayer() then
                ai.states.defend.bombsite = objective
                ai.states.defend.isSpecificNodeSet = false
                ai.states.lurkWithBomb.bombsite = objective
            else
                ai.states.defend:invoke(objective)
                ai.states.plant:invoke(objective)
                ai.states.pushDemolition:invoke(objective)
                ai.states.lurkWithBomb:invoke(objective)
                ai.states.lurkT:invokeAndSetOppositeBombsite(objective)

                ai.voice.pack:speakAgreement()
            end
        end
    end)
end

return Nyx.class("AiChatCommandGo", AiChatCommandGo, AiChatCommandBase)
--}}}
