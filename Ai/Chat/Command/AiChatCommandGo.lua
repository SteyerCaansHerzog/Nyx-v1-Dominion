--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandGo
--- @class AiChatCommandGo : AiChatCommandBase
local AiChatCommandGo = {
    cmd = "go",
    requiredArgs = 1,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandGo:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if AiUtility.gamemode == "hostage" then
        return
    end

    if ai.reaper.isActive then
        return
    end

    if AiUtility.plantedBomb then
        return
    end

    if sender:is(LocalPlayer) or not LocalPlayer:isAlive() then
        return
    end

    local objective = args[1]

    if not objective then
        return
    end

    objective = objective:upper()

    local validObjectives = {
        A = true,
        B = true,
        CT = true,
        T = true
    }

    if not validObjectives[objective] then
        return
    end

    ai.voice.pack:speakAgreement()

    Client.fireAfter(Math.getRandomFloat(1, 2), function()
        if ai.states.boost.isBoosting then
            return
        end

        ai.states.check:reset()
        ai.states.patrol:reset()
        ai.states.sweep:activate(objective)

        if LocalPlayer:isTerrorist() then
            if objective == "CT" or objective == "T" then
                ai.states.check:activate(objective)
            else
                ai.states.defend.defendingSite = objective

                ai.states.defend:activate(objective)

                ai.states.pushDemolition.isDeactivated = false
                ai.states.pushDemolition.site = objective

                ai.states.pushDemolition:activate(objective)
            end

            if LocalPlayer.hasBomb() then
                ai.states.plant:activate(objective)
            end
        elseif LocalPlayer:isCounterTerrorist() then
            if objective == "CT" or objective == "T" then
                ai.states.check:activate(objective)
            else
                ai.states.defend.defendingSite = objective

                ai.states.defend:activate(objective)
            end
        end
    end)
end

return Nyx.class("AiChatCommandGo", AiChatCommandGo, AiChatCommandBase)
--}}}
