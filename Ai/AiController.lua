--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local CsgoWeapons = require "gamesense/csgo_weapons"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local ISurface = require "gamesense/Nyx/v1/Api/ISurface"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiActionPanorama = require "gamesense/Nyx/v1/Dominion/Ai/Action/AiActionPanorama"
local AiActionSetBaseState = require "gamesense/Nyx/v1/Dominion/Ai/Action/AiActionSetBaseState"

local AiStateAvoidInfernos = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateAvoidInfernos"
local AiStateBoost = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBoost"
local AiStateCheck = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateCheck"
local AiStateChickenInteraction = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateChickenInteraction"
local AiStateDefend = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDefend"
local AiStateDefuse = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDefuse"
local AiStateDeveloper = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDeveloper"
local AiStateDrop = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDrop"
local AiStateEngage = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEngage"
local AiStateEvacuate = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEvacuate"
local AiStateEvade = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEvade"
local AiStateFlashbang = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateFlashbang"
local AiStateFollow = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateFollow"
local AiStateGraffiti = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGraffiti"
local AiStateFlashbangDynamic = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateFlashbangDynamic"
local AiStateHeGrenade = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateHeGrenade"
local AiStateMolotov = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateMolotov"
local AiStatePatrol = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePatrol"
local AiStatePickupBomb = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePickupBomb"
local AiStatePickupItems = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePickupItems"
local AiStatePlant = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePlant"
local AiStatePush = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePush"
local AiStateRush = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateRush"
local AiStateSmoke = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateSmoke"
local AiStateSweep = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateSweep"
local AiStateWait = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateWait"
local AiStateWatch = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateWatch"

local AiChatCommandAfk = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandAfk"
local AiChatCommandBacktrack = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBacktrack"
local AiChatCommandBomb = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBomb"
local AiChatCommandBoost = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBoost"
local AiChatCommandChat = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandChat"
local AiChatCommandClantag = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandClantag"
local AiChatCommandBuy = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandRush"
local AiChatCommandDisconnect = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandDisconnect"
local AiChatCommandDrop = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandDrop"
local AiChatCommandEco = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandEco"
local AiChatCommandEnabled = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandEnabled"
local AiChatCommandFollow = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandFollow"
local AiChatCommandForce = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandForce"
local AiChatCommandGo = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandGo"
local AiChatCommandKnow = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandKnow"
local AiChatCommandLog = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandLog"
local AiChatCommandNoise = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandNoise"
local AiChatCommandOk = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandOk"
local AiChatCommandAssist = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandAssist"
local AiChatCommandReload = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandReload"
local AiChatCommandRush = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandRush"
local AiChatCommandSave = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSave"
local AiChatCommandSkill = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSkill"
local AiChatCommandSkipMatch = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSkipMatch"
local AiChatCommandScramble = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandScramble"
local AiChatCommandSilence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSilence"
local AiChatCommandStop = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandStop"
local AiChatCommandVote = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandVote"
local AiChatCommandWait = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandWait"

local AiChatbotNormal = require "gamesense/Nyx/v1/Dominion/Ai/Chat/AiChatbotNormal"
local AiChatbotGpt3 = require "gamesense/Nyx/v1/Dominion/Ai/Chat/AiChatbotGpt3"
local AiRadio = require "gamesense/Nyx/v1/Dominion/Ai/AiRadio"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiView = require "gamesense/Nyx/v1/Dominion/Ai/AiView"
local AiVoice = require "gamesense/Nyx/v1/Dominion/Ai/AiVoice"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local DominionClient = require "gamesense/Nyx/v1/Dominion/Client/Client"
local DominionMenu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
local Reaper = require "gamesense/Nyx/v1/Dominion/Reaper/Reaper"
--}}}

--{{{ AiController
--- @class AiController : Class
--- @field actions AiAction[]
--- @field antiFlyTimer Timer
--- @field antiFlyValues number
--- @field canAvoidInfernos boolean
--- @field canBuyThisRound boolean
--- @field canInspectWeapon boolean
--- @field canInspectWeaponTime number
--- @field canInspectWeaponTimer Timer
--- @field canLookAwayFromFlash boolean
--- @field canUnscope boolean
--- @field canUseKnife boolean
--- @field chatbots AiChatbot[]
--- @field client DominionClient
--- @field commands AiChatCommand[]
--- @field currentState AiState
--- @field deactivatedNodes table<number, Node[]>
--- @field deactivatedNodesByBlock table<number, Node[]>
--- @field dynamicSkillHasDied number
--- @field dynamicSkillRoundKills number
--- @field flashbang Entity
--- @field flashbangs number[]
--- @field isAntiAfkEnabled boolean
--- @field isAutoBuyArmourBlocked boolean
--- @field isQuickStopping boolean
--- @field isWalking boolean
--- @field lastPriority number
--- @field nodegraph Nodegraph
--- @field radio AiRadio
--- @field states AiState[]
--- @field unblockDirection string
--- @field unblockNodesTimer Timer
--- @field unblockTimer Timer
--- @field unscopeTime number
--- @field unscopeTimer Timer
--- @field view AiView
--- @field voice AiVoice
local AiController = {
	states = {
		avoidInfernos = AiStateAvoidInfernos,
		boost = AiStateBoost,
		check = AiStateCheck,
		defend = AiStateDefend,
		defuse = AiStateDefuse,
		developer = AiStateDeveloper,
		drop = AiStateDrop,
		engage = AiStateEngage,
		evacuate = AiStateEvacuate,
		evade = AiStateEvade,
		--flashbang = AiStateFlashbang,
		follow = AiStateFollow,
		graffiti = AiStateGraffiti,
		flashbangDynamic = AiStateFlashbangDynamic,
		heGrenade = AiStateHeGrenade,
		chickenInteraction = AiStateChickenInteraction,
		molotov = AiStateMolotov,
		patrol = AiStatePatrol,
		pickupBomb = AiStatePickupBomb,
		pickupItems = AiStatePickupItems,
		plant = AiStatePlant,
		push = AiStatePush,
		rush = AiStateRush,
		smoke = AiStateSmoke,
		sweep = AiStateSweep,
		wait = AiStateWait,
		watch = AiStateWatch,
	},
	commands = {
		afk = AiChatCommandAfk,
		ai = AiChatCommandEnabled,
		assist = AiChatCommandAssist,
		bomb = AiChatCommandBomb,
		boost = AiChatCommandBoost,
		bt = AiChatCommandBacktrack,
		buy = AiChatCommandBuy,
		chat = AiChatCommandChat,
		disconnect = AiChatCommandDisconnect,
		drop = AiChatCommandDrop,
		eco = AiChatCommandEco,
		follow = AiChatCommandFollow,
		force = AiChatCommandForce,
		go = AiChatCommandGo,
		know = AiChatCommandKnow,
		log = AiChatCommandLog,
		noise = AiChatCommandNoise,
		ok = AiChatCommandOk,
		reload = AiChatCommandReload,
		rush = AiChatCommandRush,
		save = AiChatCommandSave,
		scramble = AiChatCommandScramble,
		silence = AiChatCommandSilence,
		skill = AiChatCommandSkill,
		skipmatch = AiChatCommandSkipMatch,
		stop = AiChatCommandStop,
		tag = AiChatCommandClantag,
		vote = AiChatCommandVote,
		wait = AiChatCommandWait,
	},
	actions = {
		panorama = AiActionPanorama,
		setBaseState = AiActionSetBaseState,
	},
	chatbots = {
		normal = AiChatbotNormal,
		gpt3 = AiChatbotGpt3
	}
}

--- @param fields AiController
--- @return AiController
function AiController:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiController:__init()
	self:initFields()
	self:initEvents()
end

--- @return void
function AiController:initFields()
	self.reaper = Reaper:new({
		ai = self
	})

	self.view = AiView:new({
		nodegraph = self.nodegraph
	})

	self.isAntiAfkEnabled = false
	self.antiFlyTimer = Timer:new():start()
	self.antiFlyValues = {}
	self.canBuyThisRound = true
	self.canInspectWeapon = true
	self.canInspectWeaponTime = Client.getRandomFloat(50, 90)
	self.canInspectWeaponTimer = Timer:new():start()
	self.deactivatedNodes = {}
	self.deactivatedNodesByBlock = {}
	self.unblockDirection = "Left"
	self.unblockNodesTimer = Timer:new()
	self.unblockTimer = Timer:new():elapse()
	self.unscopeTime = 2
	self.unscopeTimer = Timer:new()
	self.flashbangs = {}

	DominionMenu.enableAi = DominionMenu.group:checkbox("> Dominion Artifical Intelligence"):setParent(DominionMenu.master):addCallback(function(item)
		local value = item:get()

		if not value then
			self.nodegraph:clearPath("AI disabled")
		end

		self.view.isEnabled = value
		self.lastPriority = nil
		self.currentState = nil
	end)

	DominionMenu.visualisePathfinding = DominionMenu.group:checkbox("    > Visualise Pathfinding"):setParent(DominionMenu.enableAi)
	DominionMenu.enableView = DominionMenu.group:checkbox("    > Enable View"):setParent(DominionMenu.enableAi)
	DominionMenu.enableAutoBuy = DominionMenu.group:checkbox("    > Enable Auto-Buy"):setParent(DominionMenu.enableAi)

	self.radio = AiRadio:new()
	self.voice = AiVoice:new()

	local states = {}

	for id, state in pairs(self.states) do
		local initialisedState = state:new()

		initialisedState.nodegraph = self.nodegraph

		states[id] = initialisedState
	end

	self.states = states

	local commands = {}

	for id, command in pairs(self.commands) do
		commands[id] = command
	end

	self.commands = commands

	local actions = {}

	for id, action in pairs(self.actions) do
		actions[id] = action:new({
			ai = self
		})
	end

	self.actions = actions

	local chatbots = {}

	for id, chatbot in pairs(self.chatbots) do
		chatbots[id] = chatbot:new()
	end

	self.chatbots = chatbots

	if Config.isLiveClient and not Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid()) then
		self.client = DominionClient:new()
	end
end

--- @return void
function AiController:initEvents()
	Callbacks.init(function()
		self.dynamicSkillRoundKills = 0
		self.dynamicSkillHasDied = false

		self.states.engage.skill = 2
	end)

	Callbacks.frame(function()
		if not DominionMenu.master:get() then
			return
		end

		self:renderUi()
	end)

	Client.onNextTick(function()
		Callbacks.setupCommand(function(cmd)
			self:think(cmd)
		end)
	end)

	Callbacks.playerDeath(function(e)
		if e.attacker:isClient() and e.victim:isEnemy() then
			self.dynamicSkillRoundKills = self.dynamicSkillRoundKills + 1
		end

		if e.victim:isClient() and e.attacker:isEnemy() then
			self.dynamicSkillHasDied = true
		end
	end)

	Callbacks.roundStart(function()
		if not self.reaper.isEnabled then
			Client.openConsole()
		end

		self.isAutoBuyArmourBlocked = true

		Client.fireAfter(1, function()
			self.isAutoBuyArmourBlocked = false
		end)

		-- Dynamic skill.
		if self.client and self.client.allocation then
			if self.dynamicSkillHasDied and self.dynamicSkillRoundKills == 0 then
				self.states.engage.skill = self.states.engage.skill + 1
			elseif self.dynamicSkillRoundKills >= 2 then
				self.states.engage.skill = self.states.engage.skill - 1
			end

			self.states.engage.skill = Math.getClamped(self.states.engage.skill, 0, 10)
		end

		self.dynamicSkillHasDied = false
		self.dynamicSkillRoundKills = 0

		self.nodegraph:reactivateAllNodes()

		if not DominionMenu.master:get() or not DominionMenu.enableAi:get() then
			return
		end

		-- AI.
		self.lastPriority = nil
		self.currentState = nil

		self.nodegraph:clearPath("Round restart")

		self:autoBuy()

		for _, block in pairs(self.nodegraph.objectiveBlock) do
			self.deactivatedNodesByBlock[block.id] = {}

			for _, node in pairs(self.nodegraph.nodes) do
				if node.id ~= block.id and block.origin:getDistance(node.origin) < 256 then
					node.active = false

					table.insert(self.deactivatedNodesByBlock[block.id], node)
				end
			end
		end

		self.nodegraph:rePathfind()
	end)

	Callbacks.roundFreezeEnd(function()
		self.canBuyThisRound = true

		self.unblockNodesTimer:start()
	end)

	Callbacks.itemEquip(function(e)
		if not DominionMenu.master:get() or not DominionMenu.enableAi:get() or not DominionMenu.enableAutoBuy:get() then
			return
		end

		if not e.player:isClient() then
			return
		end

		Client.fireAfter(0.1, function()
			if self.isAutoBuyArmourBlocked then
				return
			end

			UserInput.execute("buy vest; buy vesthelm")
		end)
	end)

	Callbacks.bombPlanted(function()
		self.nodegraph:reactivateAllNodes()
	end)

	Callbacks.smokeGrenadeDetonate(function(e)
		if AiUtility.isBombPlanted() then
			return
		end

		self:deactivateNodes(e.entityid, e.origin, 144, true)
	end)

	Callbacks.smokeGrenadeExpired(function(e)
		self:reactivateNodes(e.entityid)
	end)

	Callbacks.infernoStartBurn(function(e)
		if AiUtility.isBombPlanted() and AiUtility.bombDetonationTime < 10 then
			return
		end

		self:deactivateNodes(e.entityid, e.origin, 300)
	end)

	Callbacks.infernoExpire(function(e)
		self:reactivateNodes(e.entityid)
	end)

	Callbacks.flashbangDetonate(function(e)
		self.flashbangs[e.entityid] = nil

		if self.flashbang and self.flashbang.eid == e.entityid then
			self.flashbang = nil
		end
	end)

	Callbacks.playerChat(function(e)
		if not DominionMenu.master:get() then
			return
		end

		self:chatCommands(e)
	end)

	Callbacks.weaponFire(function(e)
		if not DominionMenu.master:get() or not DominionMenu.enableAi:get() then
			return
		end

		if e.player:isClient() and e.player:isHoldingBoltActionRifle() then
			Client.unscope(true)
		end
	end)
end

--- @param limit number
--- @return void
function AiController:buyGrenades(limit)
	local nades = Table.getShuffled({
		"buy smokegrenade",
		"buy flashbang",
		"buy hegrenade",
		"buy molotov; buy incgrenade"
	})

	limit = limit or 4

	local i = 0

	for _, nade in pairs(nades) do
		if i <= limit then
			Client.fireAfter(Client.getRandomFloat(0.25, 1), function()
				UserInput.execute(nade)
			end)

			i = i + 1
		end
	end
end

--- @param isImmediate boolean
--- @return void
function AiController:autoBuy(isImmediate)
	if not DominionMenu.enableAutoBuy:get() or not self.canBuyThisRound then
		return
	end

	local freezeTime = cvar.mp_freezetime:get_int()
	local minDelay = freezeTime * 0.5
	local maxDelay = freezeTime * 0.9

	local buyAfter

	if isImmediate then
		buyAfter = Client.getRandomFloat(0, 0.5)
	else
		buyAfter = Client.getRandomFloat(minDelay, maxDelay)
	end

	Client.fireAfter(buyAfter, function()
		if not Server.isConnected() then
			return
		end

		if not self.canBuyThisRound then
			return
		end

		local player = AiUtility.client
		local grenadeLimit = Client.getRandomInt(1, player:isCounterTerrorist() and 2 or 3)

		for _, weapon in pairs(AiUtility.mainWeapons) do
			if player:hasWeapon(weapon) then
				if player:m_iArmor() < 33 then
					UserInput.execute("buy vest; buy vesthelm")
				end

				self:buyGrenades(grenadeLimit)

				return
			end
		end

		local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
		local halftimeRounds = math.floor(cvar.mp_maxrounds:get_int() / 2)

		if roundsPlayed == 0 or roundsPlayed == halftimeRounds then
			if player:isCounterTerrorist() then
				if Client.getChance(2) then
					UserInput.execute("buy defuser")

					self:buyGrenades(4)
				else
					self:buyGrenades(4)
				end
			else
				self:buyGrenades(4)
			end

			return
		end

		local balance = player:m_iAccount()

		if not balance then
			return
		end

		local team = player:m_iTeamNum()
		local canBuyRifle = balance - (team == 2 and 3000 or 3050) >= 0
		local canBuyAwp = (balance - 5750 >= 0) and Client.getChance(3)
		local canBuyUtility = false
		local canBuyAllNades = balance > 7000

		if (roundsPlayed == 1 or roundsPlayed == halftimeRounds + 1) and not canBuyRifle then
			self:forceBuy()

			return
		end

		if Client.getChance(15) and balance > 2000 and balance < 3500 then
			UserInput.execute("buy vest; buy ssg08;")

			self:buyGrenades(1)
		end

		if canBuyAwp then
			UserInput.execute("buy awp")

			canBuyUtility = true
		elseif canBuyRifle then
			local isBuyingCheapRifle = balance - (team == 2 and 3700 or 4200) < 0
			local isBuyingScopedRifle = balance > 4500 and Client.getChance(3)

			if isBuyingCheapRifle then
				UserInput.execute("buy famas; buy galilar")

				grenadeLimit = 2
			elseif isBuyingScopedRifle then
				UserInput.execute("buy aug; buy sg556")
			else
				UserInput.execute("buy m4a4; buy ak47; buy m4a1_silencer")
			end

			canBuyUtility = true
		end

		if canBuyUtility then
			if player:m_iArmor() < 33 then
				UserInput.execute("buy vest; buy vesthelm")
			end

			if player:isCounterTerrorist() then
				UserInput.execute("buy defuser")
			end

			if canBuyAllNades then
				grenadeLimit = 4
			end

			self:buyGrenades(grenadeLimit)
		end
	end)
end

--- @return void
function AiController:forceBuy()
	local player = AiUtility.client

	for _, weapon in pairs(AiUtility.mainWeapons) do
		if player:hasWeapon(weapon) then
			if player:m_iArmor() < 33 then
				UserInput.execute("buy vest; buy vesthelm")
			end

			return
		end
	end

	local balance = player:m_iAccount()

	if not balance then
		return
	end

	local team = player:m_iTeamNum()
	local canBuyRifle = balance - (team == 2 and 3000 or 3050) > 0

	if canBuyRifle then
		return
	end

	local cheap = {
		"tec9; fn57"
	}

	local expensive = {
		"deagle",
		"mac10; mp9",
		"mp7",
		"ump45"
	}

	Client.fireAfter(Client.getRandomFloat(1, 2), function()
		local balance = player:m_iAccount()
		local isBuyingSmg = (balance - 1500) >= 0
		local isBuyingNegev = (balance - 2500 >= 0) and Client.getChance(5)

		if isBuyingNegev then
			UserInput.execute("buy negev")
		elseif isBuyingSmg then
			UserInput.execute("buy %s;", Table.getRandom(expensive))
		else
			UserInput.execute("buy %s;", Table.getRandom(cheap))
		end

		if player:m_iArmor() < 33 then
			UserInput.execute("buy vest; buy vesthelm")
		end

		self:buyGrenades(1)
	end)
end

--- @generic T
--- @param state T|AiState
--- @return T
function AiController:getState(state)
	return self.states[state.name]
end

--- @param e PlayerChatEvent
--- @return void
function AiController:chatCommands(e)
	if not e.text:sub(1, 1) == "/" then
		return
	end

	local input = Table.getExplodedString(e.text:sub(2), " ")
	local cmd = table.remove(input, 1)
	local command = self.commands[cmd]

	if not command then
		return
	end

	command:invoke(self, e.sender, input)
end

--- @param origin Vector3
--- @param radius number
--- @param checkForEnemies boolean
--- @return void
function AiController:deactivateNodes(eid, origin, radius, checkForEnemies)
	if checkForEnemies then
		local isEnemyNearby = false

		for _, enemy in pairs(AiUtility.enemies) do
			if origin:getDistance(enemy:getOrigin()) < 1250 then
				isEnemyNearby = true

				break
			end
		end

		if not isEnemyNearby then
			return
		end
	end

	origin:offset(0, 0, 18)

	--- @type Node[]
	local deactivatedNodes = {}

	--- @type Node[]
	local plantNodes = Table.merge(self.nodegraph.objectiveAPlant, self.nodegraph.objectiveBPlant)

	for _, node in pairs(self.nodegraph.nodes) do repeat
		if node.active and node.origin:getDistance(origin) <= radius then
			for _, plant in pairs(plantNodes) do
				if node.origin:getDistance(plant.origin) <= radius then
					break
				end
			end

			table.insert(deactivatedNodes, node)

			node.active = false
		end
	until true end

	self.deactivatedNodes[eid] = deactivatedNodes

	self.nodegraph:rePathfind()
end

--- @param eid number
--- @return void
function AiController:reactivateNodes(eid)
	if not self.deactivatedNodes[eid] then
		return
	end

	for _, node in pairs(self.deactivatedNodes[eid]) do
		node.active = true
	end

	self.deactivatedNodes[eid] = nil
end

--- @return void
function AiController:renderUi()
	if not DominionMenu.visualisePathfinding:get() then
		return
	end

	local player = AiUtility.client

	if not player then
		return
	end

	local uiPos = Vector2:new(20, 20)
	local fontColor = Color:hsla(0, 0, 0.95)
	local spacerColor = Color:hsla(0, 0, 0.66)
	local spacerDimensions = Vector2:new(200, 1)
	local offset = 25

	local teamColors = {
		[2] = Color:hsla(35, 0.8, 0.6),
		[3] = Color:hsla(200, 0.8, 0.6)
	}

	local nameBgColor = Color:rgba(0, 0, 0, 255)
	local teamNames = {
		[2] = "T",
		[3] = "CT"
	}
	local team = teamNames[player:m_iTeamNum()]
	local name = string.format("( %s ) %s", team, player:getName())

	if not team then
		return
	end

	local screenBgColor = Color:rgba(0, 0, 0, 200)

	if not player:isAlive() then
		name = name .. " (DEAD)"
		nameBgColor = Color:rgba(255, 50, 50, 255)
		screenBgColor = Color:rgba(150, 25, 25, 150)
	end

	local screenDimensions = Client.getScreenDimensions()

	Vector2:new():drawSurfaceRectangle(screenDimensions, screenBgColor)

	self.states.engage:render()

	local nameWidth = ISurface.getTextSize(Font.MEDIUM_BOLD, name)

	uiPos:clone():offset(-5):drawSurfaceRectangle(Vector2:new(nameWidth + 10, 25), nameBgColor)
	uiPos:drawSurfaceText(Font.MEDIUM_BOLD, teamColors[player:m_iTeamNum()], "l", name)
	uiPos:offset(0, offset)

	uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
	uiPos:offset(0, 10)

	if self.client and self.client.allocation then
		uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
			"Session with %s",
			self.client.allocation.host
		))

		uiPos:offset(0, offset)
	end

	local scoreData = Table.fromPanorama(Panorama.GameStateAPI.GetScoreDataJSO())
	local tWins = scoreData.teamdata.TERRORIST.score
	local ctWins = scoreData.teamdata.CT.score
	local maxRounds = cvar.mp_maxrounds:get_int()
	local roundType = "Custom"

	if maxRounds == 30 then
		roundType = "Long"
	elseif maxRounds == 16 then
		roundType = "Short"
	end

	local teamWins
	local enemyWins

	if player:isTerrorist() then
		teamWins = tWins
		enemyWins = ctWins
	elseif player:isCounterTerrorist() then
		teamWins = ctWins
		enemyWins = tWins
	end

	uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
		"%s Match: Score %i : %i | KD %i/%i (%.2f)",
		roundType,
		teamWins,
		enemyWins,
		player:m_iKills(),
		player:m_iDeaths(),
		player:getKdRatio()
	))

	uiPos:offset(0, offset)

	local fps = Client.getFpsDelayed()
	local tickErrorPct = math.max(0, (1 - (fps / (1 / globals.tickinterval())))) * 100
	local hue = Math.getFloat(Math.getClamped(fps, 0, 70), 70) * 120
	local fpsColor = Color:hsla(hue, 0.8, 0.6)

	uiPos:drawSurfaceText(Font.SMALL, fpsColor, "l", string.format(
		"FPS: %i (ERR %.1f%%)",
		fps,
		tickErrorPct
	))

	uiPos:offset(0, offset)

	if not DominionMenu.enableAi:get() then
		uiPos:drawSurfaceText(Font.MEDIUM_BOLD, Color:hsla(0, 0.8, 0.6, 255), "l", "AI DISABLED")

		uiPos:offset(0, offset)

		return
	end

	if Server.isConnected() then
		local ping = Server.getLatency() * 1000
		local loss = Server.getLoss() * 100
		local svrColor = Color:hsla(120, 0.8, 0.6, 255)

		if ping > 175 or loss > 2 then
			svrColor = Color:hsla(0, 0.8, 0.6, 255)
		elseif ping > 100 or loss > 0 then
			svrColor = Color:hsla(50, 0.8, 0.6, 255)
		end

		uiPos:drawSurfaceText(Font.SMALL, svrColor, "l", string.format(
			"SVR: %ims / %.2f%% loss",
			ping,
			loss
		))

		uiPos:offset(0, offset)
	end

	uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
		"Skill Level: %i",
		self.states.engage.skill
	))

	uiPos:offset(0, offset)

	if not player:isAlive() then
		return
	end

	uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
	uiPos:offset(0, 10)

	if self.currentState then
		uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
			"Behaviour: %s",
			self.currentState.name
		))

		uiPos:offset(0, offset)

		uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
			"Priority: %s [%i]",
			AiState.priorityMap[self.lastPriority],
			self.lastPriority
		))

		uiPos:offset(0, offset)
	end

	if self.nodegraph.task then
		uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
			"Task: %s",
			self.nodegraph.task
		))

		uiPos:offset(0, offset)
	end

	uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
	uiPos:offset(0, 10)

	if self.nodegraph.path and self.nodegraph.pathCurrent then
		local node = self.nodegraph.path[self.nodegraph.pathCurrent]

		if node then
			uiPos:drawSurfaceText(Font.SMALL, Node.typesColor[node.type], "l", string.format(
				"Next node: %s [%i]",
				Node.typesName[node.type],
				node.id
			))

			uiPos:offset(0, offset)
		end

		local goalNode = self.nodegraph.pathEnd

		if goalNode then
			uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
				"Distance to goal: %iu",
				player:getOrigin():getDistance(goalNode.origin)
			))

			uiPos:offset(0, offset)
		end
	end

	local failsColor =  self.nodegraph.pathfindFails > 0 and Color:hsla(0, 0.8, 0.6) or fontColor

	uiPos:drawSurfaceText(Font.SMALL, failsColor, "l", string.format(
		"Pathfind fails: %i",
		self.nodegraph.pathfindFails
	))

	uiPos:offset(0, offset)

	if DominionMenu.enableAi:get() and AiUtility.clientThreatenedFromOrigin then
		Client.draw(Vector3.drawCircleOutline, AiUtility.clientThreatenedFromOrigin, 30, 3, Color:hsla(0, 1, 1, 75))
	end
end

--- @param ai AiOptions
--- @return void
function AiController:activities(ai)
	local isQuickStopping = self.isQuickStopping

	self.isQuickStopping = false

	DominionMenu.standaloneQuickStopRef:set(isQuickStopping)

	local isWalking = self.isWalking

	self.isWalking = nil

	local clientOrigin = AiUtility.client:getOrigin()

	for _, inferno in Entity.find("CInferno") do
		if clientOrigin:getDistance(inferno:m_vecOrigin()) < 300 then
			isWalking = false

			break
		end
	end

	if isWalking then
		ai.cmd.in_speed = 1
	end

	local canUseGear = self.canUseGear
	local canUseKnife = self.canUseKnife
	local canReload = self.canReload

	self.canUseGear = true
	self.canReload = true
	self.canUseKnife = true

	local player = AiUtility.client
	local origin = player:getOrigin()

	if canReload and not AiUtility.isClientThreatened then
		local weapon = Entity:create(player:m_hActiveWeapon())
		local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
		local ammo = weapon:m_iClip1()
		local maxAmmo = csgoWeapon.primary_clip_size

		local reloadRatio = 0.9

		if AiUtility.closestEnemy then
			local closestEnemyDistance = origin:getDistance(AiUtility.closestEnemy:getOrigin())

			if closestEnemyDistance > 1000 then
				reloadRatio = 0.75
			elseif closestEnemyDistance > 750 then
				reloadRatio = 0.55
			elseif closestEnemyDistance > 500 then
				reloadRatio = 0.25
			elseif closestEnemyDistance > 250 then
				reloadRatio = 0
			end
		end

		if ammo / maxAmmo < reloadRatio then
			ai.cmd.in_reload = 1
		end
	end

	if not canUseGear then
		return
	end

	if canUseKnife then
		for _, dormantAt in pairs(AiUtility.dormantAt) do
			local dormantTime = Time.getRealtime() - dormantAt
			local period = (AiUtility.enemiesAlive == 0 or AiUtility.isBombPlanted()) and 1 or 3

			if dormantTime < period then
				canUseKnife = false
			end
		end
	end

	if AiUtility.isClientThreatened then
		canUseKnife = false
	end

	local closestCautionNode = ai.nodegraph:getClosestNodeOf(origin, Node.types.CAUTION)

	if closestCautionNode and origin:getDistance(closestCautionNode.origin) < 500 then
		canUseKnife = false
	end

	if canUseKnife then
		Client.equipKnife()
	else
		if AiUtility.client:hasPrimary() then
			Client.equipPrimary()
		else
			Client.equipPistol()
		end
	end

	local canInspectWeapon = self.canInspectWeapon

	self.canInspectWeapon = true

	if self.canInspectWeaponTimer:isElapsedThenRestart(self.canInspectWeaponTime) and canInspectWeapon then
		self.canInspectWeaponTimer:restart()
		self.canInspectWeaponTime = Client.getRandomFloat(30, 90)

		Client.execute("+lookatweapon")

		Client.onNextTick(function()
			Client.execute("-lookatweapon")
		end)
	end
end

--- @param ai AiOptions
--- @return void
function AiController:antiAfk(ai)
	ai.cmd.in_duck = 1
end

--- @param ai AiOptions
--- @return void
function AiController:antiFlash(ai)
	local eyeOrigin = Client.getEyeOrigin()
	local cameraAngles = Client.getCameraAngles()

	for _, grenade in Entity.find({Weapons.GRENADE_PROJECTILE}) do repeat
		if grenade:m_flDamage() ~= 100 then
			break
		end

		if not self.flashbangs[grenade.eid] then
			self.flashbangs[grenade.eid] = Time.getCurtime() + 1.65
		end

		if self.flashbang then
			break
		end

		if self.flashbangs[grenade.eid] - Time.getCurtime() > 0.4 then
			break
		end

		local grenadeOrigin = grenade:m_vecOrigin()
		local distance = eyeOrigin:getDistance(grenadeOrigin)
		local fov = cameraAngles:getFov(eyeOrigin, grenadeOrigin)

		if distance < 150 then
			if fov > 40 then
				break
			end
		else
			if fov > 80 then
				break
			end
		end

		local trace = Trace.getLineToPosition(eyeOrigin, grenadeOrigin, AiUtility.traceOptionsAttacking)

		if not trace.isIntersectingGeometry then
			self.flashbang = grenade
		end
	until true end

	if not self.flashbang then
		return
	end

	local canLookAwayFromFlash = self.canLookAwayFromFlash

	self.canLookAwayFromFlash = true

	if canLookAwayFromFlash then
		Client.unscope()

		ai.view:lookAtLocation(eyeOrigin:getAngle(self.flashbang:m_vecOrigin()):getBackward() * Vector3.MAX_DISTANCE, 4, "AiController avoid flashbang")
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiController:antiFly(cmd)
	-- This method can be replaced by cvar.full_update but I spent the time writing this so piss off.

	local playerOrigin = Client.getOrigin()

	if self.antiFlyTimer:isElapsedThenRestart(0.75) then
		self.antiFlyValues = {}
	end

	table.insert(self.antiFlyValues, playerOrigin.z)

	local lastValue = self.antiFlyValues[1]
	local isLastValueGreater = false
	local fails = 0

	for _, value in pairs(self.antiFlyValues) do repeat
		value = math.floor(value)

		if value == lastValue then
			break
		end

		if value > lastValue and not isLastValueGreater then
			isLastValueGreater = true
			lastValue = value

			fails = fails + 1
		elseif value < lastValue and isLastValueGreater then
			isLastValueGreater = false
			lastValue = value

			fails = fails + 1
		end

		lastValue = value
	until true end

	local onGround = AiUtility.client:getFlag(Player.flags.FL_ONGROUND)

	if not onGround and fails > 10 then
		cmd.in_jump = 1
	end
end

--- @return void
function AiController:unblockNodes()
	if not self.unblockNodesTimer:isElapsedThenStop(12) then
		return
	end

	for _, blockGroup in pairs(self.deactivatedNodesByBlock) do
		for _, node in pairs(blockGroup) do
			node.active = true
		end
	end

	if self.nodegraph.path then
		self.nodegraph:rePathfind()
	end
end

--- @return void
function AiController:unscope()
	if not self.canUnscope then
		self.canUnscope = true

		self.unscopeTimer:restart()

		return
	end

	local isScoped = AiUtility.client:m_bIsScoped() == 1

	if isScoped and not self.unscopeTimer:isStarted() then
		self.unscopeTimer:start()
	end

	if not isScoped then
		self.unscopeTimer:stop()
	end

	if isScoped and self.unscopeTimer:isElapsed(self.unscopeTime) then
		Client.unscope(true)
	end
end

--- @class AiOptions
--- @field controller AiController
--- @field nodegraph Nodegraph
--- @field view AiView
--- @field radio AiRadio
--- @field voice AiVoice
--- @field cmd SetupCommandEvent
--- @field priority number
---
--- @param cmd SetupCommandEvent
--- @return void
function AiController:think(cmd)
	if not DominionMenu.master:get() or not DominionMenu.enableAi:get() then
		-- Fix issue with AI trying to equip the last gear forever.
		if Client.isEquipping() then
			Client.cancelEquip()
		end

		return
	end

	-- Possible fix for bug where logic loop still executes in spite of being out of a server.
	if not Server.isIngame() then
		return
	end

	if Entity.getGameRules():m_bWarmupPeriod() == 1 then
		return
	end

	if not AiUtility.client then
		return
	end

	if self.isAntiAfkEnabled then
		self:antiAfk({
			controller = self,
			nodegraph = self.nodegraph,
			view = self.view,
			cmd = cmd
		})
	end

	self:antiFly(cmd)
	self:unblockNodes()

	local player = AiUtility.client

	if not player:isAlive() then
		return
	end

	--- @type AiState
	local currentState
	local highestPriority = -1

	for _, state in pairs(self.states) do
		local priority = state:assess(self.nodegraph, self)

		if priority > highestPriority then
			currentState = state
			highestPriority = priority
		end
	end

	--- @type AiOptions
	local ai = {
		controller = self,
		nodegraph = self.nodegraph,
		view = self.view,
		radio = self.radio,
		voice = self.voice,
		cmd = cmd,
		priority = highestPriority
	}

	if DominionMenu.enableView:get() then
		self.view:think(cmd)
	end

	if currentState then
		if self.lastPriority ~= highestPriority then
			self.lastPriority = highestPriority

			currentState.lastPriority = highestPriority

			self.nodegraph:clearPath(string.format("Switching AI state to %s", currentState.name))

			if currentState.activate then
				currentState:activate(ai)
			end
		end

		self.currentState = currentState

		currentState:think(ai)
	end

	self:activities(ai)

	self.nodegraph:processMovement(cmd)

	self:antiFlash(ai)
	self:unscope()
end

return Nyx.class("AiController", AiController)
--}}}
