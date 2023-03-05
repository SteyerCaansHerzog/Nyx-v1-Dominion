--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local WeaponInfo = require "gamesense/Nyx/v1/Dominion/Ai/Info/WeaponInfo"
--}}}

--{{{ Definitions
local BuyCriteria = {
	COUNTER_TERRORIST_FULL_BUY = 4200,
	COUNTER_TERRORIST_FORCE_BUY = 2500,
	COUNTER_TERRORIST_RIFLE_BUY = 3100,
	TERRORIST_FULL_BUY = 3700,
	TERRORIST_FORCE_BUY = 2500,
	TERRORIST_RIFLE_BUY = 2700
}

--- @class PlayerEconomy
--- @field eid number
--- @field player Player
--- @field balance number
--- @field fullBuys number
--- @field isAllowedToForceBuy number
--- @field isAbleToBuy boolean
--- @field isAbleToDrop boolean
--- @field isGearedUp boolean
--- @field isAbleToBuyArmor boolean
--}}}

--{{{ AiRoutineManageEconomy
--- @class AiRoutineManageEconomy : AiRoutineBase
--- @field isEnabled boolean
--- @field economies PlayerEconomy[]
--- @field ourEconomy PlayerEconomy
local AiRoutineManageEconomy = {}

--- @param fields AiRoutineManageEconomy
--- @return AiRoutineManageEconomy
function AiRoutineManageEconomy:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineManageEconomy:__init()
	self.isEnabled = true

	Callbacks.roundStart(function()
		if not self.isEnabled then
			return
		end

		if not MenuGroup.enableAi:get() then
			return
		end

		if self.ai.reaper.isActive then
			return
		end

		Client.fireAfter(0.1, function()
			self:determineEconomy()
			self:handleEconomy()
		end)
	end)
end

--- @return void
function AiRoutineManageEconomy:determineEconomy()
	--- @type PlayerEconomy[]
	local economies = {}
	local fullBuyThreshold = LocalPlayer:isTerrorist() and BuyCriteria.TERRORIST_FULL_BUY or BuyCriteria.COUNTER_TERRORIST_FULL_BUY
	local forceBuyThreshold = LocalPlayer:isTerrorist() and BuyCriteria.TERRORIST_FORCE_BUY or BuyCriteria.COUNTER_TERRORIST_FORCE_BUY
	local rifleBuyThreshold = LocalPlayer:isTerrorist() and BuyCriteria.TERRORIST_RIFLE_BUY or BuyCriteria.COUNTER_TERRORIST_RIFLE_BUY

	for _, teammate in pairs(AiUtility.teammatesAndClient) do
		--- @type PlayerEconomy
		local economy = {
			eid = teammate.eid,
			player = teammate,
			balance = teammate:m_iAccount(),
			isGearedUp = teammate:hasWeapons(WeaponInfo.primaries)
		}

		local fullBuys = 0
		local fullBuyBalance = economy.balance

		if fullBuyBalance > fullBuyThreshold then
			fullBuys = 1 + math.floor((economy.balance - fullBuyThreshold) / rifleBuyThreshold)
		end

		local forceBuys = math.floor(economy.balance / forceBuyThreshold)

		economy.fullBuys = fullBuys

		if fullBuys > 0 then
			economy.isAbleToBuy = true
		end

		if fullBuys > (economy.isGearedUp and 0 or 1) then
			economy.isAbleToDrop = true
		end

		if fullBuys == 0 and forceBuys > 0 then
			economy.isAllowedToForceBuy = true
		end

		if economy.balance >= 1000 then
			economy.isAbleToBuyArmor = true
		end

		table.insert(economies, economy)

		if teammate.eid == LocalPlayer.eid then
			self.ourEconomy = economy
		end
	end

	self.economies = economies
end

--- @return void
function AiRoutineManageEconomy:handleEconomy()
	local rounds = AiUtility.gameRules:m_totalRoundsPlayed()
	local maxRounds = cvar.mp_maxrounds:get_int()
	local halftime = math.floor(maxRounds / 2)
	local isPistolRound = rounds == 0 or rounds == halftime
	local isPostPistolRound = rounds == 1 or rounds == halftime + 1
	local scoreData = Table.fromPanorama(Panorama.GameStateAPI.GetScoreDataJSO())
	local tWins = scoreData.teamdata.TERRORIST.score
	local ctWins = scoreData.teamdata.CT.score

	local isCounterTerroristMatchPoint = ctWins == halftime
	local isTerroristMatchPoint = tWins == halftime
	local isOurMatchPoint = false
	local isEnemyMatchPoint = false
	local isLastOfHalf = rounds == (halftime - 1)
	local isLastOfGame = rounds == maxRounds

	if LocalPlayer:isCounterTerrorist() then
		isOurMatchPoint = isCounterTerroristMatchPoint
		isEnemyMatchPoint = isTerroristMatchPoint
	elseif LocalPlayer:isTerrorist() then
		isOurMatchPoint = isTerroristMatchPoint
		isEnemyMatchPoint = isCounterTerroristMatchPoint
	end

	-- We have to buy this round.
	if isEnemyMatchPoint or isLastOfHalf or isLastOfGame then
		self:determineForceBuyOrDrop()

		return
	end

	-- Do not manage the economy on the first-of-half or second-after-pistol rounds.
	if isPistolRound or isPostPistolRound then
		return
	end

	local totalPlayers = #self.economies
	local playersWhoCanFullBuy = 0
	local playersWhoCanForceBuy = 0
	local playersWhoCanBuyArmor = 0

	for _, economy in pairs(self.economies) do
		if economy.isGearedUp then
			-- Count players who spawned with primary weapons as a full buy.
			playersWhoCanFullBuy = playersWhoCanFullBuy + 1
		elseif economy.fullBuys > 0 then
			-- This player is able to purchase at least 1 full buy.
			playersWhoCanFullBuy = playersWhoCanFullBuy + 1
		elseif economy.isAllowedToForceBuy then
			playersWhoCanForceBuy = playersWhoCanForceBuy + 1
		end

		if economy.isAbleToBuyArmor then
			playersWhoCanBuyArmor = playersWhoCanBuyArmor + 1
		end
	end

	-- This comes out to 2 full buys + 3 force buys in a standard 5v5 to trigger the AI unable to full-buy to force-buy.
	-- How many full buys are required when force buying.
	local forceBuyThresholdFullCriterion = math.floor(totalPlayers / 2)
	-- How many force buys are required when force buying.
	local forceBuyThresholdForceCriterion = totalPlayers - forceBuyThresholdFullCriterion

	if playersWhoCanFullBuy == totalPlayers then
		Logger.console(Logger.ALERT, Localization.manageEconomyFullBuy)
	elseif playersWhoCanFullBuy >= forceBuyThresholdFullCriterion and (playersWhoCanForceBuy + playersWhoCanBuyArmor) >= forceBuyThresholdForceCriterion then
		self:determineForceBuyOrDrop()

		Logger.console(Logger.ALERT, Localization.manageEconomyForceBuy)
	else
		-- Randomly decide to eco-rush instead of a standard save.
		if AiUtility.getPredictableChance(2) then
			self.ai.routines.buyGear:ecoRush()

			Logger.console(Logger.ALERT, Localization.manageEconomyEcoRush)
		else
			self.ai.routines.buyGear:save()

			Logger.console(Logger.ALERT, Localization.manageEconomyEco)
		end
	end
end

--- @return boolean
function AiRoutineManageEconomy:determineForceBuyOrDrop()
	-- We aren't poor.
	if self.ourEconomy.fullBuys > 0 then
		return
	end

	-- We have a weapon already.
	if self.ourEconomy.isGearedUp then
		return
	end

	--- @type PlayerEconomy[]
	local richestPlayers = {}
	--- @type PlayerEconomy[]
	local poorestPlayers = {}

	-- Determine richest players who can drop and poorest players who need drops.
	for _, economy in pairs(self.economies) do
		if economy.fullBuys >= 2 then
			table.insert(richestPlayers, economy)
		end

		if economy.fullBuys == 0 then
			table.insert(poorestPlayers, economy)
		end
	end

	-- Sort richest descending by balance.
	table.sort(richestPlayers, function(a, b)
		return a.balance > b.balance
	end)

	-- Sort poorest ascending by balance.
	table.sort(poorestPlayers, function(a, b)
		return a.balance < b.balance
	end)

	local ourIdx

	for k, economy in pairs(poorestPlayers) do
		if economy.eid == LocalPlayer.eid then
			ourIdx = k
		end
	end

	local poorIdx = 0
	--- @type Player
	local target
	-- How long to wait before calling /drop.
	local barkDelay = 0

	-- Figure out which rich guy we're going to beg.
	-- The original comment above said "bed". Prostitution is illegal. Albeit may have the same wanted result.
	for _, economy in pairs(richestPlayers) do
		if target then
			break
		end

		for i = 1, economy.fullBuys do
			poorIdx = poorIdx + 1

			if poorIdx == ourIdx then
				target = economy.player
				barkDelay = (i - 1) * 2.4

				break
			end
		end
	end

	-- Ran out of rich people to beg.
	-- Going to just have to buy an SMG or something.
	if not target then
		self.ai.routines.buyGear:force()

		return
	end

	Client.fireAfter(barkDelay, function()
		self.ai.routines.buyGear:receiveDrop()
		self.ai.commands.drop:bark(target:getName())
	end)
end

return Nyx.class("AiRoutineManageEconomy", AiRoutineManageEconomy, AiRoutineBase)
--}}}
