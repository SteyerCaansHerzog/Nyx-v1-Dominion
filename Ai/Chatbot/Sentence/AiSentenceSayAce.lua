--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceSayAce
--- @class AiSentenceSayAce : AiSentenceBase
--- @field playerKills number[]
local AiSentenceSayAce = {}

--- @return AiSentenceSayAce
function AiSentenceSayAce:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceSayAce:__init()
    self.__parent.__init(self)

    self.playerKills = {}
    self.probability = 5
    self.maxUses = 4

    self.structures = {
        "{COMMEND}"
    }

    self.insertions = {
        COMMEND = {
            "ace", "nice ace", "lol ace", "aced", "ace?"
        }
    }
end

--- @param e PlayerDeathEvent
--- @return void
function AiSentenceSayAce:replyToPlayerDeath(e)
    local gameRules = Entity.getGameRules()

    if gameRules:m_bWarmupPeriod() == 1 then
        return
    end

    if not self.playerKills[e.attacker.eid] then
        self.playerKills[e.attacker.eid] = 0
    end

    self.playerKills[e.attacker.eid] = self.playerKills[e.attacker.eid] + 1
end

--- @return void
function AiSentenceSayAce:replyOnRoundStart()
    for _, kills in pairs(self.playerKills) do
        if kills >= 5 then
            self:speak()

            break
        end
    end

    self.playerKills = {}
end

return Nyx.class("AiSentenceSayAce", AiSentenceSayAce, AiSentenceBase)
--}}}
