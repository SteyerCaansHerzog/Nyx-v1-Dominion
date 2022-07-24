--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Localization = require "gamesense/Nyx/v1/Api/Localization"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
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
local Voice = require "gamesense/Nyx/v1/Api/Voice"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local DominionLocalization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ Definitions
--{{{ ReaperClientInfo
--- @class ReaperClientInfo
--- @field activity string
--- @field balance number
--- @field behavior string
--- @field callout string
--- @field colorHex string
--- @field health number
--- @field isAlive boolean
--- @field isAttacked boolean
--- @field isBombCarrier boolean
--- @field isFlashed boolean
--- @field isInGame boolean
--- @field isLobbyHost boolean
--- @field isLobbyQueuing boolean
--- @field isThreatened boolean
--- @field isWarmup boolean
--- @field lastKeepAliveAt number
--- @field lobbyMemberCount number
--- @field map string
--- @field name string
--- @field phase number
--- @field priority number
--- @field skill number
--- @field team number
--}}}

--{{{ ReaperClientShared
--- @class ReaperClientShared
--- @field isForced boolean
--}}}
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
	path = Config.getPath("Resource/Data/ReaperManifest.json")
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

		error(DominionLocalization.reaperMissingManifest)

		return
	end

	self.raw = fileData

	local manifest = json.parse(fileData)

	self.isEnabled = manifest.isEnabled

	if self.isEnabled then
		Logger.console(3, DominionLocalization.reaperIsEnabled)
	elseif not self.isEnabled then
		Logger.console(3, DominionLocalization.reaperIsNotEnabled)

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

		error(Localization.aiReaperManifestMissing)

		return
	end

	self.raw = fileData

	local manifest = json.parse(fileData)
	local isReaperStale = false

	for steamId64, windowHandle in pairs(manifest.clients) do
		if not self.steamId64Map[steamId64] then
			isReaperStale = true

			Logger.console(0, Localization.reaperNewAccount)

			break
		end

		if not self.windowHandleMap[windowHandle] then
			isReaperStale = true

			Logger.console(0, Localization.reaperAccountRestarted)

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
--- @field ai Ai
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
--- @field keyForceSwap VKey
--- @field isForced boolean
--- @field syncInfoTimer Timer
--- @field infoPath string
--- @field clientBoxFocusedOffset number
--- @field clientBoxActiveOffset number
--- @field screenGradientAlpha number
--- @field screenOverlayAlpha number
--- @field savedCommunicationStates boolean[]
local Reaper = {
	gameConfig = "reaper",
	clientConfig = "Nyx-v1-Dominion-Reaper",
	infoPath = Config.getPath("Resource/Data/ReaperClientInfo_%s.json"),
	sharedPath = Config.getPath("Resource/Data/ReaperClientShared.json"),
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
	self.keyForceSwap = VKey:new(VKey.Q)
	self.syncInfoTimer = Timer:new():start()
	self.manifest = ReaperManifest:new()
	self.clientBoxFocusedOffset = 0
	self.screenGradientAlpha = 0
	self.screenOverlayAlpha = 0
	self.isForced = false

	self.isEnabled = self.manifest.isEnabled

	self.savedCommunicationStates = {
		chatbotNormal = self.ai.chatbots.normal.isEnabled,
		chatbotGpt3 = self.ai.chatbots.gpt3.isEnabled
	}

	MenuGroup.disableHud:set(false)
	MenuGroup.limitFps:set(false)
end

--- @return void
function Reaper:initEvents()
	if self.isEnabled then
		self:setConfig(self.clientConfig)

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
	-- Handle rendering and console.
	if not self.isActive then
		-- We want to be able to use the console even if input is disabled.
		if self.keyOpenConsole:wasPressed() then
			Client.openConsole()
		end

		-- Enable input if the console has been opened.
		Client.setInput(Client.isConsoleOpen())

		if Server.isIngame() then
			local screenCenter = Client.getScreenDimensionsCenter()
			--- @type Color
			local color
			local text

			if LocalPlayer:isAlive() then
				color = Color:rgba(255, 255, 255, 155)
				text = "Press F to take control"

				screenCenter:clone():offset(-62, 68):drawSurfaceRectangleOutline(1, 1, Vector2:new(16, 25), Color:rgba(255, 255, 255, 20))
				screenCenter:clone():offset(-62, 68):drawSurfaceRectangleGradient(
					Vector2:new(16, 25),
					Color:rgba(255, 255, 255, 5),
					Color:rgba(255, 255, 255, 20),
					"h"
				)
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
					Font.MEDIUM, color, "c",
					"Administrator"
				)
			end

			-- AI is disabled notice.
			if not self.isAiEnabled then
				screenCenter:offset(0, 20):drawSurfaceText(
					Font.MEDIUM, Color:hsla(0, 0.8, 0.6, 255), "c",
					"AI Disabled"
				)
			end
		else
			local screenCenter = Client.getScreenDimensionsCenter()
			--- @type Color

			-- Hint or dead notice.
			screenCenter:offset(0, 60):drawSurfaceText(
				Font.LARGE, Color:rgba(255, 255, 255, 255), "c",
				"Press F to use menu"
			)

			screenCenter:clone():offset(-51, 8):drawSurfaceRectangleOutline(1, 1, Vector2:new(16, 25), Color:rgba(255, 255, 255, 20))
			screenCenter:clone():offset(-51, 8):drawSurfaceRectangleGradient(
				Vector2:new(16, 25),
				Color:rgba(255, 255, 255, 5),
				Color:rgba(255, 255, 255, 20),
				"h"
			)
		end
	end

	-- Render tabs.
	local totalClients = Table.getCount(self.manifest.clients)
	--- @type Vector2
	local drawPosition
	local screenDims = Client.getScreenDimensions()
	local clientBoxDimensions = Vector2:new(360, 52)
	local clientBoxTopOffset = 40 - (totalClients * clientBoxDimensions.y / 2)
	local clientBoxRightOffset = -300
	local clientBoxBottomMargin = 12
	local clientBoxLeftMargin = 25
	local screenCenter = Client.getScreenDimensionsCenter()
	local alphaMod = 0.9

	-- Set draw position.
	if self.isActive then
		drawPosition = Vector2:new(clientBoxLeftMargin, screenCenter.y)
		alphaMod = 0.5

		drawPosition.x = drawPosition.x + self.clientBoxActiveOffset
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

	if self.isActive then
		self.screenGradientAlpha = Animate.slerp(self.screenGradientAlpha, 0, 1.66)
		self.screenOverlayAlpha = Animate.slerp(self.screenOverlayAlpha, 0, 2)
		self.clientBoxActiveOffset = Animate.slerp(self.clientBoxActiveOffset, 0, 10)
	else
		self.screenGradientAlpha = 255
		self.screenOverlayAlpha = 100
		self.clientBoxActiveOffset = 75
	end

	Vector2:new():drawSurfaceRectangle(screenDims, Color:hsla(0, 0, 0.15, self.screenOverlayAlpha))

	Vector2:new(0, screenDims.y - screenDims.y / 3):drawSurfaceRectangleGradient(
		Vector2:new(screenDims.x, screenDims.y / 3),
		Color:hsla(0, 0, 0.15, 0),
		Color:hsla(0, 0, 0.15, self.screenGradientAlpha),
		"v"
	)

	if self.isForced then
		drawPosition:clone():offset(0, -30):drawSurfaceText(Font.MEDIUM, ColorList.FONT_MUTED, "l", "Tab-Lock Off")
	end

	for _, client in pairs(self.manifest.clients) do repeat
		if not client.info then
			break
		end

		local player = Player.getBySteamid64(client.steamId64)
		local nameColor = ColorList.FONT_NORMAL
		local infoColor = ColorList.FONT_NORMAL
		local bgColor = ColorList.IS_FINE
		local bgAlphaMod = 1
		local isPlayerAlive = client.info.isAlive
		local isPlayerInServer = player ~= nil
		local isConnectionLost = (Time.getUnixTimestamp() - client.info.lastKeepAliveAt) > 3
		local isClientStateOkayToShow = true
		local isClient = client.steamId64 == self.manifest.client.steamId64
		local isFocused = Process.isAppFocused()
		local isMatchOver = false

		if isConnectionLost then
			bgColor = ColorList.IS_DISCONNECTED
			nameColor = ColorList.ERROR
			infoColor = ColorList.ERROR

			isClientStateOkayToShow = false
		elseif not client.info.isInGame then
			bgColor = ColorList.IS_DISCONNECTED
			nameColor = ColorList.FONT_MUTED
			infoColor = ColorList.FONT_MUTED

			isClientStateOkayToShow = false
		elseif isClient then
			nameColor = ColorList.FONT_NORMAL
			infoColor = ColorList.FONT_NORMAL

			isClientStateOkayToShow = false
		elseif isMatchOver then
			bgColor = ColorList.IS_DISCONNECTED
			nameColor = ColorList.FONT_MUTED
			infoColor = ColorList.FONT_MUTED

			isClientStateOkayToShow = false
		elseif not isPlayerInServer then
			nameColor = ColorList.FONT_MUTED
			infoColor = ColorList.FONT_MUTED
		end

		if isClientStateOkayToShow then
			if not isPlayerAlive then
				bgColor = ColorList.IS_DEAD
				nameColor = ColorList.TEXT_DEAD
				infoColor = ColorList.TEXT_DEAD
			elseif client.info.isFlashed then
				bgColor = ColorList.IS_FLASHED
				bgAlphaMod = alphaMods.IS_FLASHED
				nameColor = ColorList.FONT_NORMAL
				infoColor = ColorList.FONT_NORMAL
			elseif client.info.isAttacked then
				bgColor = ColorList.IS_ATTACKED
				bgAlphaMod = alphaMods.IS_ATTACKED
				nameColor = ColorList.TEXT_ATTACKED
				infoColor = ColorList.TEXT_ATTACKED
			elseif client.info.isThreatened then
				bgColor = ColorList.IS_THREATENED
				nameColor = ColorList.TEXT_THREATENED
				infoColor = ColorList.TEXT_THREATENED
				bgAlphaMod = alphaMods.IS_THREATENED
			end
		end

		bgColor = bgColor:clone()
		bgColor.a = bgColor.a * bgAlphaMod

		if isFocused then
			self.clientBoxFocusedOffset = Animate.slerp(self.clientBoxFocusedOffset, 12, 4)
		else
			self.clientBoxFocusedOffset = Animate.slerp(self.clientBoxFocusedOffset, 0, 4)
		end

		if self.isActive then
			self.clientBoxFocusedOffset = 0
		end

		if isClient then
			bgColor = ColorList.IS_CLIENT_BG

			drawPosition:offset(self.clientBoxFocusedOffset)
			drawPosition:drawSurfaceRectangleOutline(2, 2, clientBoxDimensions, ColorList.IS_CLIENT_OUTLINE)
		else
			--- @type Color
			local outlineColor

			if isConnectionLost then
				outlineColor = ColorList.ERROR
			elseif isPlayerInServer then
				outlineColor = ColorList.IS_IN_SERVER
			else
				outlineColor = bgColor:clone():setAlpha(50 * alphaMod)
			end

			drawPosition:drawSurfaceRectangleOutline(2, 2, clientBoxDimensions, outlineColor)
		end

		drawPosition:drawBlur(clientBoxDimensions)
		drawPosition:drawSurfaceRectangle(clientBoxDimensions, bgColor)

		local nameOffset = 0

		-- Player color circle.
		if isPlayerInServer and client.info.colorHex then
			local color = Color:hexa(client.info.colorHex)

			drawPosition:clone():offset(12, 16):drawCircle(8, Color:hsla(0, 0, 0.2)):drawCircleOutline(6, 3, color)

			nameOffset = 20
		end

		drawPosition:clone():offset(5 + nameOffset, 0):drawSurfaceText(Font.MEDIUM_LARGE, nameColor, "l", client.info.name)

		-- No connection to the client.
		if isConnectionLost then
			drawPosition:clone():offset(5, 28):drawSurfaceText(Font.SMALL, infoColor, "l", "Lost connection to client")
			drawPosition:offset(0, clientBoxDimensions.y + clientBoxBottomMargin)

			break
		end

		-- Match is over.
		if isMatchOver then
			drawPosition:clone():offset(5, 28):drawSurfaceText(Font.SMALL, infoColor, "l", "Match ended")
			drawPosition:offset(0, clientBoxDimensions.y + clientBoxBottomMargin)

			break
		end

		-- Player state.
		if client.info.isInGame then
			-- In-game state.
			if client.info.isWarmup then
				drawPosition:clone():offset(5, 28):drawSurfaceText(Font.SMALL, infoColor, "l", "Idling in warmup")
			elseif isPlayerAlive then
				drawPosition:clone():offset(5, 28):drawSurfaceText(Font.SMALL, infoColor, "l", client.info.activity)
			else
				drawPosition:clone():offset(5, 28):drawSurfaceText(Font.SMALL, infoColor, "l", "Dead")
			end
		else
			-- Lobby state.
			local isInLobby = false
			local playerCount

			if Panorama.LobbyAPI.IsSessionActive() then
				local lobbyInfo = json.parse(tostring(Panorama.LobbyAPI.GetSessionSettings()))
				playerCount = lobbyInfo.members.numPlayers

				if playerCount > 1 then
					isInLobby = true
				end
			end

			if client.info.lobbyMemberCount then
				local lobbyText

				if client.info.isLobbyQueuing then
					lobbyText = string.format(
						"Queuing with %i people",
						client.info.lobbyMemberCount
					)
				else
					lobbyText = string.format(
						"In a lobby with %i people",
						client.info.lobbyMemberCount
					)
				end

				drawPosition:clone():offset(5, 28):drawSurfaceText(Font.SMALL, infoColor, "l", lobbyText)

				if client.info.lobbyMemberCount > 1 and client.info.isLobbyHost then
					drawPosition:clone():offset(clientBoxDimensions.x - 5, 25):drawSurfaceText(Font.SMALL, infoColor, "r", "Host")
				end
			else
				drawPosition:clone():offset(5, 28):drawSurfaceText(Font.SMALL, infoColor, "l", "In the main menu")
			end
		end

		local skillHueAdd = Math.getFloat(client.info.skill, 10) * 140
		local skillColor = Color:hsla(215 + skillHueAdd, 0.7, 0.8)

		-- Skill level.
		drawPosition:clone():offset(clientBoxDimensions.x - 14):drawSurfaceText(Font.SMALL_BOLD, skillColor, "c", client.info.skill)
		drawPosition:clone():offset(clientBoxDimensions.x - 21, 6):drawSurfaceRectangleOutline(1, 4, Vector2:new(15, 10), skillColor:clone():setAlpha(33 * alphaMod))
		drawPosition:clone():offset(clientBoxDimensions.x - 25, 2):drawSurfaceRectangleGradient(
			Vector2:new(24, 18),
			skillColor:clone():setAlpha(8 * alphaMod),
			skillColor:clone():setAlpha(48 * alphaMod),
			"h"
		)

		-- Set team color.
		local teamColor
		local teamName

		if client.info.team == 2 then
			teamColor = ColorList.TERRORIST
			teamName = "T"
		elseif client.info.team == 3 then
			teamColor = ColorList.COUNTER_TERRORIST
			teamName = "CT"
		else
			teamColor = ColorList.FONT_MUTED
			teamName = "-"
		end

		-- Team.
		if client.info.team then
			drawPosition:clone():offset(clientBoxDimensions.x - 14 - 28):drawSurfaceText(Font.SMALL_BOLD, teamColor, "c", teamName)
			drawPosition:clone():offset(clientBoxDimensions.x - 21 - 28, 6):drawSurfaceRectangleOutline(1, 4, Vector2:new(15, 10), teamColor:clone():setAlpha(33 * alphaMod))
			drawPosition:clone():offset(clientBoxDimensions.x - 21 - 32, 2):drawSurfaceRectangleGradient(
				Vector2:new(24, 18),
				teamColor:clone():setAlpha(8 * alphaMod),
				teamColor:clone():setAlpha(48 * alphaMod),
				"h"
			)
		end

		if isPlayerAlive then
			if client.info.health then
				local healthPct

				if client.info.health < 20 then
					healthPct = 0
				else
					healthPct = Math.getClampedFloat(client.info.health, 100, 0, 180)
				end

				local healthColor = Color:hsla(100 * healthPct, 0.8, 0.6, 255 * alphaMod)

				-- Health.
				drawPosition:clone():offset(clientBoxDimensions.x - 19 - 56):drawSurfaceText(Font.SMALL_BOLD, healthColor, "c", client.info.health)
				drawPosition:clone():offset(clientBoxDimensions.x - 31 - 56, 6):drawSurfaceRectangleOutline(1, 4, Vector2:new(25, 10), healthColor:clone():setAlpha(33 * alphaMod))
				drawPosition:clone():offset(clientBoxDimensions.x - 35 - 56, 2):drawSurfaceRectangleGradient(
					Vector2:new(33, 18),
					healthColor:clone():setAlpha(8 * alphaMod),
					healthColor:clone():setAlpha(48 * alphaMod),
					"h"
				)

				-- C4.
				if client.info.isBombCarrier then
					drawPosition:clone():offset(clientBoxDimensions.x - 14 - 94):drawSurfaceText(Font.SMALL_BOLD, teamColor, "c", "C4")
					drawPosition:clone():offset(clientBoxDimensions.x - 21 - 94, 6):drawSurfaceRectangleOutline(1, 4, Vector2:new(15, 10), teamColor:clone():setAlpha(33 * alphaMod))
					drawPosition:clone():offset(clientBoxDimensions.x - 21 - 98, 2):drawSurfaceRectangleGradient(
						Vector2:new(24, 18),
						teamColor:clone():setAlpha(8 * alphaMod),
						teamColor:clone():setAlpha(48 * alphaMod),
						"h"
					)
				end
			end

			if client.info.map then
				local text

				if isPlayerInServer then
					if AiUtility.gameRules:m_bFreezePeriod() == 1 then
						text = string.format("$%i balance", client.info.balance)
					else
						text = client.info.callout
					end
				else
					text = "In another match"
				end

				drawPosition:clone():offset(clientBoxDimensions.x - 5, 25):drawSurfaceText(Font.SMALL, infoColor, "r", text)
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
	local isAppFocused = Process.isAppFocused()
	local isInGame = Server.isIngame()

	if self.syncInfoTimer:isElapsedThenRestart(0.05) then
		local behavior = "Inactive"
		local activity = "Inactive"

		if MenuGroup.enableAi:get() and self.ai.currentState then
			behavior = self.ai.currentState.name
			activity = self.ai.currentState.activity or "Unknown"
		end

		if self.isActive then
			activity = "Possessed"
		end

		local balance
		local callout
		local health
		local isAlive = false
		local isWarmup = false
		local map
		local phase
		local team
		local isBombCarrier

		if Server.isIngame() then
			balance = LocalPlayer:m_iAccount()
			callout = Localization.get(LocalPlayer:m_szLastPlaceName())
			health = LocalPlayer:m_iHealth()
			isAlive = LocalPlayer:isAlive()
			isWarmup = Entity.getGameRules():m_bWarmupPeriod() == 1
			map = globals.mapname()
			team = LocalPlayer:m_iTeamNum()
			isBombCarrier = AiUtility.bombCarrier and AiUtility.bombCarrier:isClient()

			if AiUtility.timeData then
				phase = AiUtility.timeData.gamephase
			end
		end

		local lobbyMemberCount
		local isLobbyHost
		local isLobbyQueuing

		if Panorama.LobbyAPI.IsSessionActive() then
			local lobbyInfo = json.parse(tostring(Panorama.LobbyAPI.GetSessionSettings()))
			local numPlayers = lobbyInfo.members.numPlayers

			if numPlayers > 1 then
				lobbyMemberCount = numPlayers
			end

			isLobbyHost = Panorama.LobbyAPI.BIsHost()
			isLobbyQueuing = Panorama.LobbyAPI.GetMatchmakingStatusString() ~= ""
		end

		local teamColorIndicator = Panorama.GameStateAPI.GetPlayerColor(Panorama.MyPersonaAPI.GetXuid())

		--- @type ReaperClientInfo
		local info = {
			activity = activity,
			balance = balance,
			behavior = behavior,
			callout = callout,
			colorHex = teamColorIndicator,
			health = health,
			isAlive = isAlive,
			isAttacked = AiUtility.isEnemyVisible,
			isBombCarrier = isBombCarrier,
			isFlashed = LocalPlayer.isFlashed(),
			isInGame = Server.isIngame(),
			isLobbyHost = isLobbyHost,
			isLobbyQueuing = isLobbyQueuing,
			isThreatened = AiUtility.isClientThreatenedMinor,
			isWarmup = isWarmup,
			lastKeepAliveAt = Time.getUnixTimestamp(),
			lobbyMemberCount = lobbyMemberCount,
			map = map,
			name = Panorama.MyPersonaAPI.GetName(),
			phase = phase,
			priority = self.ai.lastPriority,
			skill = self.ai.states.engage.skill,
			team = team,
		}

		if isAppFocused then
			--- @type ReaperClientShared
			local shared = {
				isForced = self.isForced
			}

			writefile(self.sharedPath, json.stringify(shared))
		else
			local fileData = readfile(self.sharedPath)

			if fileData then
				pcall(function()
					--- @type ReaperClientShared
					local data = json.parse(fileData)

					for k, v in pairs(data) do
						self[k] = v
					end
				end)
			end
		end

		writefile(string.format(self.infoPath, Panorama.MyPersonaAPI.GetXuid()), json.stringify(info))

		for _, client in pairs(self.manifest.clients) do repeat
			local filedata = readfile(string.format(self.infoPath, client.steamId64))

			if not filedata then
				break
			end

			pcall(function()
				local data = json.parse(filedata)

				client.info = data
			end)
		until true end
	end

	-- Allow input outside of games.
	if not isInGame then
		Client.setInput(true)
	end

	if not self.isActive and self.keyForceSwap:wasPressed() then
		self.isForced = not self.isForced
	end

	if self.isActive and isAppFocused then
		self.isForced = false
	end

	-- The hot-swap key was pressed.
	if self.keyHotSwap:wasPressed() and isAppFocused then
		local cameraAngles = Client.getCameraAngles()

		-- Prevent the AI camera from snapping between the human and the AI.
		-- This will force the AI's camera angles to match the possessed angles.
		 View.viewAngles = cameraAngles
		 View.lookAtAngles = cameraAngles
		 View.lastCameraAngles = cameraAngles

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

			if not isInGame or self.isForced then
				nextClient = client
				isValid = true

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

		if nextClient.index == originalIndex then
			self.isActive = false
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

		if isAppFocused then
			cvar.fps_max:set_int(64)
			cvar.fps_max_menu:set_int(0)
		else
			cvar.fps_max:set_int(64)
			cvar.fps_max_menu:set_int(15)
		end

		-- Toggle g_bTextMode. Text Mode disables rendering in the Source engine.
		if Config.isTextModeAllowed then
			Client.setTextMode(not isAppFocused)
		end

		if isAppFocused then
			Client.execute("volume %.2f", Config.clientFocusVolume)

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

		-- Toggle communication states.
		if self.isActive then
			cvar.fps_max:set_int(0)

			self.savedCommunicationStates = {
				chatbotNormal = self.ai.chatbots.normal.isEnabled,
				chatbotGpt3 = self.ai.chatbots.gpt3.isEnabled
			}

			self.ai.chatbots.normal.isEnabled = false
			self.ai.chatbots.gpt3.isEnabled = false
		else
			self.ai.chatbots.normal.isEnabled = self.savedCommunicationStates.chatbotNormal
			self.ai.chatbots.gpt3.isEnabled = self.savedCommunicationStates.chatbotGpt3
		end

		Voice.isEnabled = not self.isActive

		-- Set all the appropriate settings when activating or deactivating clients.
		if self.isActive then
			AiUtility.isPerformingCalculations = false

			if self.isAiEnabled then
				MenuGroup.enableAi:set(false)
				MenuGroup.limitFps:set(false)
				MenuGroup.disableHud:set(false)
				MenuGroup.enableAutoBuy:set(false)
				MenuGroup.standaloneQuickStopRef:set(false)
			end

			Client.setInput(true)

			MenuGroup.visualiseAimbot:set(false)
		else
			AiUtility.isPerformingCalculations = true

			if self.isAiEnabled then
				MenuGroup.enableAi:set(true)
				MenuGroup.limitFps:set(true)
				MenuGroup.enableAutoBuy:set(true)
				MenuGroup.enableMouseControl:set(true)
				MenuGroup.enableAimbot:set(true)
			end

			MenuGroup.visualiseAimbot:set(true)

			-- Ensure input is turned on or off when tabbing, so we cannot accidentally press keys in spectator mode.
			Client.setInput(false)
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
