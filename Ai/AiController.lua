--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local ISurface = require "gamesense/Nyx/v1/Api/ISurface"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
-- Components.
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommand"
local AiChatbot = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/AiChatbot"
local AiProcess = require "gamesense/Nyx/v1/Dominion/Ai/Process/AiProcess"
local AiRoutine = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutine"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"

-- Other.
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiVoice = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoice"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local DominionClient = require "gamesense/Nyx/v1/Dominion/Client/Client"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local Reaper = require "gamesense/Nyx/v1/Dominion/Reaper/Reaper"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiController
--- @class AiController : Class
--- @field chatbots AiChatbot
--- @field client DominionClient
--- @field commands AiChatCommand
--- @field currentState AiStateBase
--- @field lastPriority number
--- @field lockStateTimer Timer
--- @field processes AiProcess
--- @field routines AiRoutine
--- @field states AiStateList
--- @field voice AiVoice
local AiController = {}

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
	self.lockStateTimer = Timer:new():startThenElapse()

	if Config.isLiveClient and not Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid()) then
		self.client = DominionClient:new()
	end

	-- Chat commands.
	local commands = {}

	--- @param command AiChatCommandBase
	for id, command in pairs(AiChatCommand) do
		commands[id] = command
	end

	self.commands = commands

	-- Routines.
	local routines = {}

	--- @param routine AiRoutineBase
	for id, routine in pairs(AiRoutine) do
		routines[id] = routine:new({
			ai = self
		})
	end

	self.routines = routines

	-- Chatbots.
	local chatbots = {}

	for id, chatbot in pairs(AiChatbot) do
		chatbots[id] = chatbot:new()
	end

	self.chatbots = chatbots

	self.reaper = Reaper:new({
		ai = self
	})

	-- Processes.
	-- These do not need to be initialised or cleaned up on a per-map basis.
	local processes = {}

	--- @param process AiProcessBase
	for id, process in pairs(AiProcess) do
		processes[id] = process:new({
			ai = self
		})
	end

	self.processes = processes

	self:initMenu()

	self.voice = AiVoice:new()
end

--- @return void
function AiController:initMenu()
	MenuGroup.enableAi = MenuGroup.group:addCheckbox("> Enable AI"):setParent(MenuGroup.master):addCallback(function(item)
		Pathfinder.isEnabled = item:get()
		self.lastPriority = nil
		self.currentState = nil

		Pathfinder.clearActivePathAndLastRequest()
	end)

	MenuGroup.enableAutoBuy = MenuGroup.group:addCheckbox("    | Buy Weapons"):addCallback(function(item)
		self.routines.buyGear.isEnabled = item:get()
	end):setParent(MenuGroup.enableAi)

	MenuGroup.visualiseAi = MenuGroup.group:addCheckbox("    | Visualise AI"):setParent(MenuGroup.enableAi)
	MenuGroup.enableAimbot = MenuGroup.group:addCheckbox("    | Enable Aim System"):setParent(MenuGroup.enableAi)
	MenuGroup.visualiseAimbot = MenuGroup.group:addCheckbox("        | Visualise Aimbot"):setParent(MenuGroup.enableAimbot)
end

--- @return void
function AiController:initEvents()
	Callbacks.init(function()
		if not Server.isIngame() then
			Logger.console(2, "Not in-game. Waiting to join a server before initialising AI states.")

			return
		end

		-- States.
		local states = {}

		--- @param state AiStateBase
		for id, state in pairs(AiState) do repeat
			local err = state:getError()

			if err then
				Logger.console(
					2,
					"AI state '%s' not loaded. %s.",
					state.name,
					err
				)

				break
			end

			local object = state:new({
				ai = self
			})

			states[id] = object

			Logger.console(0, "AI state '%s' successfully loaded.", state.name)
		until true end

		self.states = states
	end)

	Callbacks.frame(function()
		if not MenuGroup.master:get() then
			return
		end

		self:renderUi()
	end)

	Client.onNextTick(function()
		Callbacks.setupCommand(function(cmd)
			self:think(cmd)
		end)
	end)

	Callbacks.roundStart(function()
		if not self.reaper.isEnabled then
			Client.openConsole()
		end

		if not MenuGroup.master:get() or not MenuGroup.enableAi:get() then
			return
		end

		self.lastPriority = nil
		self.currentState = nil
	end)

	Callbacks.playerChat(function(e)
		if not MenuGroup.master:get() then
			return
		end

		self:handleChatCommands(e)
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

--- @param e PlayerChatEvent
--- @return void
function AiController:handleChatCommands(e)
	if not e.text:sub(1, 1) == "/" then
		return
	end

	local args = Table.getExplodedString(e.text:sub(2), " ")
	local cmd = table.remove(args, 1)
	--- @type AiChatCommandBase
	local command = self.commands[cmd]

	if not command then
		return
	end

	local rejection = command:getRejectionError(self, e.sender, args)

	if rejection then
		Logger.console(3, "Rejected chat command '/%s' from '%s' because %s.", cmd, e.sender:getName(), rejection)

		return
	end

	local argsImploded = Table.getImploded(args, ", ")
	local ignored = command:invoke(self, e.sender, args)

	if ignored then
		Logger.console(3, "Ignoring chat command '/%s' from '%s' because %s.", cmd, e.sender:getName(), ignored)

		return
	end

	if argsImploded == "" then
		Logger.console(0, "Executing chat command '/%s' from '%s'.", cmd, e.sender:getName())
	else
		Logger.console(0, "Executing chat command '/%s' from '%s' with '%s'.", cmd, e.sender:getName(), argsImploded)
	end
end

--- @return void
function AiController:renderUi()
	if not MenuGroup.visualiseAi:get() then
		return
	end

	if not LocalPlayer then
		return
	end

	local uiPos = Vector2:new(20, 20)
	local fontColor = ColorList.FONT_NORMAL
	local spacerColor = ColorList.FONT_MUTED
	local spacerDimensions = Vector2:new(200, 1)
	local offset = 25

	local teamColors = {
		[2] = Color:hsla(35, 0.8, 0.6),
		[3] = Color:hsla(200, 0.8, 0.6)
	}

	local nameBgColor = ColorList.FONT_MUTED
	local teamNames = {
		[2] = "T",
		[3] = "CT"
	}
	local team = teamNames[LocalPlayer:m_iTeamNum()]
	local name = string.format("( %s ) %s", team, LocalPlayer:getName())

	if not team then
		return
	end

	local screenBgColor = Color:rgba(0, 0, 0, 200)

	if not LocalPlayer:isAlive() then
		name = name .. " (DEAD)"
		nameBgColor = Color:rgba(255, 50, 50, 255)
		screenBgColor = Color:rgba(150, 25, 25, 150)
	end

	local screenDimensions = Client.getScreenDimensions()

	Vector2:new():drawSurfaceRectangle(screenDimensions, screenBgColor)

	self.states.engage:render()

	local nameWidth = ISurface.getTextSize(Font.MEDIUM_BOLD, name)

	uiPos:clone():offset(-5):drawSurfaceRectangle(Vector2:new(nameWidth + 10, 25), nameBgColor)
	uiPos:drawSurfaceText(Font.MEDIUM_BOLD, teamColors[LocalPlayer:m_iTeamNum()], "l", name)
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

	if LocalPlayer:isTerrorist() then
		teamWins = tWins
		enemyWins = ctWins
	elseif LocalPlayer:isCounterTerrorist() then
		teamWins = ctWins
		enemyWins = tWins
	end

	uiPos:drawSurfaceText(Font.SMALL, fontColor, "l", string.format(
		"%s Match: Score %i : %i | KD %i/%i (%.2f)",
		roundType,
		teamWins,
		enemyWins,
		LocalPlayer:m_iKills(),
		LocalPlayer:m_iDeaths(),
		LocalPlayer:getKdRatio()
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

	if not LocalPlayer:isAlive() then
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

	if MenuGroup.enableAi:get() and AiUtility.clientThreatenedFromOrigin then
		Client.draw(Vector3.drawCircleOutline, AiUtility.clientThreatenedFromOrigin, 30, 3, Color:hsla(0, 1, 1, 75))
	end
end

--- @type AiStateBase[]
local ditherLog = {}

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

	if not LocalPlayer:isAlive() then
		return
	end

	if #ditherLog > 32 then
		table.remove(ditherLog, 1)
	end

	local repeats = 0
	--- @type AiStateBase
	local a = ditherLog[1]
	--- @type AiStateBase
	local b = ditherLog[2]

	if a and b and ditherLog[3] then
		a = ditherLog[1]
		b = ditherLog[2]

		for i = 3, #ditherLog do
			local id = ditherLog[i].__classid

			if i % 2 == 0 then
				if id == b.__classid then
					repeats = repeats + 1
				end
			else
				if id == a.__classid then
					repeats = repeats + 1
				end
			end
		end
	end

	if repeats >= 10 then
		local highest = a.priority > b.priority and a or b

		--highest.abuseLockTimer:restart()

		Logger.console(1, "AI state '%s' was locked due to dithering. Please check assessment logic for faults.", highest.name)

		ditherLog = {}
	end

	--- @type AiStateBase
	local currentState
	local highestPriority = -1
	local debugPriority = {}

	--- @param state AiStateBase
	for _, state in pairs(self.states) do repeat
		state.isCurrentState = false

		if state.isBlocked then
			state.isBlocked = false

			break
		end

		if state.abuseLockTimer:isNotElapsed(15) then
			break
		end

		if not state.assess then
			error(string.format("The state '%s' does not have an assess() method.", state.name))
		end

		local priority = state:assess()

		if not priority then
			error(string.format("The state '%s' does not return a priority.", state.name))
		end

		if Debug.isLoggingStatePriorities and priority > -1 then
			debugPriority[state.name] = priority
		end

		if priority > highestPriority then
			currentState = state
			highestPriority = priority
		end
	until true end

	if Debug.isLoggingStatePriorities then
		for name, priority in Table.sortedPairs(debugPriority, function(a, b)
			return a < b
		end) do
			Client.drawIndicatorTick(Color, "%s = %i", name, priority)
		end
	end

	if currentState and ((self.lastPriority and self.lastPriority > highestPriority) or self.lockStateTimer:isElapsed(0.0))then
		local isReactivated = false

		if currentState.isQueuedForReactivation then
			currentState.isQueuedForReactivation = false

			currentState:activate()

			Logger.console(3, "Re-activating AI state '%s' [%i].", currentState.name, highestPriority)
		end

		if self.lastPriority ~= highestPriority then
			self.lastPriority = highestPriority

			currentState.priority = highestPriority
			currentState.isCurrentState = true

			local isActivatable = true

			if not currentState.activate then
				isActivatable = false
			elseif self.currentState and Nyx.is(currentState, self.currentState) then
				isActivatable = false
			elseif isReactivated then
				isActivatable = false
			end

			if isActivatable then
				Logger.console(3, "Changed AI state to '%s' [%i].", currentState.name, highestPriority)

				View.lookSpeedDelayMin = currentState.delayedMouseMin
				View.lookSpeedDelayMax = currentState.delayedMouseMax
				View.lookSpeedDelay = Math.getRandomFloat(currentState.delayedMouseMin, currentState.delayedMouseMax)
				View.lookState = currentState.name

				Pathfinder.flushRequest()

				currentState:activate()

				table.insert(ditherLog, currentState)
			end
		end

		if currentState ~= self.currentState then
			if self.currentState and self.currentState.deactivate then
				self.currentState:deactivate()
			end

			self.lockStateTimer:restart()
		end

		self.currentState = currentState
	end

	if self.currentState then
		self.currentState:think(cmd)
	end

	--- @param routine AiRoutineBase
	for _, routine in pairs(self.routines) do repeat
		if routine.isBlocked then
			routine:whileBlocked()

			routine.isBlocked = false

			break
		end

		if routine.think then
			routine:think(cmd)
		end
	until true end

	-- This is here to control when it is executed.
	if MenuGroup.enableMouseControl:get() then
		View.setViewAngles()
		View.think(cmd)
	end
end

return Nyx.class("AiController", AiController)
--}}}
