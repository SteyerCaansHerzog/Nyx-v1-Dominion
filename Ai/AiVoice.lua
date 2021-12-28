--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiVoicePackEmpty = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackEmpty"
local AiVoicePackGeneric = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackGeneric"
--}}}

--{{{ AiVoice
--- @class AiVoice : Class
--- @field pack AiVoicePack
--- @field packs AiVoicePack[]
--- @field clientWonLastRound boolean
local AiVoice = {
    packs = {
        empty = AiVoicePackEmpty,
        generic = AiVoicePackGeneric
    }
}

--- @param fields AiVoice
--- @return AiVoice
function AiVoice:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiVoice:__init()
    self.pack = self.packs.empty

    Callbacks.levelInit(function()
    	Client.fireAfter(Client.getRandomFloat(5, 15), function()
            if Entity.getGameRules():m_bWarmupPeriod() == 1 then
                self.pack:speakWarmupGreeting()
            end
    	end)

        Client.fireAfter(Client.getRandomFloat(16, 35), function()
            if Entity.getGameRules():m_bWarmupPeriod() == 1 then
                self.pack:speakWarmupIdle()
            end
        end)
    end)

    Callbacks.roundStart(function()
        local freezetime = cvar.mp_freezetime:get_float()
        local minDelay = freezetime * 0.4
        local maxDelay = freezetime * 0.8

        Client.fireAfter(Client.getRandomFloat(minDelay, maxDelay), function()
            local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
            local scoreData = Table.fromPanorama(Panorama.GameStateAPI.GetScoreDataJSO())
            local tWins = scoreData.teamdata.TERRORIST.score
            local ctWins = scoreData.teamdata.CT.score
            local teamWins
            local oppositionWins

            if Player.getClient():isTerrorist() then
                teamWins = tWins
                oppositionWins = ctWins
            else
                teamWins = ctWins
                oppositionWins = tWins
            end

            self.pack:speakRoundStart()

            if roundsPlayed == 0 then
                self.pack:speakRoundStartPistolFirstHalf()

                return
            end

            if roundsPlayed == 15 then
                self.pack:speakRoundStartPistolSecondHalf()

                return
            end

            if roundsPlayed == 29 then
                self.pack:speakRoundStartMatchPointFinalRound()

                return
            end

            if teamWins == 15 then
                self.pack:speakRoundStartMatchPointToTeam()

                return
            end

            if oppositionWins == 15 then
                self.pack:speakRoundStartMatchPointToOpposition()

                return
            end

            if self.clientWonLastRound then
                self.pack:speakRoundStartWonPrevious()
            else
                self.pack:speakRoundStartLostPrevious()
            end
        end)
    end)

    Callbacks.roundEnd(function(e)
        local restartDelay = cvar.mp_round_restart_delay:get_float()
        local minDelay = restartDelay * 0.1
        local maxDelay = restartDelay * 0.66

        Client.fireAfter(Client.getRandomFloat(minDelay, maxDelay), function()
            local isWinner = e.winner == Player.getClient():m_iTeamNum()
            local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
            local roundsNeededToWin = cvar.mp_maxrounds:get_int() / 2
            local scoreData = Table.fromPanorama(Panorama.GameStateAPI.GetScoreDataJSO())
            local tWins = scoreData.teamdata.TERRORIST.score
            local ctWins = scoreData.teamdata.CT.score
            local teamWins
            local oppositionWins

            if Player.getClient():isTerrorist() then
                teamWins = tWins
                oppositionWins = ctWins
            else
                teamWins = ctWins
                oppositionWins = tWins
            end

            if teamWins == roundsNeededToWin then
                self.pack:speakGameEndWon()

                return
            end

            if oppositionWins == roundsNeededToWin then
                self.pack:speakGameEndLost()

                return
            end

            self.pack:speakRoundEnd()

            if roundsPlayed == 14 then
                self.pack:speakRoundEndHalftime()

                return
            end

            if isWinner then
                self.pack:speakRoundEndWon()
            else
                self.pack:speakRoundEndLost()
            end
        end)
    end)

    Callbacks.playerDeath(function(e)
        if e.attacker:isClient() then
            if e.victim:isEnemy() then
                self.pack:speakEnemyKilledByClient(e)

                return
            end

            if e.victim:isTeammate() then
                self.pack:speakTeammateKilledByClient(e)

                return
            end
        end

        if e.victim:isClient() then
            if e.attacker:isEnemy() then
                self.pack:speakClientKilledByEnemy(e)

                return
            end

            if e.attacker:isTeammate() then
                self.pack:speakClientKilledByTeammate(e)

                return
            end
        end
    end)

    Callbacks.playerHurt(function(e)
        if e.attacker:isClient() then
            if e.victim:isEnemy() then
                self.pack:speakEnemyHurtByClient(e)

                return
            end

            if e.victim:isTeammate() then
                self.pack:speakTeammateHurtByClient(e)

                return
            end
        end

        if e.victim:isClient() then
            if e.attacker:isEnemy() then
                self.pack:speakClientHurtByEnemy(e)

                return
            end

            if e.attacker:isTeammate() then
                self.pack:speakClientHurtByTeammate(e)

                return
            end
        end
    end)
end

return Nyx.class("AiVoice", AiVoice)
--}}}
