--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Localization = require "gamesense/Localization"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Process = require "gamesense/Nyx/v1/Api/Process"
local Server = require "gamesense/Nyx/v1/Api/Server"
local VKey = require "gamesense/Nyx/v1/Api/VKey"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local DominionMenu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
--}}}

--{{{ ReaperClientInfo
--- @class ReaperClientInfo
--- @field name string
--- @field isInGame boolean
--- @field isThreatened boolean
--- @field isAttacked boolean
--- @field isFlashed boolean
--- @field isAlive boolean
--- @field behavior string
--- @field activity string
--- @field skill number
--- @field map string
--- @field callout string
--- @field health number
--- @field lastKeepAliveAt number
--}}}

--{{{ ReaperClient
--- @class ReaperClient : Class
--- @field index number
--- @field steamId64 number
--- @field window number
--- @field info ReaperClientInfo
local ReaperClient = {}

--- @param fields ReaperClient
--- @return ReaperClient
function ReaperClient:new(fields)
	return Nyx.new(self, fields)
end

Nyx.class("ReaperClient", ReaperClient)
--}}}

--{{{ ReaperManifest
--- @class ReaperManifest : Class
--- @field client ReaperClient
--- @field clients ReaperClient[]
--- @field isEnabled boolean
--- @field path string
--- @field raw string
--- @field steamId64Map boolean[]
--- @field windowHandleMap boolean[]
local ReaperManifest = {
	path = "lua/gamesense/Nyx/v1/Dominion/Resource/Data/ReaperManifest.json"
}

--- @param fields ReaperManifest
--- @return ReaperManifest
function ReaperManifest:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function ReaperManifest:__init()
	local fileData = readfile(self.path)

	if not fileData then
		self.isEnabled = false

		error("'ReaperManifest.json' does not exist.")

		return
	end

	self.raw = fileData

	local manifest = json.parse(fileData)

	self.isEnabled = manifest.isEnabled

	if not self.isEnabled then
		print("Reaper is not enabled.")

		return
	end

	--- @type ReaperClient
	local clients = {}
	local index = 1
	local clientKeysSorted = {}
	local steamId64 = Panorama.MyPersonaAPI.GetXuid()
	local steamId64Map = {}
	local windowHandleMap = {}

	for key in pairs(manifest.clients) do
		table.insert(clientKeysSorted, key)
	end

	table.sort(clientKeysSorted)

	for _, key in ipairs(clientKeysSorted) do
		local window = manifest.clients[key]

		local client = ReaperClient:new({
			index = index,
			steamId64 = key,
			window = window
		})

		if client.steamId64 == steamId64 then
			self.client = client
		end

		clients[index] = client
		index = index + 1
		steamId64Map[client.steamId64] = true
		windowHandleMap[client.window] = true
	end

	if not self.client then
		self.isEnabled = false

		return
	end

	self.clients = clients
	self.steamId64Map = steamId64Map
	self.windowHandleMap = windowHandleMap

	Client.fireAfter(5, function()
		self:verifyManifest()
	end)
end

--- @return void
function ReaperManifest:verifyManifest()
	local fileData = readfile(self.path)

	if not fileData then
		self.isEnabled = false

		error("'ReaperManifest.json' does not exist.")

		return
	end

	self.raw = fileData

	local manifest = json.parse(fileData)
	local isReaperStale = false

	for steamId64, windowHandle in pairs(manifest.clients) do
		if not self.steamId64Map[steamId64] then
			isReaperStale = true

			print("New Reaper account detected.")

			break
		end

		if not self.windowHandleMap[windowHandle] then
			isReaperStale = true

			print("A Reaper account has been restarted.")

			break
		end
	end

	if isReaperStale then
		Client.reloadApi()

		return
	end

	Client.fireAfter(5, function()
		self:verifyManifest()
	end)
end

--- @return void
function ReaperManifest:restore()
	writefile(self.path, self.raw)
end

Nyx.class("ReaperManifest", ReaperManifest)
--}}}

--{{{ Reaper
--- @class Reaper : Class
--- @field ai AiController
--- @field gameConfig string
--- @field isActive boolean
--- @field isAiEnabled boolean
--- @field isClientAdmin boolean
--- @field isEnabled boolean
--- @field keyHotSwap VKey
--- @field keyTakeControl VKey
--- @field lastActiveState boolean
--- @field lastFocusedState boolean
--- @field manifest ReaperManifest
--- @field keyOpenConsole VKey
--- @field keySuppressAiEnable VKey
--- @field isSuppressed boolean
--- @field syncInfoTimer Timer
--- @field infoPath string
--- @field clientBoxFocusedOffset number
local Reaper = {
	gameConfig = "reaper",
	infoPath = "lua/gamesense/Nyx/v1/Dominion/Resource/Data/ReaperClientInfo_%s.json"
}

--- @param fields Reaper
--- @return Reaper
function Reaper:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function Reaper:__init()
	self:initFields()
	self:initEvents()
end

--- @return void
function Reaper:initFields()
	self.isActive = false
	self.isAiEnabled = true
	self.isClientAdmin = Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid())
	self.keyHotSwap = VKey:new(VKey.TAB)
	self.keyTakeControl = VKey:new(VKey.F)
	self.keyOpenConsole = VKey:new(VKey.PUNCT_BACKTICK)
	self.keySuppressAiEnable = VKey:new(VKey.L)
	self.syncInfoTimer = Timer:new():start()
	self.manifest = ReaperManifest:new()
	self.clientBoxFocusedOffset = 0

	self.isEnabled = self.manifest.isEnabled

	DominionMenu.disableHud:set(false)
	DominionMenu.limitFps:set(false)

	DominionMenu.group:button("Restore Reaper Manifest", function()
		self.manifest:restore()
	end)
end

--- @return void
function Reaper:initEvents()
	if self.isEnabled then
		self:setConfig("Nyx-v1-Dominion-Reaper")

		Callbacks.frameGlobal(function()
			self:think()
			self:render()
		end)

		Callbacks.roundStart(function()
			Client.closeConsole()
		end)
	end

	Callbacks.shutdown(function()
		Client.setInput(true)
		Client.setTextMode(false)
	end)
end

--- @return void
function Reaper:render()
	if not Server.isIngame() then
		return
	end

	--- @type Vector2
	local drawPosition
	local clientBoxDimensions = Vector2:new(350, 50)
	local clientBoxTopOffset = -75
	local clientBoxRightOffset = -300
	local clientBoxBottomMargin = 12
	local clientBoxLeftMargin = 25
	local screenCenter = Client.getScreenDimensionsCenter()
	local alphaMod = 0.9

	if self.isActive then
		drawPosition = Vector2:new(clientBoxLeftMargin, screenCenter.y)
		alphaMod = 0.5

		drawPosition.y = drawPosition.y + clientBoxTopOffset
	else
		drawPosition = screenCenter

		drawPosition.x = drawPosition.x - clientBoxDimensions.x + clientBoxRightOffset
		drawPosition.y = drawPosition.y + clientBoxTopOffset
	end

	local alphaMods = {
		IS_FLASHED = Animate.sine(0.5, 0.2, 30),
		IS_ATTACKED = Animate.sine(0.25, 0.2, 20),
		IS_THREATENED = Animate.sine(0.33, 0.2, 10)
	}

	local colors = {
		TEXT_MAIN = Color:hsla(0, 0, 1, 255 * alphaMod),
		TEXT_MUTED = Color:hsla(0, 0, 0.66, 255 * alphaMod),
		TEXT_DEAD = Color:hsla(0, 0.8, 0.6, 255 * alphaMod),
		TEXT_ATTACKED = Color:hsla(26, 0.8, 0.55, 255 * alphaMod),
		TEXT_THREATENED = Color:hsla(40, 0.5, 0.55, 255 * alphaMod),

		IS_FINE = Color:hsla(210, 0.0, 0.2, 100 * alphaMod),
		IS_FLASHED = Color:hsla(0, 0, 1, 255 * alphaMod),

		IS_ATTACKED = Color:hsla(26, 0.8, 0.5, 255 * alphaMod),
		IS_THREATENED = Color:hsla(40, 0.5, 0.5, 100 * alphaMod),
		IS_DEAD = Color:hsla(0, 0.5, 0.5, 50 * alphaMod),

		IS_DISCONNECTED = Color:hsla(0, 0.0, 0.35, 100 * alphaMod),

		IS_CLIENT_OUTLINE = Color:hsla(0, 0.0, 0.8, 255 * alphaMod),
		IS_CLIENT_BG = Color:hsla(0, 0.0, 0.55, 100 * alphaMod),
		IS_IN_SERVER = Color:hsla(205, 0.4, 0.5, 75 * alphaMod),
	}

	for _, client in pairs(self.manifest.clients) do repeat
		if not client.info then
			break
		end

		local player = Player.getBySteamid64(client.steamId64)
		local nameColor = colors.TEXT_MAIN
		local infoColor = colors.TEXT_MAIN
		local bgColor = colors.IS_FINE
		local bgAlphaMod = 1
		local isPlayerAlive = client.info.isAlive
		local isPlayerInServer = player ~= nil
		local isConnectionLost = (Time.getUnixTimestamp() - client.info.lastKeepAliveAt) > 3
		local isClientStateOkayToShow = true
		local isClient = client.steamId64 == self.manifest.client.steamId64
		local isFocused = Process.isAppFocused()

		if isConnectionLost then
			bgColor = colors.IS_DISCONNECTED
			nameColor = colors.TEXT_MUTED
			infoColor = colors.TEXT_MUTED

			isClientStateOkayToShow = false
		elseif not client.info.isInGame then
			bgColor = colors.IS_DISCONNECTED
			nameColor = colors.TEXT_MUTED
			infoColor = colors.TEXT_MUTED

			isClientStateOkayToShow = false
		elseif isClient then
			nameColor = colors.TEXT_MAIN
			infoColor = colors.TEXT_MAIN

			isClientStateOkayToShow = false
		elseif not isPlayerInServer then
			nameColor = colors.TEXT_MUTED
			infoColor = colors.TEXT_MUTED
		end

		if isClientStateOkayToShow then
			if not isPlayerAlive then
				bgColor = colors.IS_DEAD
				nameColor = colors.TEXT_DEAD
				infoColor = colors.TEXT_DEAD
			elseif client.info.isFlashed then
				bgColor = colors.IS_FLASHED
				bgAlphaMod = alphaMods.IS_FLASHED
				nameColor = colors.TEXT_MAIN
				infoColor = colors.TEXT_MAIN
			elseif client.info.isAttacked then
				bgColor = colors.IS_ATTACKED
				bgAlphaMod = alphaMods.IS_ATTACKED
				nameColor = colors.TEXT_ATTACKED
				infoColor = colors.TEXT_ATTACKED
			elseif client.info.isThreatened then
				bgColor = colors.IS_THREATENED
				nameColor = colors.TEXT_THREATENED
				infoColor = colors.TEXT_THREATENED
				bgAlphaMod = alphaMods.IS_THREATENED
			end
		end

		bgColor = bgColor:clone()
		bgColor.a = bgColor.a * bgAlphaMod

		if isFocused then
			self.clientBoxFocusedOffset = Animate.slerp(self.clientBoxFocusedOffset, 10, 1.66)
		else
			self.clientBoxFocusedOffset = Animate.slerp(self.clientBoxFocusedOffset, 0, 1.66)
		end

		if self.isActive then
			self.clientBoxFocusedOffset = 0
		end

		if isClient then
			bgColor = colors.IS_CLIENT_BG

			drawPosition:offset(self.clientBoxFocusedOffset)
			drawPosition:drawSurfaceRectangleOutline(2, 2, clientBoxDimensions, colors.IS_CLIENT_OUTLINE)
		else
			drawPosition:drawSurfaceRectangleOutline(2, 2, clientBoxDimensions, bgColor:clone():setAlpha(50 * alphaMod))
		end

		drawPosition:drawBlur(clientBoxDimensions, 1, 1)
		drawPosition:drawSurfaceRectangle(clientBoxDimensions, bgColor)
		drawPosition:clone():offset(5, 0):drawSurfaceText(Font.MEDIUM_LARGE, nameColor, "l", client.info.name)

		if isConnectionLost then
			drawPosition:clone():offset(5, 25):drawSurfaceText(Font.SMALL, colors.TEXT_MUTED, "l", "CONNECTION LOST")

			drawPosition:offset(0, clientBoxDimensions.y + clientBoxBottomMargin)

			break
		end

		if client.info.isInGame then
			if isPlayerAlive then
				drawPosition:clone():offset(5, 25):drawSurfaceText(Font.SMALL, infoColor, "l", client.info.activity)
			else
				drawPosition:clone():offset(5, 25):drawSurfaceText(Font.SMALL, infoColor, "l", "Dead")
			end
		else
			drawPosition:clone():offset(5, 25):drawSurfaceText(Font.SMALL, infoColor, "l", "Disconnected")
		end

		-- Skill level
		drawPosition:clone():offset(clientBoxDimensions.x - 14):drawSurfaceText(Font.SMALL_BOLD, colors.TEXT_MUTED, "c", client.info.skill)
		drawPosition:clone():offset(clientBoxDimensions.x - 21, 6):drawSurfaceRectangleOutline(1, 4, Vector2:new(15, 10), colors.TEXT_MUTED:clone():setAlpha(33 * alphaMod))

		if isPlayerAlive then
			if client.info.health then
				local healthPct

				if client.info.health < 20 then
					healthPct = 0
				else
					healthPct = Math.getFloat(client.info.health, 100)
				end

				local healthColor = Color:hsla(100 * healthPct, 0.8, 0.6, 255 * alphaMod)

				-- Health
				drawPosition:clone():offset(clientBoxDimensions.x - 18 - 28):drawSurfaceText(Font.SMALL_BOLD, healthColor, "c", client.info.health)
				drawPosition:clone():offset(clientBoxDimensions.x - 31 - 28, 6):drawSurfaceRectangleOutline(1, 4, Vector2:new(25, 10), healthColor:clone():setAlpha(33 * alphaMod))
			end

			if client.info.map then
				if isPlayerInServer then
					drawPosition:clone():offset(clientBoxDimensions.x - 5, 25):drawSurfaceText(Font.SMALL, infoColor, "r", client.info.callout)
				else
					drawPosition:clone():offset(clientBoxDimensions.x - 5, 25):drawSurfaceText(Font.SMALL, infoColor, "r", "In other match")
				end
			end
		end

		if isClient then
			drawPosition:offset(-self.clientBoxFocusedOffset)
		end

		drawPosition:offset(0, clientBoxDimensions.y + clientBoxBottomMargin)
	until true end
end

--- @return void
function Reaper:think()
	if self.syncInfoTimer:isElapsedThenRestart(0.05) then
		local behavior = "Inactive"
		local activity = "Inactive"

		if DominionMenu.enableAi:get() and self.ai.currentState then
			behavior = self.ai.currentState.name
			activity = self.ai.currentState.activity or "Unknown"
		end

		if self.isActive then
			activity = "Possessed"
		end

		local map
		local callout
		local health
		local isAlive = false

		if Server.isIngame() then
			map = globals.mapname()
			callout = Localization.get(AiUtility.client:m_szLastPlaceName())
			health = AiUtility.client:m_iHealth()
			isAlive = AiUtility.client:isAlive()
		end

		--- @type ReaperClientInfo
		local info = {
			name = Panorama.MyPersonaAPI.GetName(),
			isInGame = Server.isIngame(),
			isFlashed = Client.isFlashed(),
			isAttacked = AiUtility.isEnemyVisible,
			isThreatened = AiUtility.isClientThreatened,
			isAlive = isAlive,
			behavior = behavior,
			activity = activity,
			skill = self.ai.states.engage.skill,
			map = map,
			callout = callout,
			health = health,
			lastKeepAliveAt = Time.getUnixTimestamp()
		}

		writefile(string.format(self.infoPath, Panorama.MyPersonaAPI.GetXuid()), json.stringify(info))

		for _, client in pairs(self.manifest.clients) do repeat
			local info = readfile(string.format(self.infoPath, client.steamId64))

			if not info then
				break
			end

			pcall(function()
				local json = json.parse(info)

				client.info = json
			end)
		until true end
	end

	-- Allow input outside of games.
	if not Server.isIngame() then
		Client.setInput(true)

		return
	end

	-- Check if we're tabbed into the client.
	local isAppFocused = Process.isAppFocused()

	-- The hot-swap key was pressed.
	if self.keyHotSwap:wasPressed() and isAppFocused then
		local cameraAngles = Client.getCameraAngles()

		-- Prevent the AI camera from snapping between the human and the AI.
		-- This will force the AI's camera angles to match the possessed angles.
		self.ai.view.viewAngles = cameraAngles
		self.ai.view.lookAtAngles = cameraAngles
		self.ai.view.lastCameraAngles = cameraAngles

		-- Deactivate this client.
		-- Will put the current client into AI-mode.
		-- If we're holding the suppress key, then we don't enable the AI on the client we're leaving.
		-- This allows us to tab out of an account, but leaving the account "AFK" instead of running the AI on it.
		if not self.keySuppressAiEnable:isHeld() then
			self.isActive = false

			self.isSuppressed = true
		else
			self.isSuppressed = false
		end

		-- Current client ID.
		local originalIndex = self.manifest.client.index

		-- Next client. Begin with our own. If no alternative client is found, we "tab out" of the current one.
		local nextClient = self.manifest.client
		local nextIndex = originalIndex + 1
		-- Break once we find a good client to hot-swap to.
		local isValid = false
		local emergencyExit = 0

		while (nextIndex ~= originalIndex) and emergencyExit < 32 do if isValid then break end repeat
			emergencyExit = emergencyExit + 1

			local client = self.manifest.clients[nextIndex]

			-- We reached the end of the client list. Loop around.
			if not client then
				nextIndex = 1

				break
			end

			if not client.info then
				break
			end

			local isConnectionLost = (Time.getUnixTimestamp() - client.info.lastKeepAliveAt) > 3

			if isConnectionLost then
				nextIndex = nextIndex + 1

				break
			end

			-- No such client in our game. May have exited or crashed.
			if not client.info.isInGame then
				nextIndex = nextIndex + 1

				break
			end

			-- Player is dead. We'd prefer not to tab to dead bots.
			if not client.info.isAlive then
				nextIndex = nextIndex + 1

				break
			end

			nextClient = client

			isValid = true
		until true end

		if not nextClient then
			return
		end

		-- Open the next window over our current ones.
		Process.setForegroundWindow(nextClient.window)
	end

	-- AI should keep running until we press the take-control key.
	-- Allows us to spectate about without affecting any bots we don't want to.
	if self.keyTakeControl:wasPressed() then
		self.isActive = true
	end

	if isAppFocused ~= self.lastFocusedState then
		self.lastFocusedState = isAppFocused

		-- Toggle g_bTextMode. Text Mode disables rendering in the Source engine.
		Client.setTextMode(not isAppFocused)

		if isAppFocused then
			Client.execute("volume 0.5")

			cvar.m_rawinput:set_int(1)

			-- We can't hot-swap when the console is open, so ensure it's always closed when tabbing in.
			Client.closeConsole()
		else
			self.isActive = false

			Client.execute("volume 0")

			cvar.m_rawinput:set_int(1)
		end
	end

	if self.isActive ~= self.lastActiveState then
		self.lastActiveState = self.isActive

		-- Set all the appropriate settings when activating or deactivating clients.
		if self.isActive then
			if self.isAiEnabled then
				DominionMenu.enableAi:set(false)
				DominionMenu.limitFps:set(false)
				DominionMenu.disableHud:set(false)
				DominionMenu.enableAutoBuy:set(false)
				DominionMenu.standaloneQuickStopRef:set(false)
			end

			-- Ensure input is turned on or off when tabbing, so we cannot accidentally press keys in spectator mode.
			Client.setInput(true)

			DominionMenu.visualisePathfinding:set(false)
		else
			Client.setInput(false)

			if self.isAiEnabled then
				DominionMenu.enableAi:set(true)
				DominionMenu.limitFps:set(true)
				DominionMenu.enableAutoBuy:set(true)
				DominionMenu.enableView:set(true)
				DominionMenu.enableAimbot:set(true)
			end

			DominionMenu.visualisePathfinding:set(true)
			DominionMenu.visualiseAimbot:set(true)
		end
	end

	-- Handle rendering and console.
	if not self.isActive then
		-- We want to be able to use the console even if input is disabled.
		if self.keyOpenConsole:wasPressed() then
			Client.openConsole()
		end

		-- Enable input if the console has been opened.
		Client.setInput(Client.isConsoleOpen())

		local screenCenter = Client.getScreenDimensionsCenter()
		--- @type Color
		local color
		local text
		local player = Player.getClient()

		if player:isAlive() then
			color = Color:rgba(255, 255, 255, 100)
			text = "Press F to take control"
		else
			color = Color:rgba(255, 255, 255, 255)
			text = "Player is dead"
		end

		-- Hint or dead notice.
		screenCenter:offset(0, 60):drawSurfaceText(
			Font.LARGE, color, "c",
			text
		)

		screenCenter:offset(0, 10)

		-- Client name.
		screenCenter:offset(0, 30):drawSurfaceText(
			Font.LARGE_BOLD, color, "c",
			Panorama.MyPersonaAPI.GetName()
		)

		screenCenter:offset(0, 15)

		-- Client has admin permissions on Dominion.
		if self.isClientAdmin then
			screenCenter:offset(0, 20):drawSurfaceText(
				Font.MEDIUM, Color:hsla(200, 0.8, 0.6, 200), "c",
				"Administrator"
			)
		end

		-- AI is disabled notice.
		if not self.isAiEnabled then
			screenCenter:offset(0, 20):drawSurfaceText(
				Font.MEDIUM, Color:hsla(0, 0.8, 0.6, 200), "c",
				"AI Disabled"
			)
		end
	end
end

--- @param name string
--- @return void
function Reaper:setConfig(name)
	config.load(name)

	Client.execute("exec %s", self.gameConfig)
end

return Nyx.class("Reaper", Reaper)
--}}}
