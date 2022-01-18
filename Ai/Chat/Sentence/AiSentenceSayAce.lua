--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceSayAce
--- @class AiSentenceSayAce : AiSentence
--- @field playerKills number[]
local AiSentenceSayAce = {}

--- @return AiSentenceSayAce
function AiSentenceSayAce:new()
    return Nyx.new(self)
end

--- @return nil
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
            "wp", "ns", "nice", "nice shot", "gj", "good job", "wow", "jesus"
        }
    }

    Callbacks.playerDeath(function(e)
        local gameRules = Entity.getGameRules()

        if gameRules:m_bWarmupPeriod() == 1 then
            return
        end

        if not self.playerKills[e.attacker.eid] then
            self.playerKills[e.attacker.eid] = 0
        end

        self.playerKills[e.attacker.eid] = self.playerKills[e.attacker.eid] + 1
    end)

    Callbacks.roundStart(function()
        for _, kills in pairs(self.playerKills) do
            if kills >= 5 then
                self:speak()

                break
            end
        end

        self.playerKills = {}
    end)
end

return Nyx.class("AiSentenceSayAce", AiSentenceSayAce, AiSentence)
--}}}
