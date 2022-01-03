--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePack = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePack"
--}}}

--{{{ AiVoicePackSteyer
--- @class AiVoicePackSteyer : AiVoicePack
local AiVoicePackSteyer = {
    packPath = "Steyer"
}

--- @param fields AiVoicePackSteyer
--- @return AiVoicePackSteyer
function AiVoicePackSteyer:new(fields)
	return Nyx.new(self, fields)
end

--{{{ Kills
--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakEnemyKilledByClient(event)
	local group

	if event.weapon == "hegrenade" then
		group = self:getGroup("EnemyKilledByClient_Grenade", 5)
	elseif event.attackerblind or event.penetrated > 0 or event.weapon == "inferno" or event.thrusmoke then
		group = self:getGroup("EnemyKilledByClient_Owned", 8)
	else
		group = self:getGroup("EnemyKilledByClient_Generic", 38)
	end

	self:speak(group, {
		chance = 2,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakTeammateKilledByClient(event)
	local group

	if event.weapon == "inferno" then
		group = self:getGroup("TeammateKilledByClient_Inferno", 4)
	elseif event.attackerblind then
		group = self:getGroup("TeammateKilledByClient_Blind", 4)
	else
		group = self:getGroup("TeammateKilledByClient_Generic", 8)
	end

	self:speak(group, {
		chance = 1,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakClientKilledByEnemy(event)
	local group

	if event.weapon == "inferno" or event.weapon == "hegrenade" or event.attackerblind or event.penetrated > 0 or event.thrusmoke then
		group = self:getGroup("ClientKilledByEnemy_Owned", 10)
	else
		group = self:getGroup("ClientKilledByEnemy_Generic", 24)
	end

	self:speak(group, {
		chance = 2,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @param event PlayerDeathEvent
--- @return void
function AiVoicePack:speakClientKilledByTeammate(event)
	self:speak(self:getGroup("ClientKilledByTeammate", 15), {
		chance = 1,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end
--}}}

--{{{ Hurt
--- @param event PlayerHurtEvent
--- @return void
function AiVoicePack:speakEnemyHurtByClient(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePack:speakTeammateHurtByClient(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePack:speakClientHurtByEnemy(event) end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePack:speakClientHurtByTeammate(event)
	if event.dmg_health > 10 then
		self:speak(self:getGroup("ClientHurtByTeammate", 6), {
			chance = 1,
			interrupt = false,
			lock = true,
			ignoreLock = false,
			minDelay = 0.33,
			maxDelay = 1
		})
	end
end
--}}}

--{{{ AI
--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePack:speakRequestTeammatesToRotate(bombsite)
	local group

	if bombsite == "a" then
		group = self:getGroup("RequestTeammatesToRotate_A", 20)
	elseif bombsite == "b" then
		group = self:getGroup("RequestTeammatesToRotate_B", 16)
	end

	self:speak(group, {
		chance = 2,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePack:speakRequestTeammatesToPush(bombsite)
	local group

	if bombsite == "a" then
		group = self:getGroup("RequestTeammatesToPush_A", 18)
	elseif bombsite == "b" then
		group = self:getGroup("RequestTeammatesToPush_B", 16)
	end

	self:speak(group, {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- Must be implemented by AI. Triggered when enemy becomes aware of enemies and has decided to engage them.
---
--- @return void
function AiVoicePack:speakHearNearbyEnemies()
	self:speak(self:getGroup("HearNearbyEnemies", 22), {
		chance = 3,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- Must be implemented by AI. Is related to HearNearbyEnemies.
---
--- @return void
function AiVoicePack:speakNotifyTeamOfBombCarrier()
	self:speak(self:getGroup("NotifyTeamOfBombCarrier", 8), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- Must be implemented by AI.
---
--- @return void
function AiVoicePack:speakNotifyTeamOfBomb()
	self:speak(self:getGroup("NotifyTeamOfBomb", 10), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @return void
function AiVoicePack:speakNotifyFlashbanged()
	self:speak(self:getGroup("NotifyFlashbanged", 10), {
		chance = 2,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end
--}}}

--{{{ Round Start
--- @return void
function AiVoicePack:speakRoundStartPistolFirstHalf()
	self:speak(self:getGroup("RoundStartPistolFirstHalf", 8), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end

--- @return void
function AiVoicePack:speakRoundStartPistolSecondHalf()
	self:speak(self:getGroup("RoundStartPistolSecondHalf", 7), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end

--- @return void
function AiVoicePack:speakRoundStartWonPrevious()
	self:speak(self:getGroup("RoundStartWonPrevious", 9), {
		chance = 6,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end

--- @return void
function AiVoicePack:speakRoundStartLostPrevious()
	self:speak(self:getGroup("RoundStartLostPrevious", 9), {
		chance = 6,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end

--- @return void
function AiVoicePack:speakRoundStartMatchPointToTeam()
	self:speak(self:getGroup("RoundStartMatchPointToTeam", 5), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end

--- @return void
function AiVoicePack:speakRoundStartMatchPointToOpposition()
	self:speak(self:getGroup("RoundStartMatchPointToOpposition", 6), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end

--- @return void
function AiVoicePack:speakRoundStartMatchPointFinalRound()
	self:speak(self:getGroup("RoundStartMatchPointFinalRound", 6), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end
--}}}

--{{{ Round End
--- @return void
function AiVoicePack:speakRoundEndWon()
	self:speak(self:getGroup("RoundEndWon", 4), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 4
	})
end

--- @return void
function AiVoicePack:speakRoundEndLost()
	self:speak(self:getGroup("RoundEndLost", 4), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 4
	})
end

--- @return void
function AiVoicePack:speakRoundEndHalftime()
	self:speak(self:getGroup("RoundEndHalftime", 5), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end
--}}}

--{{{ Game Start
--- @return void
function AiVoicePack:speakWarmupGreeting()
	self:speak(self:getGroup("WarmupGreeting", 7), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @return void
function AiVoicePack:speakWarmupIdle()
	self:speak(self:getGroup("WarmupIdle", 14), {
		chance = 6,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end
--}}}

--{{{ Game End
--- @return void
function AiVoicePack:speakGameEndWon()
	self:speak(self:getGroup("GameEndWon", 7), {
		chance = 3,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 6
	})
end

--- @return void
function AiVoicePack:speakGameEndLost()
	self:speak(self:getGroup("GameEndLost", 7), {
		chance = 3,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 6
	})
end
--}}}

--{{{ Utility
--- @return void
function AiVoicePack:speakClientDefusingBomb()
	self:speak(self:getGroup("ClientDefusingBomb", 12), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @return void
function AiVoicePack:speakEnemyDefusingBomb()
	self:speak(self:getGroup("EnemyDefusingBomb", 9), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 0.5
	})
end

--- @return void
function AiVoicePack:speakCannotDefuseBomb()
	self:speak(self:getGroup("CannotDefuseBomb", 10), {
		chance = 2,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 2
	})
end

--- @return void
function AiVoicePack:speakClientPlantingBomb()
	self:speak(self:getGroup("ClientPlantingBomb", 12), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @return void
function AiVoicePack:speakEnemyPlantingBomb()
	self:speak(self:getGroup("EnemyPlantingBomb", 10), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @return void
function AiVoicePack:speakClientThrowingFlashbang()
	self:speak(self:getGroup("ClientThrowingFlashbang", 18), {
		chance = 1,
		interrupt = false,
		lock = false,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.1
	})
end

--- @return void
function AiVoicePack:speakClientThrowingSmoke()
	self:speak(self:getGroup("ClientThrowingSmoke", 16), {
		chance = 2,
		interrupt = false,
		lock = false,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.1
	})
end

--- @return void
function AiVoicePack:speakClientThrowingHeGrenade()
	self:speak(self:getGroup("ClientThrowingHeGrenade", 14), {
		chance = 3,
		interrupt = false,
		lock = false,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.1
	})
end

--- @return void
function AiVoicePack:speakClientThrowingIncendiary()
	self:speak(self:getGroup("ClientThrowingIncendiary", 10), {
		chance = 3,
		interrupt = false,
		lock = false,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.1
	})
end
--}}}

return Nyx.class("AiVoicePackSteyer", AiVoicePackSteyer, AiVoicePack)
--}}}
