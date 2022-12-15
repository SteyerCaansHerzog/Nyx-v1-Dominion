--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
--}}}

--{{{ AiRoutineHandleRotates
--- @class AiRoutineHandleRotates : AiRoutineBase
--- @field callRotateCooldownTimer Timer
--- @field callGoCooldownTimer Timer
local AiRoutineHandleRotates = {}

--- @param fields AiRoutineHandleRotates
--- @return AiRoutineHandleRotates
function AiRoutineHandleRotates:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineHandleRotates:__init()
	self.callRotateCooldownTimer = Timer:new():startThenElapse()
	self.callGoCooldownTimer = Timer:new():startThenElapse()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineHandleRotates:think(cmd)
	if AiUtility.gamemode == AiUtility.gamemodes.HOSTAGE then
		return
	end

	if not LocalPlayer:isCounterTerrorist() then
		return
	end

	if AiUtility.plantedBomb then
		return
	end

	if self.callRotateCooldownTimer:isElapsed(60) then
		self:calloutRotate()
	end

	if self.callGoCooldownTimer:isElapsed(60) then
		self:calloutGo()
	end
end

--- @return void
function AiRoutineHandleRotates:calloutRotate()
	if not AiUtility.bombCarrier then
		return
	end

	local enemyOrigin = AiUtility.bombCarrier:getOrigin()
	local enemyNearestBombsite = Nodegraph.getClosestBombsite(enemyOrigin)

	if enemyOrigin:getDistance(enemyNearestBombsite.origin) > 1250 then
		return
	end

	self.callRotateCooldownTimer:restart()

	local clientOrigin = LocalPlayer:getOrigin()
	local clientNearestBombsite = Nodegraph.getClosestBombsite(clientOrigin)

	if clientNearestBombsite.bombsite == enemyNearestBombsite.bombsite then
		self.ai.commands.rot:bark(enemyNearestBombsite.bombsite:lower())
		self.ai.voice.pack:speakRequestTeammatesToRotate(enemyNearestBombsite.bombsite)
	else
		self.ai.states.rotate:invoke(enemyNearestBombsite.bombsite)
	end
end

--- @return void
function AiRoutineHandleRotates:calloutGo()
	if AiUtility.enemiesAlive == 0 then
		return
	end

	local enemiesNearBombsites = {
		A = 0,
		B = 0
	}

	for _, enemy in pairs(AiUtility.enemies) do
		local enemyOrigin = enemy:getOrigin()
		local nearestBombsite = Nodegraph.getClosestBombsite(enemyOrigin)

		if enemyOrigin:getDistance(nearestBombsite.origin) < 1750 then
			enemiesNearBombsites[nearestBombsite.bombsite] = enemiesNearBombsites[nearestBombsite.bombsite] + 1
		end
	end

	local bombsite
	local enemiesNearBombsite

	if enemiesNearBombsites.A >= enemiesNearBombsites.B then
		bombsite = "A"
		enemiesNearBombsite = enemiesNearBombsites.A
	else
		bombsite = "B"
		enemiesNearBombsite = enemiesNearBombsites.B
	end

	local ratio = enemiesNearBombsite / AiUtility.enemiesAlive

	if ratio < 0.5 then
		return
	end

	self.callGoCooldownTimer:restart()

	local clientOrigin = LocalPlayer:getOrigin()
	local clientNearestBombsite = Nodegraph.getClosestBombsite(clientOrigin)

	if clientNearestBombsite.bombsite == bombsite then
		self.ai.commands.go:bark(bombsite:lower())
		self.ai.voice.pack:speakRequestTeammatesToRotate(bombsite)
	else
		self.ai.states.defend:invoke(bombsite)
	end
end

return Nyx.class("AiRoutineHandleRotates", AiRoutineHandleRotates, AiRoutineBase)
--}}}
