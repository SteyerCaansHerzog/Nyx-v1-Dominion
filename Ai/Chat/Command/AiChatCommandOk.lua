--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Messenger = require "gamesense/Nyx/v1/Api/Messenger"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandOk
--- @class AiChatCommandOk : AiChatCommand
--- @field isTaken boolean
local AiChatCommandOk = {
    cmd = "ok",
    requiredArgs = 0,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return nil
function AiChatCommandOk:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    ai.commands.boost.isTaken = true
end

return Nyx.class("AiChatCommandOk", AiChatCommandOk, AiChatCommand)
--}}}
