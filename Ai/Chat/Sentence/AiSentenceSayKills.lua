--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiSentence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentence"
--}}}

--{{{ AiSentenceSayKills
--- @class AiSentenceSayKills : AiSentence
local AiSentenceSayKills = {}

--- @return AiSentenceSayKills
function AiSentenceSayKills:new()
    return Nyx.new(self)
end

--- @return void
function AiSentenceSayKills:__init()
    self.__parent.__init(self)

    self.probability = 3
    self.maxUses = 6

    self.structures = {
        DEATH_WP = {
            "{WOW}{PUNCT}",
            "{COMMEND}{PUNCT}"
        },
        DEATH_NADE = {
            "{OH}{PUNCT}"
        },
        DEATH_BY_TEAMMATE = {
            "{BRO}{PUNCT}",
            "{NP}{PUNCT}"
        },
        KILL_KOBE = {
            "{KOBE}{PUNCT}"
        },
        KILL_INSULT = {
            "{INSULT}{PUNCT}"
        },
        KILL_SORRY = {
            "{SORRY}{PUNCT}"
        },
        DEATH_NOOB = {
            "{YOURE}{NOOB}{PUNCT}"
        },
        ENEMY_DEATH_BY_TEAMMATE = {
            "{LOL}{PUNCT}",
            "{EMOJI}"
        }
    }

    self.insertions = {
        COMMEND = {
            "wp", "ns", "nice", "nice shot", "gj", "good job", "wow"
        },
        WOW = {
            "wow", "lmao", "ok then", "jesus", "ok"
        },
        OH = {
            "oh", "ah", "ok then", "fuck"
        },
        KOBE = {
            "kobe", "ez", "lmao", "haha", "rekt"
        },
        INSULT = {
            "ez", "easy", "rekt", "destroyed", "owned", "+ratio'd", "+ratio"
        },
        SORRY = {
            "sorry", "my bad", "mb", "oops", "shit"
        },
        BRO = {
            "bro", "bruh", "my guy", "dude", "ffs", "really", "lmao"
        },
        NP = {
            "np", "nw", "no worries", "don't worry", "it's ok"
        },
        LOL = {
            "lol", "lmao", "haha", "oof"
        },
        EMOJI = {
            "xd", ":p", ":v", "xD", "xd"
        },
        YOURE = {
            "", "you're a ", "ur a "
        },
        NOOB = {
            "noob", "cuck", "cock", "fatso", "fattie", "little bitch", "little slut", "cumsleeve"
        },
        PUNCT = {
            "", ".", "!"
        }
    }

    Callbacks.playerDeath(function(e)
        local gameRules = Entity.getGameRules()

        if gameRules:m_bWarmupPeriod() == 1 then
            return
        end

        if e.attacker:isClient() and e.victim:isTeammate() then
            self:speak("KILL_SORRY")
        end

        if e.attacker:isClient() and not e.victim:isTeammate() then
            if e.weapon == "hegrenade" then
                self:speak("KILL_KOBE")
            elseif e.weapon == "inferno" or (e.penetrated > 0 and e.headshot) then
                self:speak("KILL_INSULT")
            end

            return
        end

        if e.victim:isClient() and e.attacker:isEnemy() then
            if e.weapon == "knife" then
                self:speak("DEATH_WP")
            elseif e.weapon == "p90" or e.weapon == "scar20" or e.weapon == "g3sg" then
                self:speak("DEATH_NOOB")
            elseif e.weapon == "hegrenade" or e.weapon == "inferno" then
                self:speak("DEATH_NADE")
            elseif e.penetrated > 0 and e.headshot then
                self:speak("DEATH_WP")
            elseif e.noscope or e.attackerblind or e.thrusmoke then
                self:speak("DEATH_WP")
            elseif Client.getChance(8) then
                self:speak("DEATH_WP")
            end
        end

        if e.victim:isClient() and e.attacker:isTeammate() then
            self:speak("DEATH_BY_TEAMMATE")
        end

        if e.victim:isEnemy() and e.attacker:isEnemy() then
            self:speak("ENEMY_DEATH_BY_TEAMMATE")
        end
    end)
end

return Nyx.class("AiSentenceSayKills", AiSentenceSayKills, AiSentence)
--}}}
