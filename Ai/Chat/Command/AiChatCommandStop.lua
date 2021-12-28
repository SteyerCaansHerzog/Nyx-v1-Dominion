--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiStateCheck = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateCheck"
local AiStatePatrol = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePatrol"
--}}}

--{{{ AiChatCommandStop
--- @class AiChatCommandStop : AiChatCommand
local AiChatCommandStop = {
    cmd = "stop",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandStop:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    if not sender:isAlive() then
        return
    end

    local check = ai:getState(AiStateCheck)
    local patrol = ai:getState(AiStatePatrol)

    check:reset()
    patrol:reset()
end

return Nyx.class("AiChatCommandStop", AiChatCommandStop, AiChatCommand)
--}}}
