--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiRoutineBase = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutineBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local WeaponInfo = require "gamesense/Nyx/v1/Dominion/Ai/Info/WeaponInfo"
--}}}

--{{{ Enums
local WeaponBuyCode = {
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
--}}}

--{{{ Definitions
--- @class AiRoutineBuyGearSet
--- @field chance number
--- @field balance number
--- @field callback fun(): nil
--}}}

--{{{ AiRoutineBuyGear
--- @class AiRoutineBuyGear : AiRoutineBase
--- @field isBuyingThisRound boolean
--- @field isInterrupted boolean
--- @field isEnabled boolean
local AiRoutineBuyGear = {}

--- @param fields AiRoutineBuyGear
--- @return AiRoutineBuyGear
function AiRoutineBuyGear:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiRoutineBuyGear:__init()
	self.isBuyingThisRound = true

	Callbacks.init(function()
		if not Server.isIngame() then
			return
		end

		if AiUtility.gameRules:m_bFreezePeriod() == 1 then
			self:buyGear()
		end
	end)

	Callbacks.roundStart(function()
		if not self.isEnabled then
			return
		end
		
		self.isInterrupted = false

		local freezeTime = cvar.mp_freezetime:get_int()
		local minDelay = freezeTime * 0.6
		local maxDelay = freezeTime * 0.8

		Client.fireAfterRandom(minDelay, maxDelay, function()
			if not self.isInterrupted then
				self:buyGear()
			end
		end)
	end)

	Callbacks.itemEquip(function(e)
		if not self.isEnabled then
			return
		end

		if self.isArmorBuyBlocked then
			return
		end

		if not e.player:isClient() then
			return
		end

		if not LocalPlayer:hasWeapons(WeaponInfo.primaries) then
			return
		end

		if AiUtility.timeData.roundtime_elapsed > cvar.mp_buytime:get_int() then
			return
		end

		self:equipBodyArmor()
	end)
end

--- @return void
function AiRoutineBuyGear:blockThisRound()
	self.isBuyingThisRound = false
end

--- @return void
function AiRoutineBuyGear:buyGear()
	if AiUtility.timeData.roundtime_elapsed > cvar.mp_buytime:get_int() then
		return
	end

	self.isInterrupted = true

	-- Place this here to allow telling the AI to eco this round.
	if not self.isBuyingThisRound then
		-- Buy next round.
		self.isBuyingThisRound = true

		return
	end

	local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
	local halftimeRounds = math.floor(cvar.mp_maxrounds:get_int() / 2)
	local balance = LocalPlayer:m_iAccount()

	-- 2nd-round buy.
	if roundsPlayed == 1 or roundsPlayed == halftimeRounds + 1 and balance < 3100 then
		self:buyForceRound()

		return
	end

	local isPistolRound = balance < 1000 and (roundsPlayed == 0 or roundsPlayed == halftimeRounds)

	if LocalPlayer:isTerrorist() then
		if isPistolRound then
			self:buyPistolRoundTerrorist()
		else
			self:buyRoundTerrorist()
		end
	elseif LocalPlayer:isCounterTerrorist() then
		if isPistolRound then
			self:buyPistolRoundCounterTerrorist()
		else
			self:buyRoundCounterTerrorist()
		end
	end
end

--- Will not be executed if the AI has enough money for a normal buy ($3100).
---
--- Automatically invoked on the 2nd round of a half.
---
--- @return void
function AiRoutineBuyGear:buyForceRound()
	local balance = LocalPlayer:m_iAccount()

	if balance < 1500 then
		self:equipRandomWeapon({
			WeaponBuyCode.FN57,
			WeaponBuyCode.DEAGLE,
			LocalPlayer:isTerrorist() and WeaponBuyCode.MAC10 or WeaponBuyCode.MP9
		})

		self:equipRandomGrenades(1)
	else
		self:equipRandomWeapon({
			WeaponBuyCode.MP7,
			WeaponBuyCode.UMP45,
			WeaponBuyCode.NEGEV
		})

		self:equipBodyArmor()
		self:equipRandomGrenades(2)
	end
end

--- @return void
function AiRoutineBuyGear:buyEcoRush()
	local buys = {
		function()
			self:equipRandomWeapon({ WeaponBuyCode.P250, WeaponBuyCode.ELITE, WeaponBuyCode.FN57 })
		end,
		function()
			self:equipWeapon(WeaponBuyCode.P250)
			self:equipGrenades({WeaponBuyCode.FLASHBANG})
		end
	}

	Table.getRandom(buys)()
end

--- @return void
function AiRoutineBuyGear:buyPistolRoundTerrorist()
	local buys = {
		function()
			self:equipRandomWeapon({ WeaponBuyCode.P250, WeaponBuyCode.TEC9})
			self:equipGrenades({ WeaponBuyCode.FLASHBANG, WeaponBuyCode.SMOKEGRENADE, WeaponBuyCode.MOLOTOV}, true)
		end,
		function()
			self:equipBodyArmor()
		end
	}

	Table.getRandom(buys)()
end

--- @return void
function AiRoutineBuyGear:buyPistolRoundCounterTerrorist()
	local buys = {
		function()
			self:equipDefuser()
			self:equipRandomGrenades(1)
		end,
		function()
			self:equipRandomWeapon({WeaponBuyCode.P250, WeaponBuyCode.FN57})
			self:equipGrenades({WeaponBuyCode.FLASHBANG, WeaponBuyCode.SMOKEGRENADE}, true)
		end,
		function()
			self:equipBodyArmor()
		end
	}

	Table.getRandom(buys)()
end

--- @return void
function AiRoutineBuyGear:buyRoundTerrorist()
	--- @type AiRoutineBuyGearSet[]
	local buys = {
		{
			chance = 2,
			balance = 6000,
			callback = function()
				self:equipWeapon(WeaponBuyCode.AWP)
			end
		},
		{
			chance = 4,
			balance = 5000,
			callback = function()
				self:equipWeapon(WeaponBuyCode.SG556)
			end
		},
		{
			chance = 1,
			balance = 4000,
			callback = function()
				self:equipWeapon(WeaponBuyCode.AK47)
			end
		},
		{
			chance = 1,
			balance = 3100,
			callback = function()
				self:equipWeapon(WeaponBuyCode.GALILAR)
			end
		}
	}

	if not LocalPlayer:hasWeapons(WeaponInfo.primaries) then
		self:buySet(buys)
	end

	self:equipFullArmor()

	local balance = LocalPlayer:m_iAccount()
	local grenades = balance > 5000 and 4 or Math.getRandomInt(2, 4)

	self:equipRandomGrenades(grenades)
end

--- @return void
function AiRoutineBuyGear:buyRoundCounterTerrorist()
	--- @type AiRoutineBuyGearSet[]
	local buys = {
		{
			chance = 2,
			balance = 6200,
			callback = function()
				self:equipWeapon(WeaponBuyCode.AWP)
			end
		},
		{
			chance = 2,
			balance = 5000,
			callback = function()
				self:equipWeapon(WeaponBuyCode.AUG)
			end
		},
		{
			chance = 1,
			balance = 4500,
			callback = function()
				self:equipWeapon(WeaponBuyCode.M4A1)
			end
		},
		{
			chance = 1,
			balance = 3100,
			callback = function()
				self:equipWeapon(WeaponBuyCode.FAMAS)
			end
		}
	}

	self:equipBodyArmor()

	if not LocalPlayer:hasWeapons(WeaponInfo.primaries) then
		self:buySet(buys)
		self:equipDefuser()
	end

	self:equipFullArmor()

	local balance = LocalPlayer:m_iAccount()
	local grenades = balance > 5000 and 4 or Math.getRandomInt(2, 4)

	self:equipRandomGrenades(grenades)
end

--- @param buys AiRoutineBuyGearSet[]
--- @return void
function AiRoutineBuyGear:buySet(buys)
	local balance = LocalPlayer:m_iAccount()

	--- @type AiRoutineBuyGearSet
	local uncertainBuys = {}
	--- @type AiRoutineBuyGearSet
	local certainBuys = {}

	for _, buy in pairs(buys) do
		if balance >= buy.balance and Math.getChance(buy.chance) then
			if buy.chance == 1 then
				table.insert(certainBuys, buy)
			else
				table.insert(uncertainBuys, buy)
			end
		end
	end

	--- @type AiRoutineBuyGearSet
	local highestCertainBuy
	local highestBalance = -1

	for _, buy in pairs(certainBuys) do
		if buy.balance > highestBalance then
			highestBalance = buy.balance
			highestCertainBuy = buy
		end
	end

	if not Table.isEmpty(uncertainBuys) then
		--- @type AiRoutineBuyGearSet
		local mergedBuys = Table.new(uncertainBuys, {highestCertainBuy})

		Table.getRandom(mergedBuys).callback()
	elseif highestCertainBuy then
		highestCertainBuy.callback()
	end
end

--- @return void
function AiRoutineBuyGear:equipBodyArmor()
	Client.fireAfterRandom(0, 2, function()
		if LocalPlayer:m_iArmor() > 33 then
			return
		end

		Client.execute("buy vest")
		Logger.console(-1, "Equipped vest.")
	end)
end

--- @return void
function AiRoutineBuyGear:equipFullArmor()
	Client.fireAfterRandom(1, 2, function()
		if LocalPlayer:m_iArmor() > 33 then
			return
		end

		Client.execute("buy vesthelm")
		Logger.console(-1, "Equipped vesthelm.")
	end)
end

--- @return void
function AiRoutineBuyGear:equipDefuser()
	Client.fireAfterRandom(1, 2, function()
		Client.execute("buy defuser")
		Logger.console(-1, "Equipped defuser.")
	end)
end

--- @param maxGrenades number
--- @return void
function AiRoutineBuyGear:equipRandomGrenades(maxGrenades)
	Client.fireAfterRandom(1, 2, function()
		local grenades = {
			WeaponBuyCode.FLASHBANG,
			WeaponBuyCode.SMOKEGRENADE,
			WeaponBuyCode.HEGRENADE,
			LocalPlayer:isTerrorist() and WeaponBuyCode.MOLOTOV or WeaponBuyCode.INCGRENADE
		}

		grenades = Table.getShuffled(grenades)

		local iGrenade = 0

		for _, grenade in pairs(grenades) do
			if iGrenade == maxGrenades then
				break
			end

			Client.execute(string.format("buy %s", grenade))
			Logger.console(-1, "Equipped %s.", grenade)

			iGrenade = iGrenade + 1
		end
	end)
end

--- @param grenades string[]
--- @param isRandomized boolean
--- @param maxGrenades number
--- @return void
function AiRoutineBuyGear:equipGrenades(grenades, isRandomized, maxGrenades)
	maxGrenades = maxGrenades or 4

	Client.fireAfterRandom(1, 2, function()
		if isRandomized then
			grenades = Table.getShuffled(grenades)
		end

		local iGrenade = 0

		for _, grenade in pairs(grenades) do
			if iGrenade == maxGrenades then
				break
			end

			Client.execute(string.format("buy %s", grenade))
			Logger.console(-1, "Equipped %s.", grenade)

			iGrenade = iGrenade + 1
		end
	end)
end

--- @param weapon string
--- @return void
function AiRoutineBuyGear:equipWeapon(weapon)
	Client.fireAfterRandom(0, 1, function()
		Client.execute(string.format("buy %s", weapon))
		Logger.console(-1, "Equipped %s.", weapon)
	end)
end

--- @param weapons string[]
--- @return void
function AiRoutineBuyGear:equipRandomWeapon(weapons)
	Client.fireAfterRandom(0, 1, function()
		local weapon = Table.getRandom(weapons)

		Client.execute(string.format("buy %s", weapon))
		Logger.console(-1, "Equipped %s.", weapon)
	end)
end

return Nyx.class("AiRoutineBuyGear", AiRoutineBuyGear, AiRoutineBase)
--}}}
