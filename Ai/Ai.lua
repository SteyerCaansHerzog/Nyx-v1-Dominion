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
local AiChatbot = require "gamesense/Nyx/v1/Dominion/Ai/Chatbot/AiChatbot"
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommand"
local AiProcess = require "gamesense/Nyx/v1/Dominion/Ai/Process/AiProcess"
local AiRoutine = require "gamesense/Nyx/v1/Dominion/Ai/Routine/AiRoutine"
local AiSense = require "gamesense/Nyx/v1/Dominion/Ai/AiSense"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiThreats = require "gamesense/Nyx/v1/Dominion/Ai/AiThreats"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiVoice = require "gamesense/Nyx/v1/Dominion/Ai/Voice/AiVoice"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local DominionClient = require "gamesense/Nyx/v1/Dominion/Client/Client"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local Reaper = require "gamesense/Nyx/v1/Dominion/Reaper/Reaper"
local Version = require "gamesense/Nyx/v1/Dominion/Version"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ Definitions
--- @class AiStateDitherHistory
--- @field state AiStateBase
--- @field timer Timer
--}}}

--{{{ Ai
--- @class Ai : Class
--- @field chatbots AiChatbot
--- @field client DominionClient
--- @field commands AiChatCommand
--- @field currentHighestPriority number
--- @field currentState AiStateBase
--- @field debugPriorities table<string, string>
--- @field ditherHistories AiStateDitherHistory[]
--- @field ditherHistoryMax number
--- @field ditherHistoryTimer Timer
--- @field ditherThreshold number
--- @field isAllowedToBuyGear boolean
--- @field isAntiAfkEnabled boolean
--- @field isEnabled boolean
--- @field processes AiProcess
--- @field routines AiRoutine
--- @field sense AiSense
--- @field states AiStateList
--- @field voice AiVoice
local Ai = {}

--- @param fields Ai
--- @return Ai
function Ai:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function Ai:__init()
	self:initFields()
	self:initEvents()

	Logger.console(Logger.OK, Localization.aiReady)
end

--- @return void
function Ai:initFields()
	self:initMenu()

	AiUtility.ai = self

	self.isAntiAfkEnabled = false
	self.ditherHistories = {}
	self.ditherHistoryMax = 16
	self.ditherThreshold = 8
	self.ditherHistoryTimer = Timer:new():start()
	self.debugPriorities = {}
	self.sense = AiSense

	if Config.isLiveClient and not Config.isAdministrator(Client.xuid) then
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

	-- AI voice packs.
	self.voice = AiVoice:new()

	-- Chatbots.
	local chatbots = {}

	chatbots.normal = AiChatbot.normal:new({
		ai = self
	})

	chatbots[Config.gptVersion] = AiChatbot[Config.gptVersion]:new({
		ai = self
	})

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

	-- States.
	local states = {}

	--- @param state AiStateBase
	for id, state in pairs(AiState) do repeat
		local isEnabled = true
		local err = state:getError()

		if err then
			isEnabled = false
		end

		local object = state:new({
			ai = self
		})

		object.isEnabled = isEnabled

		states[id] = object

		if isEnabled  then
			Logger.console(Logger.OK, Localization.aiStateLoaded, state.name)
		else
			Logger.console(Logger.WARNING, Localization.aiStateNotLoaded, state.name, err)
		end
	until true end

	self.states = states
	self.currentState = AiState.idle
	self.currentHighestPriority = 0

	self:validateFsmStates()
end

--- @return void
function Ai:initMenu()
	MenuGroup.enableAi = MenuGroup.group:addCheckbox("> Enable AI"):setParent(MenuGroup.master):addCallback(function(item)
		local bool = item:get()

		Pathfinder.isEnabled = bool
		AiUtility.isPerformingCalculations = bool
		self.isEnabled = bool
		self.currentHighestPriority = nil
		self.currentState = nil

		Pathfinder.clearActivePathAndLastRequest()
	end)

	MenuGroup.enableAutoBuy = MenuGroup.group:addCheckbox("    > Buy Weapons"):addCallback(function(item)
		-- This is here because setting isEnabled on the routine is circular-referential.
		self.isAllowedToBuyGear = item:get()
	end):setParent(MenuGroup.enableAi)

	MenuGroup.visualiseAi = MenuGroup.group:addCheckbox("    > Visualise AI"):setParent(MenuGroup.enableAi)
	MenuGroup.visualiseAiStates = MenuGroup.group:addCheckbox("        > Visualise States"):set(true):setParent(MenuGroup.visualiseAi)
	MenuGroup.visualiseAiSense = MenuGroup.group:addCheckbox("        > Visualise Senses"):set(true):setParent(MenuGroup.visualiseAi)
	MenuGroup.enableDim = MenuGroup.group:addCheckbox("        > Enable Dim"):set(true):setParent(MenuGroup.visualiseAi)
	MenuGroup.enableAimbot = MenuGroup.group:addCheckbox("    > Enable Aim System"):setParent(MenuGroup.enableAi)
	MenuGroup.visualiseAimbot = MenuGroup.group:addCheckbox("        > Visualise Aimbot"):setParent(MenuGroup.enableAimbot)
end

--- @return void
function Ai:initEvents()
	Callbacks.levelInit(function()
		if not Server.isIngame() then
			Logger.console(Logger.WARNING, Localization.aiNotInGame)

			return
		end

		self.currentState = nil

		Pathfinder.clearActivePathAndLastRequest(true)

		--- @param state AiStateBase
		for _, state in pairs(self.states) do
			local isEnabled = true
			local err = state:getError()

			if err then
				isEnabled = false
			end

			if state.reset then
				state:reset()
			end

			state.isEnabled = isEnabled

			if isEnabled  then
				Logger.console(Logger.OK, Localization.aiStateLoaded, state.name)
			else
				Logger.console(Logger.WARNING, Localization.aiStateNotLoaded, state.name, err)
			end
		end
	end)

	Callbacks.frame(function()
		if not MenuGroup.master:get() then
			return
		end

		if self.ditherHistoryTimer:isElapsedThenRestart(6) and not Table.isEmpty(self.ditherHistories) then
			table.remove(self.ditherHistories, 1)
		end

		self:render()
	end)

	Client.onNextTick(function()
		Callbacks.setupCommand(function(cmd)
			if self.debugPre then
				self:debugPre(cmd)
			end

			if self.isAntiAfkEnabled then
				cmd.in_duck = true
			end

			self:think(cmd)

			if self.debugPost then
				self:debugPost(cmd)
			end
		end, false)
	end)

	Callbacks.roundStart(function()
		if not MenuGroup.master:get() or not MenuGroup.enableAi:get() then
			return
		end

		self.currentHighestPriority = nil
		self.currentState = nil
	end)

	Callbacks.playerChat(function(e)
		if not MenuGroup.master:get() then
			return
		end

		self:processCommand(e, false)
	end)

	Callbacks.consoleInput(function(e)
		if not MenuGroup.master:get() then
			return
		end

		--- @type PlayerChatEvent
		local params = {
			text = e,
			teamonly = true,
			sender = LocalPlayer,
			name = LocalPlayer:getName()
		}

		self:processCommand(params, true)
	end)
end

--- @param e PlayerChatEvent
--- @return void
function Ai:processCommand(e, isInvokedByConsole)
	local validPrefixes = {
		["/"] = true,
		["."] = true,
		["!"] = true,
		[" "] = true
	}

	local cmdPrefix = e.text:sub(1, 1)

	if not validPrefixes[cmdPrefix] then
		return
	end

	local isOtherBot = cmdPrefix == " "

	local args = Table.getTableFromStringByDelimiter(e.text:sub(2), " ")
	local cmd = table.remove(args, 1)
	--- @type AiChatCommandBase
	local command = self.commands[cmd]

	if not command then
		return
	end

	local rejection = command:getRejectionError(self, e.sender, args, isInvokedByConsole)

	if rejection then
		Logger.console(Logger.ALERT, Localization.chatCommandRejected, cmd, e.sender:getName(), rejection)

		return
	end

	local argsImploded = Table.getStringFromTableWithDelimiter(args, ", ")
	local errString = command:invoke(self, e.sender, args, isOtherBot)

	if errString then
		Logger.console(Logger.ALERT, Localization.chatCommandIgnored, cmd, e.sender:getName(), errString)

		return
	end

	if argsImploded == "" then
		Logger.console(Logger.OK, Localization.chatCommandExecutedNoArgs, cmd, e.sender:getName())
	else
		Logger.console(Logger.OK, Localization.chatCommandExecutedArgs, cmd, e.sender:getName(), argsImploded)
	end
end

--- @return void
function Ai:render()
	if not MenuGroup.visualiseAi:get() then
		return
	end

	if not LocalPlayer then
		return
	end

	local uiPos = Vector2:new(20, 20)
	local fontColor = ColorList.FONT_NORMAL
	local spacerColor = ColorList.FONT_MUTED_EXTRA
	local spacerDimensions = Vector2:new(200, 1)
	local offset = 18

	local teamColors = {
		[2] = Color:hsla(35, 0.8, 0.6),
		[3] = Color:hsla(200, 0.8, 0.6)
	}

	local nameBgColor = ColorList.BACKGROUND_3
	local teamNames = {
		[2] = "T",
		[3] = "CT"
	}
	local team = teamNames[LocalPlayer:m_iTeamNum()]
	local name = string.format("( %s ) %s", team, LocalPlayer:getName())

	if not team then
		return
	end

	local screenBgColor = Color:rgba(0, 0, 0, 80)

	if not LocalPlayer:isAlive() then
		name = name .. " (DEAD)"
		nameBgColor = Color:rgba(255, 50, 50, 255)
	end

	local screenDimensions = Client.getScreenDimensions()
	
	if MenuGroup.enableDim:get() then
		Vector2:new():drawSurfaceRectangle(screenDimensions, screenBgColor)
	end

	self.states.engage:render()

	local nameWidth = ISurface.getTextSize(Font.SMALL_BOLD, name)

	uiPos:clone():offset(-5):drawSurfaceRectangle(Vector2:new(nameWidth + 10, 25), nameBgColor)
	uiPos:drawSurfaceText(Font.SMALL_BOLD, teamColors[LocalPlayer:m_iTeamNum()], "l", name)
	uiPos:offset(0, offset)

	uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
	uiPos:offset(0, 10)

	if self.client and self.client.allocation then
		uiPos:drawSurfaceText(Font.TINY, fontColor, "l", string.format(
			"Assigned to %s",
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

	uiPos:drawSurfaceText(Font.TINY, fontColor, "l", string.format(
		"v%s | %s %i:%i (KD %i/%i)",
		Version.number,
		roundType,
		teamWins,
		enemyWins,
		LocalPlayer:m_iKills(),
		LocalPlayer:m_iDeaths()
	))

	uiPos:offset(0, offset)

	local fps = Client.getFpsDelayed()
	local tickErrorPct = math.max(0, (1 - (fps / (1 / globals.tickinterval())))) * 100
	local hue = Math.getFloat(Math.getClamped(fps, 0, 70), 70) * 100
	local fpsColor = Color:hsla(hue, 0.8, 0.6)

	uiPos:drawSurfaceText(Font.TINY, fpsColor, "l", string.format(
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

		uiPos:drawSurfaceText(Font.TINY, svrColor, "l", string.format(
			"SVR: %ims | %.2f%% loss",
			ping,
			loss
		))

		uiPos:offset(0, offset)
	end

	local skill = self.states.engage.skill

	if skill == -1 then
		skill = "Practice"
	end

	uiPos:drawSurfaceText(Font.TINY, fontColor, "l", string.format(
		"Skill: %s",
		skill
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
		uiPos:drawSurfaceText(Font.TINY, fontColor, "l", string.format(
			"State: %s",
			self.currentState.name
		))

		uiPos:offset(0, offset)

		uiPos:drawSurfaceText(Font.TINY, fontColor, "l", string.format(
			"Priority: %s [%i]",
			AiStateBase.priorityMap[self.currentHighestPriority],
			self.currentHighestPriority
		))

		uiPos:offset(0, offset)

		local activity = self.currentState.activity and self.currentState.activity or "Unknown"

		uiPos:drawSurfaceText(Font.TINY, fontColor, "l", string.format(
			"Activity: %s",
			activity
		))

		uiPos:offset(0, offset)
	else
		uiPos:drawSurfaceText(Font.TINY, ColorList.FONT_MUTED_EXTRA, "l", "State: NONE")
		uiPos:offset(0, offset)

		uiPos:drawSurfaceText(Font.TINY, ColorList.FONT_MUTED_EXTRA, "l", "Priority: NONE")
		uiPos:offset(0, offset)

		uiPos:drawSurfaceText(Font.TINY, ColorList.FONT_MUTED_EXTRA, "l", "Activity: NONE")
		uiPos:offset(0, offset)
	end

	if VirtualMouse.lookState and VirtualMouse.lookState ~= "None" then
		uiPos:drawSurfaceText(Font.TINY, fontColor, "l", string.format(
			"VMouse: %s",
			VirtualMouse.lookState
		))

		uiPos:offset(0, offset)
	else
		uiPos:drawSurfaceText(Font.TINY, ColorList.FONT_MUTED_EXTRA, "l", "VMouse: NONE")
		uiPos:offset(0, offset)
	end

	if Pathfinder.path then
		if Pathfinder.isOnValidPath() then
			uiPos:drawSurfaceText(Font.TINY, fontColor, "l", string.format(
				"Task: %s",
				Pathfinder.path.task
			))

			uiPos:offset(0, offset)
		else
			uiPos:drawSurfaceText(Font.TINY, ColorList.ERROR, "l", string.format(
				string.format("Error: %s", Pathfinder.path.errorMessage),
				Pathfinder.path.task
			))

			uiPos:offset(0, offset)
		end
	else
		uiPos:drawSurfaceText(Font.TINY, ColorList.FONT_MUTED_EXTRA, "l", "Task: NONE")

		uiPos:offset(0, offset)
	end

	uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
	uiPos:offset(0, 10)

	if MenuGroup.visualiseAiSense:get() then
		if AiThreats.threatLevel then
			local map = {
				[AiThreats.threatLevels.NONE] = "No Threats",
				[AiThreats.threatLevels.LOW] = "Low",
				[AiThreats.threatLevels.MEDIUM] = "Medium",
				[AiThreats.threatLevels.HIGH] = "High",
				[AiThreats.threatLevels.EXTREME] = "Extreme"
			}

			local mod = Math.getInversedFloat(AiThreats.threatLevel, 4) * 80
			local color = Color:hsla(mod, 0.8, 0.6, 255)

			uiPos:drawSurfaceText(Font.EXTRA_TINY, color, "l", string.format(
				"Threat Level: %s",
				map[AiThreats.threatLevel]
			))
			uiPos:offset(0, 14)

			uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
			uiPos:offset(0, 10)
		end

		local baseColor = Color:hsla(20, 0.8, 0.6)
		local isEmpty = true

		for _, enemy in pairs(AiUtility.enemies) do
			isEmpty = false

			local awarenessLevel, awarenessReason = AiSense.getAwareness(enemy)
			local awarenessString = AiSense.awarenessStrings[awarenessLevel]
			local float = Math.getInversedFloat(awarenessLevel, 8)
			local color = baseColor:clone():shiftHue(120 * float)

			uiPos:drawSurfaceText(Font.EXTRA_TINY, color, "l", string.format(
				"%s (%s, %s)",
				enemy:getName(),
				awarenessString,
				awarenessReason
			))

			uiPos:offset(0, 14)
		end

		if isEmpty then
			uiPos:drawSurfaceText(Font.EXTRA_TINY, ColorList.FONT_NORMAL, "l", "NO ENEMIES ARE SENSED")
			uiPos:offset(0, 14)
		end

		uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
		uiPos:offset(0, 10)
	end

	if MenuGroup.visualiseAiStates:get() then
		-- Debug priorities
		if not Table.isEmpty(self.debugPriorities) then
			for stateName, priority in Table.sortedPairs(self.debugPriorities, function(a, b)
				return a > b
			end) do
				local priorityColor = fontColor

				if Debug.highlightStates[stateName] then
					priorityColor = ColorList.OK
				end

				uiPos:drawSurfaceText(Font.EXTRA_TINY, priorityColor, "l", string.format(
					"%s (%s)",
					stateName,
					AiStateBase.priorityMap[priority]
				))

				uiPos:offset(0, 14)
			end
		end
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function Ai:think(cmd)
	if not MenuGroup.master:get() or not MenuGroup.enableAi:get() or self.reaper.isActive then
		-- Fix issue with AI trying to equip the last gear forever.
		if LocalPlayer.isEquipping() then
			LocalPlayer.cancelEquip()
		end

		return
	end

	if not Server.isIngame() then
		return
	end

	if Entity.getGameRules():m_bWarmupPeriod() == 1 then
		return
	end

	if not LocalPlayer:isAlive() then
		return
	end

	self:processFiniteStateMachine(cmd)
end

--- @param cmd SetupCommandEvent
--- @return void
function Ai:debugPre(cmd) end

--- @param cmd SetupCommandEvent
--- @return void
function Ai:debugPost(cmd) end

--- @param cmd SetupCommandEvent
--- @return void
function Ai:processFiniteStateMachine(cmd)
	self:handleFsmStateDithering()

	local state, priority = self:getHighestFsmState()

	self:setFsmState(state, priority, cmd)
	self:handleFsmRoutines(cmd)
end

--- @return void
function Ai:handleFsmStateDithering()
	-- Cap the histories.
	if #self.ditherHistories >= self.ditherHistoryMax then
		table.remove(self.ditherHistories, 1)
	end

	local currentState = self.ditherHistories[1]
	local count = 1

	for i = 2, #self.ditherHistories do
		local testState = self.ditherHistories[i]

		if currentState.state.__classid  == testState.state.__classid then
			count = count + 1
		end
	end

	-- Did not dither enough.
	if count < self.ditherThreshold then
		return
	end

	-- Not permitted to lock. This state is critical to AI survivability.
	-- Would have to fix dithering through state logic.
	if not currentState.state.isLockable then
		return
	end

	currentState.state.abuseLockTimer:start()

	self.ditherHistories = {}

	Logger.console(Logger.ERROR, Localization.aiDitherLocked, currentState.state.name)
end

--- @return AiStateBase, number
function Ai:getHighestFsmState()
	--- @type AiStateBase
	local bestState
	local highestPriority = -1
	local debugPriorities = {}

	--- @param state AiStateBase
	for _, state in pairs(self.states) do repeat
		state.isCurrentState = false

		if not state.isEnabled then
			break
		end

		if state.isBlocked then
			state.isBlocked = false

			break
		end

		local priority = state:getAssessment()

		-- If a state yields no priority, we assume the programmer has made a mistake.
		if not priority then
			error(string.format(Localization.aiNoPriority, state.name))
		end

		if priority > -1 then
			debugPriorities[state.name] = priority
		end

		if priority <= highestPriority then
			break
		end

		highestPriority = priority
		bestState = state
	until true end

	self.debugPriorities = debugPriorities

	if highestPriority == self.currentHighestPriority then
		bestState = self.currentState
	end

	return bestState, highestPriority
end

--- This is a suboptimal state machine. Should have enter *and* exit conditions for states.
---
--- @param state AiStateBase
--- @param priority number
--- @param cmd SetupCommandEvent
--- @return void
function Ai:setFsmState(state, priority, cmd)
	-- No state to be in, so transition to idle.
	if not state then
		self.currentState = AiState.idle
		self.currentHighestPriority = 0

		return
	end

	-- Sync virtual mouse parameters.
	if VirtualMouse.activeViewAngles then
		VirtualMouse.lookState = state.name
		VirtualMouse.isLookSpeedDelayed = state.isMouseDelayAllowed
		VirtualMouse.lookSpeedDelayMin = state.delayedMouseMin
		VirtualMouse.lookSpeedDelayMax = state.delayedMouseMax
		VirtualMouse.lookSpeedDelay = Math.getRandomFloat(state.delayedMouseMin, state.delayedMouseMax)
	end

	-- We do not transition states whose priority is the same.
	if priority == self.currentHighestPriority then
		state:think(cmd)

		return
	end

	state.priority = priority

	local isCurrentStateValid = self.currentState ~= nil
	local isDifferentState = not isCurrentStateValid or not Nyx.is(state, self.currentState)
	local isValidTransition = isDifferentState or state.isQueuedForReactivation

	-- Run the deactivate method.
	if isCurrentStateValid and isDifferentState and self.currentState.deactivate then
		self.currentState:deactivate()
	end

	-- Completely clear the Pathfinder if we're transitioning or reactivating.
	if isValidTransition then
		Pathfinder.flushRequest()
	end

	-- Run the activate method on the state.
	if state.activate and isValidTransition then
		state:activate()

		table.insert(self.ditherHistories, {
			state = state,
			timer = Timer:new():start()
		})

		if state.isQueuedForReactivation then
			Logger.console(Logger.ALERT, Localization.aiStateReactivating, state.name, priority)
		else
			Logger.console(Logger.ALERT, Localization.aiStateTransitioned, state.name, priority)
		end

		state.isQueuedForReactivation = false
	end

	self.currentHighestPriority = priority
	self.currentState = state

	state:think(cmd)
end

--- @param cmd SetupCommandEvent
--- @return void
function Ai:handleFsmRoutines(cmd)
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
end

--- @return void
function Ai:validateFsmStates()
	--- @param state AiStateBase
	for _, state in pairs(self.states) do
		if not state.getAssessment then
			error(string.format(Localization.aiNoAssessMethod, state.name))
		end
	end
end

return Nyx.class("Ai", Ai)
--}}}
