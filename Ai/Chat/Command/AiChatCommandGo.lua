--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiStateCheck = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateCheck"
local AiStateDefend = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDefend"
local AiStateGrenadeBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGrenadeBase"
local AiStatePatrol = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePatrol"
local AiStatePlant = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePlant"
local AiStatePush = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePush"
local AiStateSweep = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateSweep"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandGo
--- @class AiChatCommandGo : AiChatCommand
local AiChatCommandGo = {
    cmd = "go",
    requiredArgs = 1,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return nil
function AiChatCommandGo:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if AiUtility.plantedBomb then
        return
    end

    if sender:is(AiUtility.client) or not AiUtility.client:isAlive() then
        return
    end

    local objective = args[1]
    local validObjectives = {
        a = true,
        b = true,
        ct = true,
        t = true
    }

    if not validObjectives[objective] then
        return
    end

    local player = AiUtility.client

    if AiUtility.roundTimer:isStarted() and AiUtility.roundTimer:isElapsed(15) then
        AiStateGrenadeBase.globalCooldownTimer:start()
    end

    ai.voice.pack:speakAgreement()

    Client.fireAfter(Client.getRandomFloat(1, 2), function()
        ai.states.check:reset()
        ai.states.patrol:reset()
        ai.states.sweep:activate(ai, objective)

        if ai.states.boost.isBoosting then
            return
        end

        if Client.hasBomb() then
            ai.states.plant:activate(ai, objective)
        end

        if player:isTerrorist() then
            if objective == "ct" or objective == "t" then
                ai.states.check:activate(ai, objective)
            else
                ai.states.defend.defendingSite = objective

                ai.states.defend:activate(ai, objective)

                ai.states.push.isDeactivated = false
                ai.states.push.site = objective

                ai.states.push:activate(ai, objective)
            end

        elseif player:isCounterTerrorist() then
            if objective == "ct" or objective == "t" then
                ai.states.check:activate(ai, objective)
            else
                ai.states.defend.defendingSite = objective

                ai.states.defend:activate(ai, objective)

                local siteNode = ai.nodegraph:getSiteNode(objective)
                local team = player:m_iTeamNum()
                local text

                if team == 2 then
                    text = "I'm %sgoing%s there now."
                else
                    text = "I'm %srotating%s there now."
                end

                if player:getOrigin():getDistance(siteNode.origin) > 1024 then
                    ai.radio:speak(ai.radio.message.AGREE, 1, 0.33, 1, text, ai.radio.color.YELLOW, ai.radio.color.DEFAULT)
                end
            end
        end
    end)
end

return Nyx.class("AiChatCommandGo", AiChatCommandGo, AiChatCommand)
--}}}
