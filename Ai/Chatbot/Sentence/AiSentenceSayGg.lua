--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentenceBase = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/Sentence/AiSentenceBase"
--}}}

--{{{ AiSentenceSayGg
--- @class AiSentenceSayGg : AiSentenceBase
local AiSentenceSayGg = {}

--- @return AiSentenceSayGg
function AiSentenceSayGg:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceSayGg:__init()
    self.__parent.__init(self)

    self.probability = 2
    self.maxUses = 3

    self.structures = {
        GL = {
            "{GL}"
        },
        GH = {
            "{GH}"
        },
        GG = {
            "{GG}"
        }
    }

    self.insertions = {
        GL = {
            "gl", "glhf"
        },
        GH = {
            "gh"
        },
        GG = {
            "gg", "gg wp", "wp", "good game"
        }
    }
end

--- @return void
function AiSentenceSayGg:replyOnRoundStart()
    local gameRules = Entity.getGameRules()
    local roundsPlayed = gameRules:m_totalRoundsPlayed()

    if roundsPlayed == 0 then
        self:speak("GL")
    end
end

--- @return void
function AiSentenceSayGg:replyOnRoundEnd()
    Client.onNextTick(function()
        local gameRules = Entity.getGameRules()
        local roundsPlayed = gameRules:m_totalRoundsPlayed()

        if roundsPlayed == math.ceil(cvar.mp_maxrounds:get_int() / 2) then
            self:speak("GH")
        end
    end)
end

--- @return void
function AiSentenceSayGg:replyOnMatchEnd()
    self:speak("GG")
end

return Nyx.class("AiSentenceSayGg", AiSentenceSayGg, AiSentenceBase)
--}}}
