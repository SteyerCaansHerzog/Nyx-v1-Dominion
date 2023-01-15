--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
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
--- @field lastCallRotateBombsite string
--- @field lastCallGoBombsite string
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

	Callbacks.roundStart(function()
		self.lastCallRotateBombsite = nil
		self.lastCallGoBombsite = nil
	end)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiRoutineHandleRotates:think(cmd)
	if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE then
		return
	end

	if not LocalPlayer:isCounterTerrorist() then
		return
	end

	if AiUtility.plantedBomb then
		return
	end

	self:calloutRotate()
	self:calloutGo()
end

--- @return void
function AiRoutineHandleRotates:calloutRotate()
	if not self.callRotateCooldownTimer:isElapsed(8) then
		return
	end

	if not AiUtility.bombCarrier then
		return
	end

	if AiUtility.gameRules:m_bFreezePeriod() == 1 then
		return
	end

	if AiUtility.timeData.roundtime_elapsed < 15 then
		return
	end

	if AiUtility.bombCarrier:isDormant() then
		return
	end

	local enemyOrigin = AiUtility.bombCarrier:m_vecOrigin()
	local enemyNearestBombsite = Nodegraph.getClosestBombsite(enemyOrigin)

	if enemyOrigin:getDistance(enemyNearestBombsite.origin) > AiUtility.mapInfo.bombsiteRotateRadius then
		return
	end

	if enemyNearestBombsite.bombsite == self.lastCallRotateBombsite then
		return
	end

	self.lastCallRotateBombsite = enemyNearestBombsite.bombsite

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
	if not self.callGoCooldownTimer:isElapsed(8) then
		return
	end

	if AiUtility.enemiesAlive == 0 then
		return
	end

	if AiUtility.gameRules:m_bFreezePeriod() == 1 then
		return
	end

	if AiUtility.timeData.roundtime_elapsed < 15 then
		return
	end

	local enemiesNearBombsites = {
		A = 0,
		B = 0
	}

	for _, enemy in pairs(AiUtility.enemies) do repeat
		if enemy:isDormant() then
			break
		end

		-- Not using dormant origin as it can go stale.
		local enemyOrigin = enemy:m_vecOrigin()
		local nearestBombsite = Nodegraph.getClosestBombsite(enemyOrigin)

		if enemyOrigin:getDistance(nearestBombsite.origin) < AiUtility.mapInfo.bombsiteRotateRadius * 1.2 then
			enemiesNearBombsites[nearestBombsite.bombsite] = enemiesNearBombsites[nearestBombsite.bombsite] + 1
		end
	until true end

	local bombsite
	local enemiesNearBombsite

	if enemiesNearBombsites.A >= enemiesNearBombsites.B then
		bombsite = "A"
		enemiesNearBombsite = enemiesNearBombsites.A
	else
		bombsite = "B"
		enemiesNearBombsite = enemiesNearBombsites.B
	end

	if self.lastCallGoBombsite == bombsite then
		return
	end

	self.lastCallGoBombsite = bombsite

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
