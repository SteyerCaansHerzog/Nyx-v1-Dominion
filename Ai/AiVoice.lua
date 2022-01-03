--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"

--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiVoicePackEmpty = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackEmpty"
local AiVoicePackSteyer = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackSteyer"
--}}}

--{{{ AiVoice
--- @class AiVoice : Class
--- @field pack AiVoicePack
--- @field packs AiVoicePack[]
--- @field clientWonLastRound boolean
--- @field flashbangTimer Timer
local AiVoice = {
    packs = {
        empty = AiVoicePackEmpty,
        steyer = AiVoicePackSteyer
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
    self.flashbangTimer = Timer:new():startThenElapse()

    Callbacks.runCommand(function()
        if Client.isFlashed() and self.flashbangTimer:isElapsedThenRestart(10) then
            self.pack:speakNotifyFlashbanged()
        end
    end)

    Callbacks.levelInit(function()
    	Client.fireAfter(Client.getRandomFloat(10, 20), function()
            if Entity.getGameRules():m_bWarmupPeriod() == 1 then
                self.pack:speakWarmupGreeting()
            end
    	end)

        Client.fireAfter(Client.getRandomFloat(22, 40), function()
            if Entity.getGameRules():m_bWarmupPeriod() == 1 then
                self.pack:speakWarmupIdle()
            end
        end)
    end)

    Callbacks.roundStart(function()
        Client.onNextTick(function()
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

            local maxRounds = cvar.mp_maxrounds:get_int()
            local halfTime = math.ceil(maxRounds / 2)

            if roundsPlayed == 0 then
                self.pack:speakRoundStartPistolFirstHalf()

                return
            end

            if roundsPlayed == halfTime - 1 then
                self.pack:speakRoundStartPistolSecondHalf()

                return
            end

            if roundsPlayed == maxRounds - 1 then
                self.pack:speakRoundStartMatchPointFinalRound()

                return
            end

            if teamWins == halfTime then
                self.pack:speakRoundStartMatchPointToTeam()

                return
            end

            if oppositionWins == halfTime then
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
        Client.onNextTick(function()
            local player = Player.getClient()
            local team = player:m_iTeamNum()

            self.clientWonLastRound = e.winner == team

            local isWinner = e.winner == Player.getClient():m_iTeamNum()
            local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
            local maxRounds = cvar.mp_maxrounds:get_int()
            local halfTime = math.floor(maxRounds / 2)
            local roundsNeededToWin = halfTime + 1
            local scoreData = Table.fromPanorama(Panorama.GameStateAPI.GetScoreDataJSO())
            local tWins = scoreData.teamdata.TERRORIST.score
            local ctWins = scoreData.teamdata.CT.score
            local teamWins
            local oppositionWins

            if player:isTerrorist() then
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

            if roundsPlayed == halfTime then
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
        if AiUtility.isLastAlive or Entity.getGameRules():m_bWarmupPeriod() == 1 then
            return
        end

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
        if AiUtility.isLastAlive or Entity.getGameRules():m_bWarmupPeriod() == 1 then
            return
        end

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

    Callbacks.bombBeginDefuse(function(e)
        if AiUtility.isLastAlive then
            return
        end

        if e.player:isClient() then
            self.pack:speakClientDefusingBomb()
        end

        local player = Player.getClient()

        if e.player:isEnemy() and player:isAlive() and player:getOrigin():getDistance(e.player:getOrigin()) < 1500 then
            self.pack:speakEnemyDefusingBomb()
        end
    end)

    Callbacks.bombBeginPlant(function(e)
        if AiUtility.isLastAlive then
            return
        end

        if e.player:isClient() then
            self.pack:speakClientPlantingBomb()
        end

        local player = Player.getClient()

        if e.player:isEnemy() and player:isAlive() and player:getOrigin():getDistance(e.player:getOrigin()) < 1500 then
            self.pack:speakEnemyPlantingBomb()
        end
    end)

    Callbacks.weaponFire(function(e)
        if AiUtility.isLastAlive then
            return
        end

        if e.player:isClient() then
            local methods = {
                weapon_flashbang = "speakClientThrowingFlashbang",
                weapon_hegrenade = "speakClientThrowingHeGrenade",
                weapon_smokegrenade = "speakClientThrowingSmoke",
                weapon_incgrenade = "speakClientThrowingIncendiary",
                weapon_molotov = "speakClientThrowingIncendiary",
            }

            local method = methods[e.weapon]

            if method then
                self.pack[method](self.pack)
            end
        end
    end)


end

return Nyx.class("AiVoice", AiVoice)
--}}}
