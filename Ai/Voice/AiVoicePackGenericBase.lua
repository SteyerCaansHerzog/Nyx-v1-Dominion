--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiVoicePackBase = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoicePackBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiVoicePackGenericBase
--- @class AiVoicePackGenericBase : AiVoicePackBase
--- @field groups table<string, number>
local AiVoicePackGenericBase = {
	name = "Generic",
    packPath = "Generic"
}

--- @param fields AiVoicePackGenericBase
--- @return AiVoicePackGenericBase
function AiVoicePackGenericBase:new(fields)
	return Nyx.new(self, fields)
end

--{{{ Kills
--- @param event PlayerDeathEvent
--- @return void
function AiVoicePackGenericBase:speakEnemyKilledByClient(event)
	local group

	if event.weapon == "hegrenade" then
		group = self:getGroupDynamic("EnemyKilledByClient_Grenade")
	elseif event.attackerblind or event.penetrated > 0 or event.weapon == "inferno" or event.thrusmoke then
		group = self:getGroupDynamic("EnemyKilledByClient_Owned")
	else
		group = self:getGroupDynamic("EnemyKilledByClient_Generic")
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
function AiVoicePackGenericBase:speakTeammateKilledByClient(event)
	local group

	if event.weapon == "inferno" then
		group = self:getGroupDynamic("TeammateKilledByClient_Inferno")
	elseif event.attackerblind then
		group = self:getGroupDynamic("TeammateKilledByClient_Blind")
	else
		group = self:getGroupDynamic("TeammateKilledByClient_Generic")
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
function AiVoicePackGenericBase:speakClientKilledByEnemy(event)
	local group

	if event.weapon == "inferno" or event.weapon == "hegrenade" or event.attackerblind or event.penetrated > 0 or event.thrusmoke then
		group = self:getGroupDynamic("ClientKilledByEnemy_Owned")
	else
		group = self:getGroupDynamic("ClientKilledByEnemy_Generic")
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
function AiVoicePackGenericBase:speakClientKilledByTeammate(event)
	self:speak(self:getGroupDynamic("ClientKilledByTeammate"), {
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
function AiVoicePackGenericBase:speakEnemyHurtByClient(event)
	if event.dmg_health > 10 then
		self:speak(self:getGroupDynamic("EnemyHurtByClient"), {
			chance = 3,
			interrupt = false,
			lock = true,
			ignoreLock = false,
			minDelay = 1,
			maxDelay = 1.5,
			condition = function()
				return event.victim:isAlive()
			end
		})
	end
end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePackGenericBase:speakTeammateHurtByClient(event)
	if event.dmg_health > 10 then
		self:speak(self:getGroupDynamic("TeammateHurtByClient"), {
			chance = 2,
			interrupt = false,
			lock = true,
			ignoreLock = false,
			minDelay = 1,
			maxDelay = 1.5,
			condition = function()
				return event.victim:isAlive()
			end
		})
	end
end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePackGenericBase:speakClientHurtByEnemy(event)
	if event.health < 50 then
		self:speak(self:getGroupDynamic("ClientHurtByEnemy"), {
			chance = 3,
			interrupt = false,
			lock = true,
			ignoreLock = false,
			minDelay = 1,
			maxDelay = 1.5,
			condition = function()
				return not AiUtility.isRoundOver and not AiUtility.isLastAlive and LocalPlayer:isAlive()
			end
		})
	end
end

--- @param event PlayerHurtEvent
--- @return void
function AiVoicePackGenericBase:speakClientHurtByTeammate(event)
	if event.dmg_health > 10 then
		self:speak(self:getGroupDynamic("ClientHurtByTeammate"), {
			chance = 1,
			interrupt = false,
			lock = true,
			ignoreLock = false,
			minDelay = 0.33,
			maxDelay = 1,
			condition = function()
				return not AiUtility.isRoundOver and not AiUtility.isLastAlive and LocalPlayer:isAlive()
			end
		})
	end
end
--}}}

--{{{ AI
--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePackGenericBase:speakRequestTeammatesToRotate(bombsite)
	local group

	if bombsite == "A" then
		group = self:getGroupDynamic("RequestTeammatesToRotate_A")
	elseif bombsite == "B" then
		group = self:getGroupDynamic("RequestTeammatesToRotate_B")
	end

	self:speak(group, {
		chance = 2,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- Must be implemented by AI.
---
--- @param bombsite string
--- @return void
function AiVoicePackGenericBase:speakRequestTeammatesToPush(bombsite)
	local group

	if bombsite == "A" then
		group = self:getGroupDynamic("RequestTeammatesToPush_A")
	elseif bombsite == "B" then
		group = self:getGroupDynamic("RequestTeammatesToPush_B")
	end

	self:speak(group, {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- Must be implemented by AI. Triggered when enemy becomes aware of enemies and has decided to engage them.
---
--- @return void
function AiVoicePackGenericBase:speakHearNearbyEnemies()
	self:speak(self:getGroupDynamic("HearNearbyEnemies"), {
		chance = 3,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 2,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- Must be implemented by AI. Is related to HearNearbyEnemies.
---
--- @return void
function AiVoicePackGenericBase:speakNotifyTeamOfBombCarrier()
	self:speak(self:getGroupDynamic("NotifyTeamOfBombCarrier"), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 3
	})
end

--- Must be implemented by AI.
---
--- @return void
function AiVoicePackGenericBase:speakNotifyTeamOfBomb()
	self:speak(self:getGroupDynamic("NotifyTeamOfBomb"), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @return void
function AiVoicePackGenericBase:speakNotifyFlashbanged()
	self:speak(self:getGroupDynamic("NotifyFlashbanged"), {
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
function AiVoicePackGenericBase:speakRoundStartPistolFirstHalf()
	self:speak(self:getGroupDynamic("RoundStartPistolFirstHalf"), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 13
	})
end

--- @return void
function AiVoicePackGenericBase:speakRoundStartPistolSecondHalf()
	self:speak(self:getGroupDynamic("RoundStartPistolSecondHalf"), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 13
	})
end

--- @return void
function AiVoicePackGenericBase:speakRoundStartWonPrevious()
	self:speak(self:getGroupDynamic("RoundStartWonPrevious"), {
		chance = 6,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 13
	})
end

--- @return void
function AiVoicePackGenericBase:speakRoundStartLostPrevious()
	self:speak(self:getGroupDynamic("RoundStartLostPrevious"), {
		chance = 6,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 13
	})
end

--- @return void
function AiVoicePackGenericBase:speakRoundStartMatchPointToTeam()
	self:speak(self:getGroupDynamic("RoundStartMatchPointToTeam"), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end

--- @return void
function AiVoicePackGenericBase:speakRoundStartMatchPointToOpposition()
	self:speak(self:getGroupDynamic("RoundStartMatchPointToOpposition"), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 8
	})
end

--- @return void
function AiVoicePackGenericBase:speakRoundStartMatchPointFinalRound()
	self:speak(self:getGroupDynamic("RoundStartMatchPointFinalRound"), {
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
function AiVoicePackGenericBase:speakRoundEndWon()
	self:speak(self:getGroupDynamic("RoundEndWon"), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.5,
		maxDelay = 6
	})
end

--- @return void
function AiVoicePackGenericBase:speakRoundEndLost()
	self:speak(self:getGroupDynamic("RoundEndLost"), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.5,
		maxDelay = 6
	})
end

--- @return void
function AiVoicePackGenericBase:speakRoundEndHalftime()
	self:speak(self:getGroupDynamic("RoundEndHalftime"), {
		chance = 4,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.5,
		maxDelay = 8
	})
end
--}}}

--{{{ Game Start
--- @return void
function AiVoicePackGenericBase:speakWarmupGreeting()
	self:speak(self:getGroupDynamic("WarmupGreeting"), {
		chance = 1,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1
	})
end

--- @return void
function AiVoicePackGenericBase:speakWarmupIdle()
	self:speak(self:getGroupDynamic("WarmupIdle"), {
		chance = 1,
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
function AiVoicePackGenericBase:speakGameEndWon()
	self:speak(self:getGroupDynamic("GameEndWon"), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 1,
		maxDelay = 6
	})
end

--- @return void
function AiVoicePackGenericBase:speakGameEndLost()
	self:speak(self:getGroupDynamic("GameEndLost"), {
		chance = 2,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 1,
		maxDelay = 6
	})
end
--}}}

--{{{ Utility
--- @return void
function AiVoicePackGenericBase:speakClientDefusingBomb()
	self:speak(self:getGroupDynamic("ClientDefusingBomb"), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakEnemyDefusingBomb()
	self:speak(self:getGroupDynamic("EnemyDefusingBomb"), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 0.5,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakCannotDefuseBomb()
	self:speak(self:getGroupDynamic("CannotDefuseBomb"), {
		chance = 2,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 2,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakClientPlantingBomb()
	self:speak(self:getGroupDynamic("ClientPlantingBomb"), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = true,
		minDelay = 0.33,
		maxDelay = 1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakEnemyPlantingBomb()
	self:speak(self:getGroupDynamic("EnemyPlantingBomb"), {
		chance = 1,
		interrupt = true,
		lock = true,
		ignoreLock = false,
		minDelay = 0.33,
		maxDelay = 1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakClientThrowingFlashbang()
	self:speak(self:getGroupDynamic("ClientThrowingFlashbang"), {
		chance = 1,
		interrupt = false,
		lock = false,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakClientThrowingSmoke()
	self:speak(self:getGroupDynamic("ClientThrowingSmoke"), {
		chance = 2,
		interrupt = false,
		lock = false,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakClientThrowingHeGrenade()
	self:speak(self:getGroupDynamic("ClientThrowingHeGrenade"), {
		chance = 3,
		interrupt = false,
		lock = false,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakClientThrowingIncendiary()
	self:speak(self:getGroupDynamic("ClientThrowingIncendiary"), {
		chance = 3,
		interrupt = false,
		lock = false,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.1,
		condition = function()
			return not AiUtility.isRoundOver and not AiUtility.isLastAlive
		end
	})
end
--}}}

--{{{ Comments
--- @return void
function AiVoicePackGenericBase:speakLastAlive()
	self:speak(self:getGroupDynamic("LastAlive"), {
		chance = 2,
		interrupt = false,
		lock = false,
		ignoreLock = true,
		minDelay = 1,
		maxDelay = 4,
		condition = function()
			return not AiUtility.isRoundOver and LocalPlayer:isAlive()
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakGifting()
	self:speak(self:getGroupDynamic("Gifting"), {
		chance = 1,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 0.5,
		condition = function()
			return LocalPlayer:isAlive()
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakGratitude()
	self:speak(self:getGroupDynamic("Gratitude"), {
		chance = 1,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 1,
		condition = function()
			return LocalPlayer:isAlive()
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakAgreement()
	self:speak(self:getGroupDynamic("Agreement"), {
		chance = 6,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 1.25,
		maxDelay = 2,
		condition = function()
			return LocalPlayer:isAlive()
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakDisagreement()
	self:speak(self:getGroupDynamic("Disagreement"), {
		chance = 6,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 1.25,
		maxDelay = 2,
		condition = function()
			return LocalPlayer:isAlive()
		end
	})
end

--- @return void
function AiVoicePackGenericBase:speakNoProblem()
	self:speak(self:getGroupDynamic("NoProblem"), {
		chance = 1,
		interrupt = false,
		lock = true,
		ignoreLock = false,
		minDelay = 0,
		maxDelay = 3,
		condition = function()
			return LocalPlayer:isAlive()
		end
	})
end
--}}}

return Nyx.class("AiVoicePackGenericBase", AiVoicePackGenericBase, AiVoicePackBase)
--}}}
