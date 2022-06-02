--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local CsgoWeapons = require "gamesense/csgo_weapons"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local ISurface = require "gamesense/Nyx/v1/Api/ISurface"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
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
-- Chatbot.
local AiChatbotNormal = require "gamesense/Nyx/v1/Dominion/Ai/Chat/AiChatbotNormal"
local AiChatbotGpt3 = require "gamesense/Nyx/v1/Dominion/Ai/Chat/AiChatbotGpt3"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"

-- Modules.
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiVoice = require "gamesense/Nyx/v1/Dominion/Ai/AiVoice"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local DominionClient = require "gamesense/Nyx/v1/Dominion/Client/Client"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local Reaper = require "gamesense/Nyx/v1/Dominion/Reaper/Reaper"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
local WeaponInfo = require "gamesense/Nyx/v1/Dominion/Ai/Info/WeaponInfo"
--}}}

--{{{ Definitions
--- @class AiControllerActions
--- @field panorama AiActionPanorama
--- @field setBaseState AiActionSetBaseState

--- @class AiControllerChatbots
--- @field normal AiChatbotNormal
--- @field gpt3 AiChatbotGpt3
--}}}

--{{{ AiController
--- @class AiController : Class
--- @field actions AiControllerActions
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
--- @field chatbots AiControllerChatbots
--- @field client DominionClient
--- @field commands AiChatCommand
--- @field currentState AiStateBase
--- @field deactivatedNodes table<number, Node[]>
--- @field deactivatedNodesByBlock table<number, Node[]>
--- @field dynamicSkillHasDied number
--- @field dynamicSkillRoundKills number
--- @field flashbang Entity
--- @field flashbangs number[]
--- @field isAutoBuyArmourBlocked boolean
--- @field isAutoBuyEnabled boolean
--- @field isQuickStopping boolean
--- @field isWalking boolean
--- @field lastPriority number
--- @field nodegraph Nodegraph
--- @field priority number
--- @field states AiStateList
--- @field unblockDirection string
--- @field unblockNodesTimer Timer
--- @field unblockTimer Timer
--- @field unscopeTime number
--- @field unscopeTimer Timer
--- @field voice AiVoice
--- @field lockStateTimer Timer
local AiController = {
	commands = AiChatCommand,
	actions = {},
	chatbots = {
		normal = AiChatbotNormal,
		gpt3 = AiChatbotGpt3,
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

	Logger.console(0, "AI Controller is ready.")
end

--- @return void
function AiController:initFields()
	self.isAntiAfkEnabled = false
	self.antiFlyTimer = Timer:new():start()
	self.antiFlyValues = {}
	self.canBuyThisRound = true
	self.canInspectWeapon = true
	self.canInspectWeaponTime = Math.getRandomFloat(50, 90)
	self.canInspectWeaponTimer = Timer:new():start()
	self.deactivatedNodes = {}
	self.deactivatedNodesByBlock = {}
	self.unblockDirection = "Left"
	self.unblockNodesTimer = Timer:new()
	self.unblockTimer = Timer:new():elapse()
	self.unscopeTime = 2
	self.unscopeTimer = Timer:new()
	self.flashbangs = {}
	self.lockStateTimer = Timer:new():startThenElapse()
	self.isAutoBuyEnabled = true

	MenuGroup.enableAi = MenuGroup.group:addCheckbox("> Enable AI"):setParent(MenuGroup.master):addCallback(function(item)
		Pathfinder.isEnabled = item:get()

		self.lastPriority = nil
		self.currentState = nil
	end)

	MenuGroup.enableAutoBuy = MenuGroup.group:addCheckbox("    | Buy Weapons"):setParent(MenuGroup.enableAi)
	MenuGroup.visualisePathfinding = MenuGroup.group:addCheckbox("    | Visualise AI"):setParent(MenuGroup.enableAi)

	self.reaper = Reaper:new({
		ai = self
	})

	self.voice = AiVoice:new()

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
		if not Server.isIngame() then
			return
		end

		self.dynamicSkillRoundKills = 0
		self.dynamicSkillHasDied = false

		local states = {}

		--- @param state AiStateBase
		for id, state in pairs(AiState) do repeat
			if state.requiredNodes then
				local isNodeAvailable = true
				local unavailableNodes = {}

				for _, node in pairs(state.requiredNodes) do
					if not Nodegraph.isNodeAvailable(node) then
						isNodeAvailable = false

						table.insert(unavailableNodes, node.name)
					end
				end

				if not isNodeAvailable then
					Logger.console(
						2,
						"AI state '%s' requires the following nodes: '%s', but they are not present on the map. This state has not been loaded.",
						state.name,
						Table.getImploded(unavailableNodes, ", ")
					)

					break
				end
			end

			local object = state:new({
				ai = self
			})

			states[id] = object
		until true end

		self.states = states

		local commands = {}

		for id, command in pairs(self.commands) do
			commands[id] = command
		end

		self.commands = commands
	end)

	Callbacks.frame(function()
		if not MenuGroup.master:get() then
			return
		end

		self:renderUi()
	end)

	Client.onNextTick(function()
		Callbacks.setupCommand(function(cmd)
			self:seedPrng()
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

		if not MenuGroup.master:get() or not MenuGroup.enableAi:get() then
			return
		end

		self.lastPriority = nil
		self.currentState = nil

		self:autoBuy()
	end)

	Callbacks.roundFreezeEnd(function()
		self.canBuyThisRound = true

		self.unblockNodesTimer:start()
	end)

	Callbacks.itemEquip(function(e)
		if not MenuGroup.master:get() or not MenuGroup.enableAi:get() or not MenuGroup.enableAutoBuy:get() then
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

	Callbacks.flashbangDetonate(function(e)
		self.flashbangs[e.entityid] = nil

		if self.flashbang and self.flashbang.eid == e.entityid then
			self.flashbang = nil
		end
	end)

	Callbacks.playerChat(function(e)
		if not MenuGroup.master:get() then
			return
		end

		self:chatCommands(e)
	end)

	Callbacks.weaponFire(function(e)
		if not MenuGroup.master:get() or not MenuGroup.enableAi:get() then
			return
		end

		if e.player:isClient() and e.player:isHoldingBoltActionRifle() then
			LocalPlayer.unscope(true)
		end
	end)
end

--- Must be called first, before any other AI events.
--- @return void
function AiController:seedPrng()
	-- This must be executed as the very first setupCommand event that runs. Before everything else.
	-- It is responsible for ensuring RNG between AI clients on the same server is properly randomised.
	if entity.get_local_player() then
		for _ = 0, entity.get_local_player() * 100 do
			client.random_float(0, 1)
		end
	end
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
			Client.fireAfter(Math.getRandomFloat(0.25, 1), function()
				UserInput.execute(nade)
			end)

			i = i + 1
		end
	end
end

--- @param isImmediate boolean
--- @return void
function AiController:autoBuy(isImmediate)
	if not MenuGroup.enableAutoBuy:get() or not self.canBuyThisRound then
		return
	end

	if not self.isAutoBuyEnabled then
		return
	end

	local freezeTime = cvar.mp_freezetime:get_int()
	local minDelay = freezeTime * 0.5
	local maxDelay = freezeTime * 0.9

	local buyAfter

	if isImmediate then
		buyAfter = Math.getRandomFloat(0, 0.5)
	else
		buyAfter = Math.getRandomFloat(minDelay, maxDelay)
	end

	Client.fireAfter(buyAfter, function()
		if not Server.isConnected() then
			return
		end

		if not self.canBuyThisRound then
			return
		end

		local player = AiUtility.client
		local grenadeLimit = Math.getRandomInt(1, player:isCounterTerrorist() and 2 or 3)

		for _, weapon in pairs(WeaponInfo.primaries) do
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
				if Math.getChance(2) then
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
		local canBuyAwp = (balance - 5750 >= 0) and Math.getChance(3)
		local canBuyUtility = false
		local canBuyAllNades = balance > 7000

		if (roundsPlayed == 1 or roundsPlayed == halftimeRounds + 1) and not canBuyRifle then
			self:forceBuy()

			return
		end

		if Math.getChance(15) and balance > 2000 and balance < 3500 then
			UserInput.execute("buy vest; buy ssg08;")

			self:buyGrenades(1)
		end

		if canBuyAwp then
			UserInput.execute("buy awp")

			canBuyUtility = true
		elseif canBuyRifle then
			local isBuyingCheapRifle = balance - (team == 2 and 3700 or 4200) < 0
			local isBuyingScopedRifle = balance > 4500 and Math.getChance(3)

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

	for _, weapon in pairs(WeaponInfo.primaries) do
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

	Client.fireAfter(Math.getRandomFloat(1, 2), function()
		local balance = player:m_iAccount()
		local isBuyingSmg = (balance - 1500) >= 0
		local isBuyingNegev = (balance - 2500 >= 0) and Math.getChance(5)

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

--- @return void
function AiController:renderUi()
	if not MenuGroup.visualisePathfinding:get() then
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

	if not MenuGroup.enableAi:get() then
		uiPos:drawSurfaceText(Font.MEDIUM_BOLD, Color:hsla(0, 0.8, 0.6, 255), "l", "AI DISABLED")

		uiPos:offset(0, offset)

		return
	end

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
			AiStateBase.priorityMap[self.lastPriority],
			self.lastPriority
		))

		uiPos:offset(0, offset)
	end

	if Pathfinder.path then
		uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
			"Path Task: %s",
			Pathfinder.path.task
		))

		uiPos:offset(0, offset)
	end

	if self.currentState then
		local activity = self.currentState.activity and self.currentState.activity or "Unknown"

		uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
			"AI Activity: %s",
			activity
		))

		uiPos:offset(0, offset)
	end

	uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
	uiPos:offset(0, 10)

	if Pathfinder.path then
		local node = Pathfinder.path.node

		if node then
			uiPos:drawSurfaceText(Font.SMALL, Node.typesColor[node.type], "l", string.format(
				"Next node: %s [%i]",
				Node.typesName[node.type],
				node.id
			))

			uiPos:offset(0, offset)
		end

		local goalNode = Pathfinder.path.endGoal

		if goalNode then
			uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
				"Distance to goal: %iu",
				player:getOrigin():getDistance(goalNode.origin)
			))

			uiPos:offset(0, offset)
		end
	end

	if MenuGroup.enableAi:get() and AiUtility.clientThreatenedFromOrigin then
		Client.draw(Vector3.drawCircleOutline, AiUtility.clientThreatenedFromOrigin, 30, 3, Color:hsla(0, 1, 1, 75))
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiController:activities(cmd)
	-- todo
	local isWalking = self.isWalking

	self.isWalking = nil

	local clientOrigin = LocalPlayer:getOrigin()

	for _, inferno in Entity.find("CInferno") do
		if clientOrigin:getDistance(inferno:m_vecOrigin()) < 300 then
			isWalking = false

			break
		end
	end

	if isWalking then
		cmd.in_speed = true
	end

	local canUseGear = self.canUseGear
	local canUseKnife = self.canUseKnife
	local canReload = self.canReload

	self.canUseGear = true
	self.canReload = true
	self.canUseKnife = true

	local player = AiUtility.client
	local origin = player:getOrigin()

	if canReload and not AiUtility.isClientThreatened and not AiUtility.isRoundOver then
		local weapon = Entity:create(player:m_hActiveWeapon())

		-- SetupCommandEvent but no weapon? Valve?
		if weapon then
			local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
			local ammo = weapon:m_iClip1()
			local maxAmmo = csgoWeapon.primary_clip_size

			local reloadRatio = 0.9

			if AiUtility.closestEnemy then
				local closestEnemyDistance = origin:getDistance(AiUtility.closestEnemy:getOrigin())

				if closestEnemyDistance > 1500 then
					reloadRatio = 0.75
				elseif closestEnemyDistance > 1250 then
					reloadRatio = 0.45
				elseif closestEnemyDistance > 1000 then
					reloadRatio = 0.25
				elseif closestEnemyDistance > 500 then
					reloadRatio = 0.1
				else
					reloadRatio = 0.0
				end
			end

			if ammo / maxAmmo < reloadRatio then
				cmd.in_reload = true
			end
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

	if canUseKnife then
		LocalPlayer.equipKnife()
	else
		if LocalPlayer:hasPrimary() then
			LocalPlayer.equipPrimary()
		else
			LocalPlayer.equipPistol()
		end
	end

	local canInspectWeapon = self.canInspectWeapon

	self.canInspectWeapon = true

	if self.canInspectWeaponTimer:isElapsedThenRestart(self.canInspectWeaponTime) and canInspectWeapon then
		self.canInspectWeaponTimer:restart()
		self.canInspectWeaponTime = Math.getRandomFloat(30, 90)

		Client.execute("+lookatweapon")

		Client.onNextTick(function()
			Client.execute("-lookatweapon")
		end)
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiController:antiFlash(cmd)
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
		LocalPlayer.unscope()
		View.lookAlongAngle(-(eyeOrigin:getAngle(self.flashbang:m_vecOrigin())), 4.5, View.noise.moving, "AiController avoid flashbang")
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

	local onGround = LocalPlayer:getFlag(Player.flags.FL_ONGROUND)

	if not onGround and fails > 10 then
		cmd.in_jump = true
	end
end

--- @return void
function AiController:unscope()
	if not self.canUnscope then
		self.canUnscope = true

		self.unscopeTimer:restart()

		return
	end

	local isScoped = LocalPlayer:m_bIsScoped() == 1

	if isScoped and not self.unscopeTimer:isStarted() then
		self.unscopeTimer:start()
	end

	if not isScoped then
		self.unscopeTimer:stop()
	end

	if isScoped and self.unscopeTimer:isElapsed(self.unscopeTime) then
		LocalPlayer.unscope(true)
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiController:think(cmd)
	if not MenuGroup.master:get() or not MenuGroup.enableAi:get() or self.reaper.isActive then
		-- Fix issue with AI trying to equip the last gear forever.
		if LocalPlayer.isEquipping() then
			LocalPlayer.cancelEquip()
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

	self:antiFly(cmd)

	local player = AiUtility.client

	if not player:isAlive() then
		return
	end

	--- @type AiStateBase
	local currentState
	local highestPriority = -1

	--- @param state AiStateBase
	for _, state in pairs(self.states) do repeat
		if state.isBlocked then
			state.isBlocked = false

			break
		end

		if not state.assess then
			error(string.format("The state '%s' does not have an assess() method.", state.name))
		end

		local priority = state:assess()

		if not priority then
			error(string.format("The state '%s' does not return a priority.", state.name))
		end

		if priority > highestPriority then
			currentState = state
			highestPriority = priority
		end
	until true end

	if currentState and ((self.lastPriority and self.lastPriority > highestPriority) or self.lockStateTimer:isElapsed(0.5))then
		self.priority = highestPriority

		if self.lastPriority ~= highestPriority then
			self.lastPriority = highestPriority

			currentState.lastPriority = highestPriority

			local isActivatable = true

			if not currentState.activate then
				isActivatable = false
			elseif self.currentState and Nyx.is(currentState, self.currentState) then
				isActivatable = false
			end

			if isActivatable then
				View.lookSpeedDelay = Math.getRandomFloat(currentState.delayedMouseMin, currentState.delayedMouseMax)

				Pathfinder.clearActivePathAndLastRequest()

				currentState:activate()

				Logger.console(3, "Changed AI state to '%s' [%i].", currentState.name, highestPriority)
			end
		end

		if currentState ~= self.currentState then
			self.lockStateTimer:restart()
		end

		self.currentState = currentState
	end

	if self.currentState then
		self.currentState:think(cmd)
	end

	self:activities(cmd)
	self:antiFlash(cmd)
	self:unscope()
end

return Nyx.class("AiController", AiController)
--}}}
