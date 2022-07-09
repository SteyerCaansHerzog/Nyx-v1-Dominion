--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local WeaponInfo = require "gamesense/Nyx/v1/Dominion/Ai/Info/WeaponInfo"
--}}}

--{{{ Definitions
local Buy = {
	GLOCK = "glock",
	HKP2000 = "hkp2000",
	USP_SILENCER = "usp_silencer",
	ELITE = "elite",
	P250 = "p250",
	TEC9 = "tec9",
	FN57 = "fn57",
	DEAGLE = "deagle",
	GALILAR = "galilar",
	FAMAS = "famas",
	AK47 = "ak47",
	M4A1 = "m4a1",
	M4A1_SILENCER = "m4a1_silencer",
	SSG08 = "ssg08",
	AUG = "aug",
	SG556 = "sg556",
	AWP = "awp",
	SCAR20 = "scar20",
	G3SG1 = "g3sg1",
	NOVA = "nova",
	XM1014 = "xm1014",
	MAG7 = "mag7",
	M249 = "m249",
	NEGEV = "negev",
	MAC10 = "mac10",
	MP9 = "mp9",
	MP7 = "mp7",
	UMP45 = "ump45",
	P90 = "p90",
	BIZON = "bizon",
	VEST = "vest",
	VESTHELM = "vesthelm",
	TASER = "taser",
	DEFUSER = "defuser",
	HEAVYARMOR = "heavyarmor",
	MOLOTOV = "molotov",
	INCGRENADE = "incgrenade",
	DECOY = "decoy",
	FLASHBANG = "flashbang",
	HEGRENADE = "hegrenade",
	SMOKEGRENADE = "smokegrenade",
}

local BuyCriteria = {
	COUNTER_TERRORIST_FULL_BUY = 3100,
	COUNTER_TERRORIST_SMG_BUY = 2000,
	TERRORIST_FULL_BUY = 2800,
	TERRORIST_SMG_BUY = 2000,
}

--- @class GearSet
--- @field chance number
--- @field balance number
--- @field queue fun(): void

--- @class BuyQueue
--- @field buy fun(): void
--- @field after number
--}}}

--{{{ AiRoutineBuyGear
--- @class AiRoutineBuyGear : AiRoutineBase
--- @field balance number
--- @field buyItemList string[]
--- @field buyQueue BuyQueue[]
--- @field customItemList string[]
--- @field isBeingDropped boolean
--- @field isEnabled boolean
--- @field isForcing boolean
--- @field isProcessingQueue boolean
--- @field isQueued boolean
--- @field isRushing boolean
--- @field isSaving boolean
--- @field processQueueTimer Timer
local AiRoutineBuyGear = {}

--- @param fields AiRoutineBuyGear
--- @return AiRoutineBuyGear
function AiRoutineBuyGear:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineBuyGear:__init()
	self.buyItemList = {}
	self.buyQueue = {}
	self.processQueueTimer = Timer:new()

	Callbacks.init(function()
		if not Server.isIngame() then
			return
		end

		if AiUtility.gameRules:m_bFreezePeriod() == 0 then
			return
		end

		self.balance = LocalPlayer:m_iAccount()

		self:buyRoundStart()
		self:createBuyQueue()
	end)

	Callbacks.roundStart(function()
		if not self.isEnabled then
			return
		end

		Client.onNextTick(function()
			self.buyItemList = {}
			self.isQueued = false
			self.isProcessingQueue = false
			self.balance = LocalPlayer:m_iAccount()

			local freezetime = cvar.mp_freezetime:get_int()
			local minDelay = freezetime * 0.4
			local maxDelay = freezetime * 0.9

			Client.fireAfterRandom(minDelay, maxDelay, function()
				self:buyRoundStart()
				self:createBuyQueue()
			end)
		end)
	end)

	Callbacks.roundEnd(function()
		-- Reset saving if given randomly during the previous round.
		-- The AI should only respond to /eco for the oncoming round.
		self.isSaving = false
		self.isRushing = false
		self.isForcing = false
	end)

	Callbacks.setupCommand(function()
		self:processBuyQueue()
	end)
end

--- @return boolean
function AiRoutineBuyGear:isAlreadyGearedUpAndBuyMisc()
	local isGearedUp = LocalPlayer:hasWeapons(WeaponInfo.primaries)

	if isGearedUp then
		self:equipFullArmor()
		self:equipRandomGrenades(nil, self.balance > 6500 and 4 or 3)
	end

	return isGearedUp
end

--- @param itemNames string
function AiRoutineBuyGear:setCustomItemList(itemNames)
	self.customItemList = Table.getExplodedString(itemNames, ",")
end

--- @return void
function AiRoutineBuyGear:resetCustomItemList()
	self.customItemList = nil
end

--- @return void
function AiRoutineBuyGear:save()
	self.isSaving = true
end

--- @return void
function AiRoutineBuyGear:force()
	self.isForcing = true
end

--- @return void
function AiRoutineBuyGear:ecoRush()
	self.isRushing = true
end

--- @return void
function AiRoutineBuyGear:receiveDrop()
	self.isBeingDropped = true
end

--- @return void
function AiRoutineBuyGear:pickup()
	self:equipFullArmor()

	if LocalPlayer:isTerrorist() then
		self:equipRandomGrenades(nil, 4)
	elseif LocalPlayer:isCounterTerrorist() then
		self:equipRandomGrenades(nil, 2)
		self:equipDefuseKit()
	end
end

--- @return void
function AiRoutineBuyGear:pauseQueue()
	self.processQueueTimer:pause()
end

--- @return void
function AiRoutineBuyGear:createBuyQueue()
	if not LocalPlayer:isAlive() then
		return
	end

	self.buyQueue = {}

	local i = 0

	for j, item in pairs(self.buyItemList) do
		local intervalMin = i * 0.2
		local intervalMax = intervalMin + Math.getRandomFloat(0, 0.12)

		table.insert(self.buyQueue, {
			buy = function()
				Client.execute("buy %s", item)
				Logger.console(-1, Localization.buyGearPurchased, j, item)
			end,
			after = Math.getRandomFloat(intervalMin, intervalMax)
		})

		i = i + 1
	end

	self.isProcessingQueue = true
	self.buyItemList = {}
end

--- @return void
function AiRoutineBuyGear:processBuyQueue()
	if not self.isProcessingQueue then
		return
	end

	for id, item in pairs(self.buyQueue) do repeat
		if not self.processQueueTimer:isElapsed(item.after) then
			break
		end

		Client.fireAfter(item.after, function()
			item.buy()
		end)

		self.buyQueue[id] = nil
	until true end

	self.processQueueTimer:ifPausedThenStart()
end

--- @param item string
function AiRoutineBuyGear:queue(item)
	if not item then
		return
	end

	table.insert(self.buyItemList, item)

	self.isQueued = true
end

--- @param gearSets GearSet[]
--- @return void
function AiRoutineBuyGear:activateHighestChanceFrom(gearSets)
	for _, set in Table.sortedPairs(gearSets, function(a, b)
		return a.chance > b.chance
	end) do repeat
		if self.balance < set.balance then
			break
		end

		if not Math.getChance(set.chance) then
			break
		end

		set.queue()

		return
	until true end

	Logger.console(1, "Tried to purchase from best set, except there was no best set to buy.")
end

--- @param gearSets GearSet[]
--- @return void
function AiRoutineBuyGear:activateAnyPassingFrom(gearSets)
	--- @type GearSet[]
	local passingSets = {}
	--- @type GearSet
	local bestOneInOneSet
	local bestOneInOnePrice = -1

	for _, set in pairs(gearSets) do repeat
		if self.balance < set.balance then
			break
		end

		if not Math.getChance(set.chance) then
			break
		end

		if set.chance == 1 then
			if set.balance > bestOneInOnePrice then
				bestOneInOneSet = set
				bestOneInOnePrice = set.balance
			end
		else
			table.insert(passingSets, set)
		end
	until true end

	local randomSet = not Table.isEmpty(passingSets) and Table.getRandom(passingSets) or bestOneInOneSet

	if not randomSet then
		Logger.console(1, "Tried to purchase from any set, except there was no set to buy.")

		return
	end

	randomSet.queue()
end

--- @return void
function AiRoutineBuyGear:buyRoundStart()
	if self.isQueued then
		return
	end

	-- AI was told to save this round.
	if self.isSaving then
		self.isSaving = false

		return
	end

	if self.isForcing then
		self.isForcing = false

		self:buyCounterTerroristForceRound()
	end

	-- Buy from custom items list.
	if self.customItemList then
		self:equipWeapons(self.customItemList)

		return
	end

	-- AI requested to be dropped. Top up on armour and utility.
	if self.isBeingDropped then
		self.isBeingDropped = false

		if LocalPlayer:isTerrorist() then
			self:buyTerroristFromDrop()
		elseif LocalPlayer:isCounterTerrorist() then
			self:buyCounterTerroristFromDrop()
		end

		return
	end

	self.balance = LocalPlayer:m_iAccount()

	local rounds = AiUtility.gameRules:m_totalRoundsPlayed()
	local halftime = math.floor(cvar.mp_maxrounds:get_int() / 2)
	local isPistolRound = rounds == 0 or rounds == halftime
	local isPostPistolRound = rounds == 1 or rounds == halftime + 1

	if LocalPlayer:isTerrorist() then
		if isPistolRound then
			self:buyTerroristPistolRound()
		elseif isPostPistolRound then
			self:buyTerroristPostPistolRound()
		elseif self.isRushing then
			self:buyTerroristEcoRushRound()
		else
			self:buyTerroristFullBuyRound()
		end
	elseif LocalPlayer:isCounterTerrorist() then
		if isPistolRound then
			self:buyCounterTerroristPistolRound()
		elseif isPostPistolRound then
			self:buyCounterTerroristPostPistolRound()
		elseif self.isRushing then
			self:buyTerroristEcoRushRound()
		else
			self:buyCounterTerroristFullBuyRound()
		end
	end
end

--- @return void
function AiRoutineBuyGear:buyEcoRushRound()
	if LocalPlayer:isTerrorist() then
		self:buyTerroristEcoRushRound()
	elseif LocalPlayer:isCounterTerrorist() then
		self:buyCounterTerroristEcoRushRound()
	end
end

--- @return void
function AiRoutineBuyGear:buyForceRound()
	if LocalPlayer:isTerrorist() then
		self:buyTerroristForceRound()
	elseif LocalPlayer:isCounterTerrorist() then
		self:buyCounterTerroristForceRound()
	end
end

--- @return void
function AiRoutineBuyGear:buyTerroristFromDrop()
	self:equipFullArmor()
	self:equipRandomGrenades(nil, 4)
end

--- @return void
function AiRoutineBuyGear:buyTerroristPistolRound()
	self:activateHighestChanceFrom({
		{
			balance = 0,
			chance = 20,
			queue = function()
				self:equipWeapon(Buy.DEAGLE)
			end
		},
		{
			balance = 0,
			chance = 8,
			queue = function()
				self:equipWeapon(Buy.TEC9)
				self:equipRandomGrenades({Buy.FLASHBANG, Buy.SMOKEGRENADE}, 1)
			end
		},
		{
			balance = 0,
			chance = 2,
			queue = function()
				self:equipWeapon(Buy.P250)
				self:equipRandomGrenades({Buy.FLASHBANG, Buy.SMOKEGRENADE})
			end
		},
		{
			balance = 0,
			chance = 1,
			queue = function()
				self:equipLightArmor()
			end
		},
	})
end

--- @return void
function AiRoutineBuyGear:buyTerroristPostPistolRound()
	if self.balance > BuyCriteria.TERRORIST_FULL_BUY then
		self:buyTerroristFullBuyRound()

		return
	end

	self:activateHighestChanceFrom({
		{
			balance = 2150,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.MP7)
				self:equipLightArmor()
				self:equipRandomGrenades()
			end
		},
		{
			balance = 1850,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.UMP45)
				self:equipLightArmor()
				self:equipRandomGrenades()
			end
		},
		{
			balance = 1700,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.MAC10)
				self:equipLightArmor()
				self:equipRandomGrenades()
			end
		},
		{
			balance = 0,
			chance = 3,
			queue = function()
				self:equipWeapon(Buy.DEAGLE)
				self:equipFullArmor()
				self:equipRandomGrenades()
			end
		},
		{
			balance = 0,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.TEC9)
				self:equipFullArmor()
				self:equipRandomGrenades()
			end
		}
	})
end

--- @return void
function AiRoutineBuyGear:buyTerroristForceRound()
	if self:isAlreadyGearedUpAndBuyMisc() then
		return
	end

	self:buyTerroristPostPistolRound()
end

--- @return void
function AiRoutineBuyGear:buyTerroristEcoRushRound()
	if self:isAlreadyGearedUpAndBuyMisc() then
		return
	end

	self:activateHighestChanceFrom({
		{
			balance = 0,
			chance = 3,
			queue = function()
				self:equipWeapon(Buy.TEC9)
			end
		},
		{
			balance = 0,
			chance = 2,
			queue = function()
				self:equipWeapon(Buy.P250)
				self:equipGrenades({
					Buy.FLASHBANG
				})
			end
		},
		{
			balance = 0,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.P250)
			end
		},
	})
end

--- @return void
function AiRoutineBuyGear:buyTerroristFullBuyRound()
	if self:isAlreadyGearedUpAndBuyMisc() then
		return
	end

	self:activateAnyPassingFrom({
		{
			balance = 6000,
			chance = 4,
			queue = function()
				self:equipWeapon(Buy.AWP)
			end
		},
		{
			balance = 4000,
			chance = 10,
			queue = function()
				self:equipWeapon(Buy.SG556)
			end
		},
		{
			balance = 3700,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.AK47)
			end
		},
		{
			balance = BuyCriteria.TERRORIST_FULL_BUY,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.GALILAR)
			end
		}
	})

	self:equipFullArmor()
	self:equipRandomGrenades(nil, self.balance > 6500 and 4 or 3)
end

--- @return void
function AiRoutineBuyGear:buyCounterTerroristFromDrop()
	self:equipFullArmor()

	self:equipRandomGrenades({
		Buy.FLASHBANG, Buy.SMOKEGRENADE
	}, 2)

	self:equipDefuseKit()

	self:equipRandomGrenades({
		Buy.HEGRENADE,
		Buy.INCGRENADE
	}, 2)
end

--- @return void
function AiRoutineBuyGear:buyCounterTerroristPistolRound()
	self:activateHighestChanceFrom({
		{
			balance = 0,
			chance = 20,
			queue = function()
				self:equipWeapon(Buy.DEAGLE)
			end
		},
		{
			balance = 0,
			chance = 4,
			queue = function()
				self:equipWeapon(Buy.ELITE)
				self:equipRandomGrenades({Buy.FLASHBANG, Buy.SMOKEGRENADE})
			end
		},
		{
			balance = 0,
			chance = 3,
			queue = function()
				self:equipWeapon(Buy.ELITE)
				self:equipDefuseKit()
			end
		},
		{
			balance = 0,
			chance = 3,
			queue = function()
				self:equipWeapon(Buy.P250)
				self:equipDefuseKit()
			end
		},
		{
			balance = 0,
			chance = 2,
			queue = function()
				self:equipWeapon(Buy.P250)
				self:equipRandomGrenades({Buy.FLASHBANG, Buy.SMOKEGRENADE})
			end
		},
		{
			balance = 0,
			chance = 1,
			queue = function()
				self:equipLightArmor()
			end
		},
	})
end

--- @return void
function AiRoutineBuyGear:buyCounterTerroristPostPistolRound()
	if self.balance >= BuyCriteria.COUNTER_TERRORIST_FULL_BUY then
		self:buyCounterTerroristFullBuyRound()

		return
	end

	self:activateHighestChanceFrom({
		{
			balance = 2150,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.MP7)
				self:equipLightArmor()
				self:equipRandomGrenades()
			end
		},
		{
			balance = 1900,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.MP9)
				self:equipLightArmor()
				self:equipRandomGrenades()
			end
		},
		{
			balance = 1850,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.UMP45)
				self:equipLightArmor()
				self:equipRandomGrenades()
			end
		},
		{
			balance = 0,
			chance = 3,
			queue = function()
				self:equipWeapon(Buy.DEAGLE)
				self:equipFullArmor()
				self:equipRandomGrenades()
			end
		},
		{
			balance = 0,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.FN57)
				self:equipFullArmor()
				self:equipRandomGrenades()
			end
		}
	})
end

--- @return void
function AiRoutineBuyGear:buyCounterTerroristForceRound()
	if self:isAlreadyGearedUpAndBuyMisc() then
		return
	end

	self:buyCounterTerroristPostPistolRound()
end

--- @return void
function AiRoutineBuyGear:buyCounterTerroristEcoRushRound()
	if self:isAlreadyGearedUpAndBuyMisc() then
		return
	end

	self:activateHighestChanceFrom({
		{
			balance = 0,
			chance = 2,
			queue = function()
				self:equipWeapon(Buy.P250)
				self:equipGrenades({
					Buy.FLASHBANG
				})
			end
		},
		{
			balance = 0,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.P250)
			end
		},
	})
end

--- @return void
function AiRoutineBuyGear:buyCounterTerroristFullBuyRound()
	if self:isAlreadyGearedUpAndBuyMisc() then
		return
	end

	self:activateAnyPassingFrom({
		{
			balance = 6000,
			chance = 4,
			queue = function()
				self:equipWeapon(Buy.AWP)
			end
		},
		{
			balance = 4600,
			chance = 2,
			queue = function()
				self:equipWeapon(Buy.AUG)
			end
		},
		{
			balance = 4100,
			chance = 1,
			queue = function()
				self:equipWeapon(string.format("%s;%s", Buy.M4A1, Buy.M4A1_SILENCER))
			end
		},
		{
			balance = BuyCriteria.COUNTER_TERRORIST_FULL_BUY,
			chance = 1,
			queue = function()
				self:equipWeapon(Buy.FAMAS)
			end
		}
	})

	self:equipFullArmor()

	self:equipRandomGrenades({
		Buy.FLASHBANG, Buy.SMOKEGRENADE
	}, 2)

	self:equipDefuseKit()

	self:equipRandomGrenades({
		Buy.HEGRENADE,
		Buy.INCGRENADE
	}, 2)
end

--- @param item string
--- @return void
function AiRoutineBuyGear:equipWeapon(item)
	self:queue(item)
end

--- @param items string[]
--- @return void
function AiRoutineBuyGear:equipWeapons(items)
	for _, item in pairs(items) do
		self:queue(item)
	end
end

--- @return void
function AiRoutineBuyGear:equipRandomWeapon(items)
	self:queue(Table.getRandom(items))
end

--- @param items string[]
--- @return void
function AiRoutineBuyGear:equipGrenades(items)
	items = self:getCleanGrenades(items)

	for _, item in pairs(items) do
		self:queue(item)
	end
end

--- @param items string[]
--- @return void
function AiRoutineBuyGear:equipRandomGrenades(items, max)
	max = max or 4
	items = self:getCleanGrenades(items)
	items = Table.getShuffled(items)

	local i = 0

	for _, item in pairs(items) do
		if i == max then
			break
		end

		self:queue(item)

		i = i + 1
	end
end

--- @param items string[]
--- @return string[]
function AiRoutineBuyGear:getCleanGrenades(items)
	if not items then
		items = {
			Buy.SMOKEGRENADE,
			Buy.FLASHBANG,
			Buy.MOLOTOV,
			Buy.HEGRENADE
		}
	end

	local map = Table.getMap(items)

	if LocalPlayer:isTerrorist() and map[Buy.INCGRENADE] then
		items[map[Buy.INCGRENADE]] = Buy.MOLOTOV
	elseif LocalPlayer:isCounterTerrorist() and map[Buy.MOLOTOV] then
		items[map[Buy.MOLOTOV]] = Buy.INCGRENADE
	end

	return items
end

--- @return void
function AiRoutineBuyGear:equipLightArmor()
	if LocalPlayer:m_iArmor() > 33 then
		return
	end

	self:queue(Buy.VEST)
end

--- @return void
function AiRoutineBuyGear:equipFullArmor()
	if LocalPlayer:m_iArmor() > 33 then
		return
	end

	self:queue(Buy.VESTHELM)
end

--- @return void
function AiRoutineBuyGear:equipDefuseKit()
	if LocalPlayer:m_bHasDefuser() == 1 then
		return
	end

	self:queue(Buy.DEFUSER)
end

return Nyx.class("AiRoutineBuyGear", AiRoutineBuyGear, AiRoutineBase)
--}}}
