--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiRoutineWalk
--- @class AiRoutineWalk : AiRoutineBase
--- @field noiseLevel number
--- @field noiseLevelTimer Timer
--- @field maxNoiseLevel number
--- @field cooldownTimer Timer
--- @field noiseThreshold number
--- @field isWalking boolean
local AiRoutineWalk = {}

--- @param fields AiRoutineWalk
--- @return AiRoutineWalk
function AiRoutineWalk:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineWalk:__init()
	self.noiseLevel = 0
	self.noiseLevelTimer = Timer:new():start()
	self.maxNoiseLevel = Math.getRandomInt(30, 40)
	self.cooldownTimer = Timer:new():startThenElapse()
	self.noiseThreshold = Math.getRandomInt(10, 18)

	Callbacks.playerHurt(function(e)
		if not e.victim:isOtherTeammate() then
			return
		end

		if LocalPlayer:getOrigin():getDistance(e.victim:getOrigin()) > 600 then
			return
		end

		self.noiseLevel = self.maxNoiseLevel
	end)

	Callbacks.playerFootstep(function(e)
		if e.player:isEnemy() or e.player:isLocalPlayer() then
			return
		end

		if LocalPlayer:getOrigin():getDistance(e.player:getOrigin()) > 600 then
			return
		end

		self.noiseLevel = Math.getClamped(self.noiseLevel + 1.15, 0, self.maxNoiseLevel)
	end)

	Callbacks.weaponFire(function(e)
		if e.player:isEnemy() or e.player:isLocalPlayer() then
			return
		end

		if LocalPlayer:getOrigin():getDistance(e.player:getOrigin()) > 600 then
			return
		end

		self.noiseLevel = Math.getClamped(self.noiseLevel + 2.5, 0, self.maxNoiseLevel)
	end)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineWalk:think(cmd)
	if self.noiseLevelTimer:isElapsedThenRestart(0.25) then
		self.noiseLevel = Math.getClamped(self.noiseLevel - 1, 0, self.maxNoiseLevel)
	end

	if not self.cooldownTimer:isElapsed(5) then
		return
	end

	if not AiUtility.closestEnemy then
		return
	end

	if AiUtility.closestEnemyDistance > 1400 then
		return
	end

	if self.noiseLevel > self.noiseThreshold then
		return
	end

	if AiUtility.isBombBeingDefusedByEnemy or AiUtility.isBombBeingPlantedByEnemy then
		return
	end

	if AiUtility.isHostageCarriedByEnemy or AiUtility.isHostageBeingPickedUpByEnemy then
		return
	end

	if LocalPlayer:isCounterTerrorist() and AiUtility.plantedBomb and AiUtility.bombDetonationTime <= 20 then
		return
	end

	if LocalPlayer:m_bIsScoped() == 1 then
		return
	end

	if LocalPlayer:isTerrorist() and not AiUtility.plantedBomb and AiUtility.timeData.roundtime_remaining < 25 then
		return
	end

	self.ai.routines.manageGear.isAllowedToKnifeWalls = false

	Pathfinder.walk()
end

return Nyx.class("AiRoutineWalk", AiRoutineWalk, AiRoutineBase)
--}}}
