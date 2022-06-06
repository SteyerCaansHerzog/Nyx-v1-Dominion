--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceReplyCommend
--- @class AiSentenceReplyCommend : AiSentenceBase
--- @field lastKilledPlayerTimers Timer[]
local AiSentenceReplyCommend = {}

--- @return AiSentenceReplyCommend
function AiSentenceReplyCommend:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceReplyCommend:__init()
    self.__parent.__init(self)

    self.lastKilledPlayerTimers = {}

    for i = 1, 64 do
        self.lastKilledPlayerTimers[i] = Timer:new()
    end

    self.probability = 2
    self.maxUses = 30

    self.structures = {
        "{THANKS} {LOL}"
    }

    self.insertions = {
        THANKS = {
            "ty", "thanks", "thank you", "ta"
        },
        LOL = {
            "", "lol", ":)", "<3", ":P"
        }
    }
end

--- @param e PlayerChatEvent
--- @return void
function AiSentenceReplyCommend:replyToPlayerChat(e)
    if not self.lastKilledPlayerTimers[e.sender.eid]:isStarted() or self.lastKilledPlayerTimers[e.sender.eid]:isElapsed(6) then
        return
    end

    if not self.contains(e.text, {
        "wp", "ns", "nice", "nice shot", "gj", "good job"
    }) then
        return
    end

    self:speak()
end

--- @param e PlayerDeathEvent
--- @return void
function AiSentenceReplyCommend:replyToPlayerDeath(e)
    if not e.attacker:isClient() or e.victim:isTeammate() then
        return
    end

    self.lastKilledPlayerTimers[e.victim.eid]:start()
end

return Nyx.class("AiSentenceReplyCommend", AiSentenceReplyCommend, AiSentenceBase)
--}}}
