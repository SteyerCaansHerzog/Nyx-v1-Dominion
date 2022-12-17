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
local SecondOrderDynamics = require "gamesense/Nyx/v1/Api/SecondOrderDynamics"
local Server = require "gamesense/Nyx/v1/Api/Server"
local VKey = require "gamesense/Nyx/v1/Api/VKey"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Voice = require "gamesense/Nyx/v1/Api/Voice"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiProcessBase = require "gamesense/Nyx/v1/Dominion/Ai/Process/AiProcessBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ Definitions
--- @class AiClientInfo
--- @field activity string
--- @field behavior string
--- @field isEnabled boolean
--- @field isOk boolean
--- @field lastUpdateAt number
--- @field priority number
--- @field renderables AiClientInfoRenderable[]
--- @field steamid64 string
--- @field threatLevel number
--- @field userdata string[]
--- @field currentTarget number
--- @field pathGoal Vector3
--- @field errors string[]
--- @field warnings string[]
--- @field task string

--- @class AiClientInfoRenderable
--- @field color Color
--- @field isOutlined boolean
--- @field origin Vector3
--- @field radius number
--- @field thickness number
--}}}

--{{{ AiProcessInfo
--- @class AiProcessInfo : AiProcessBase
--- @field isAiEnabled boolean
--- @field isLoggingEnabled boolean
--- @field syncInfoTimer Timer
--- @field infoPath string
--- @field userdata string[]
--- @field renderables AiClientInfoRenderable[]
--- @field cachedInfo AiClientInfo[]
--- @field animations SecondOrderDynamics[]
--- @field errorsCache table<number, string[]>
--- @field warningCache table<number, string[]>
local AiProcessInfo = {
	infoPath = Config.getPath("Resource/Data/AiClientInfo_%s.json")
}

--- @param fields AiProcessInfo
--- @return AiProcessInfo
function AiProcessInfo:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiProcessInfo:__init()
	self.isAiEnabled = true
	self.isLoggingEnabled = false -- todo false
	self.syncInfoTimer = Timer:new():startThenElapse()
	self.userdata = {}
	self.renderables = {}
	self.cachedInfo = {}
	self.errorsCache = {}
	self.warningCache = {}

	self.animations = Table.populateForMaxPlayers(function(eid)
		return SecondOrderDynamics:new(0.178, 0.45, 0, 0.12, Vector3, Player:new(eid):getOrigin())
	end)

	Callbacks.frame(function()
		if not Config.isAdministrator(LocalPlayer:getSteamId64()) then
			return
		end

		self:render()
	end)

	Callbacks.runCommand(function()
		self:think()
	end)
end

--- @param data string
--- @return void
function AiProcessInfo:addInfo(data)
	table.insert(self.userdata, data)
end

--- @param renderable AiClientInfoRenderable
--- @return void
function AiProcessInfo:addRenderable(renderable)
	renderable = self:getSerializedRenderable(renderable)

	table.insert(self.renderables, renderable)
end

--- @return void
function AiProcessInfo:render()
	if MenuGroup.visualiseOtherAiMode:get() == "Spectator" then
		self:renderSpectator()
		self:renderGrenades()
	elseif MenuGroup.visualiseOtherAiMode:get() == "Competitive" then
		self:renderCompetitive()
	end
end

--- @return void
function AiProcessInfo:renderSpectator()
	local threatLevelColors = {
		[0] = ColorList.BACKGROUND_1,
		[1] = Color:rgba(95, 40, 40, 255),
		[2] = Color:rgba(95, 40, 40, 255),
	}

	--- @type Vector3[]
	local origins = {}

	for _, player in pairs(Player.get()) do
		origins[player.eid] = player:getOrigin():clone():offset(0, 0, -6)
	end

	local stacks = {}
	local cameraOrigin = LocalPlayer.getCameraOrigin()

	for idA, originA in Table.sortedPairs(origins, function(a, b)
		return cameraOrigin:getDistance(a) > cameraOrigin:getDistance(b)
	end) do
		local originA2 = originA:getVector2()

		if originA2 then
			local closestId
			local closestDistance = math.huge

			for idB, originB in pairs(origins) do
				local originB2 = originB:getVector2()

				if originB2 and idA ~= idB then
					local delta = originA2:getMaxDiff(originB2)

					if not stacks[idB] and delta < closestDistance then
						closestId = idB
						closestDistance = delta
					end
				end

				if closestId then
					stacks[idA] = Math.getClampedFloat(closestDistance, 160, 25, 160)
				end
			end
		end
	end

	for _, player in Table.sortedPairs(Player.get(), function(a, b)
		return cameraOrigin:getDistance(a:getOrigin()) > cameraOrigin:getDistance(b:getOrigin())
	end) do repeat
		if not player:isAlive() then
			break
		end

		local filedata = readfile(string.format(self.infoPath, player:getSteamId64()))

		if not filedata and not self.cachedInfo[player.eid] then
			break
		end

		--- @type AiClientInfo
		local info

		pcall(function()
			local data = json.parse(filedata)

			info = data
		end)

		if not info then
			info = self.cachedInfo[player.eid]

			if not info then
				break
			end
		end

		if not info.isOk then
			break
		end

		self.cachedInfo[player.eid] = info

		-- SteamIDs don't match. Player isn't in server.
		if player:getSteamId64() ~= info.steamid64 then
			break
		end

		for _, renderable in pairs(info.renderables) do
			renderable = self:getDeserializedRenderable(renderable)

			renderable.origin:drawScaledCircle(renderable.radius, renderable.color)
		end

		local playerOrigin = origins[player.eid]
		local playerOriginAnimated = self.animations[player.eid]:think(playerOrigin)

		--- @type Vector2
		local drawPosBottom = playerOrigin:getVector2()
		--- @type Vector2
		local drawPosBottomAnimated = playerOriginAnimated:getVector2()

		if not drawPosBottom or not drawPosBottomAnimated then
			break
		end

		drawPosBottomAnimated:offset(8, 8)

		local colorBase = player:isTerrorist() and ColorList.TERRORIST or ColorList.COUNTER_TERRORIST
		local colorTeam = colorBase:clone()
		local colorMuted = ColorList.FONT_MUTED:clone()
		local colorNormal = ColorList.FONT_NORMAL:clone()
		local colorName = colorBase:clone()
		local colorError = ColorList.ERROR:clone()
		local colorBg = threatLevelColors[info.threatLevel]
		local alphaModStack = 1

		if stacks[player.eid] then
			alphaModStack = stacks[player.eid]
		end

		colorTeam.a = alphaModStack * 255
		colorMuted.a = colorTeam.a * 0.25
		colorNormal.a = colorTeam.a
		colorName.a = colorTeam.a

		drawPosBottom:drawCircle(2, colorMuted)
		drawPosBottom:drawLine(drawPosBottomAnimated, colorMuted)

		drawPosBottomAnimated:clone():offset(-2):drawSurfaceRectangle(Vector2:new(2, 35), colorTeam)
		drawPosBottomAnimated:offset(4)
		drawPosBottomAnimated:clone():offset(-4):drawSurfaceRectangleGradient(
			Vector2:new(150, 35),
			colorBg:clone():setAlpha(math.min(colorTeam.a, 255)),
			colorBg:clone():setAlpha(0),
			"h"
		)

		drawPosBottomAnimated:offset(4)

		-- Client has stopped updating.
		if Time.getUnixTimestamp() - info.lastUpdateAt > 5 then
			drawPosBottomAnimated:offset(0, 0):drawSurfaceText(Font.TINY, colorError, "l", player:getName())
			drawPosBottomAnimated:offset(0, 12):drawSurfaceText(Font.SMALL, colorError, "l", "Lost connection to client")
		else
			local isBombCarrier = AiUtility.bombCarrier and AiUtility.bombCarrier:is(player)

			if isBombCarrier then
				self:drawBombIcon(drawPosBottomAnimated:clone():offset(0, 7), colorTeam.a)

				drawPosBottomAnimated:offset(24)
			end

			drawPosBottomAnimated:offset(0, 0):drawSurfaceText(Font.TINY, colorName, "l", string.format("[%i] %s", info.priority, info.behavior))
			drawPosBottomAnimated:offset(0, 12):drawSurfaceText(Font.SMALL, colorNormal, "l", info.activity)
		end

		drawPosBottomAnimated:offset(0, 22)

		for i, item in pairs(info.userdata) do
			drawPosBottomAnimated:drawSurfaceText(Font.TINY, colorNormal, "l", item)
			drawPosBottomAnimated:offset(0, i * 12)
		end

		-- Render current target.
		if info.currentTarget then
			local target = Player:new(info.currentTarget)
			local offset = Vector3:new()

			if player:isCounterTerrorist() then
				offset:offset(0, 0, 4)
			end

			local fromOrigin = player:getOrigin() + offset
			local toOrigin = target:getOrigin() + offset

			fromOrigin:drawLine(toOrigin, colorTeam, 0.5)
			toOrigin:drawCircle3D(32, colorTeam, 1, 4)
		end

		if info.pathGoal then
			local fromOrigin = player:getOrigin()
			local toOrigin = Vector3:newFromTable(info.pathGoal):offset(0, 0, -18)
			local toOrigin2d = toOrigin:getVector2()

			fromOrigin:drawLine(toOrigin, ColorList.FONT_NORMAL, 0.5)
			toOrigin:drawCircle3D(8, ColorList.FONT_NORMAL, 1, 2)

			if toOrigin2d then
				toOrigin2d:drawSurfaceText(Font.TINY, colorTeam, "c", player:getName())
				toOrigin2d:offset(0, 12):drawSurfaceText(Font.TINY_BOLD, ColorList.FONT_NORMAL, "c", info.task)
			end
		end
	until true end
end

--- @return void
function AiProcessInfo:renderCompetitive()
	--- @type Vector3[]
	local origins = {}

	for _, player in pairs(AiUtility.teammates) do
		origins[player.eid] = player:getOrigin():clone():offset(0, 0, -6)
	end

	local stacks = {}
	local cameraOrigin = LocalPlayer.getCameraOrigin()

	for idA, originA in Table.sortedPairs(origins, function(a, b)
		return cameraOrigin:getDistance(a) > cameraOrigin:getDistance(b)
	end) do
		local originA2 = originA:getVector2()

		if originA2 then
			local closestId
			local closestDistance = math.huge

			for idB, originB in pairs(origins) do
				local originB2 = originB:getVector2()

				if originB2 and idA ~= idB then
					local delta = originA2:getMaxDiff(originB2)

					if not stacks[idB] and delta < closestDistance then
						closestId = idB
						closestDistance = delta
					end
				end

				if closestId then
					stacks[idA] = Math.getClampedFloat(closestDistance, 160, 25, 160)
				end
			end
		end
	end

	local cameraAngles = LocalPlayer.getCameraAngles()

	for _, player in Table.sortedPairs(AiUtility.teammates, function(a, b)
		return cameraOrigin:getDistance(a:getOrigin()) > cameraOrigin:getDistance(b:getOrigin())
	end) do repeat
		if not player:isAlive() then
			break
		end

		local filedata = readfile(string.format(self.infoPath, player:getSteamId64()))

		if not filedata and not self.cachedInfo[player.eid] then
			break
		end

		--- @type AiClientInfo
		local info

		pcall(function()
			local data = json.parse(filedata)

			info = data
		end)

		if not info then
			info = self.cachedInfo[player.eid]

			if not info then
				break
			end
		end

		if not info.isOk then
			break
		end

		self.cachedInfo[player.eid] = info

		-- SteamIDs don't match. Player isn't in server.
		if player:getSteamId64() ~= info.steamid64 then
			break
		end

		for _, renderable in pairs(info.renderables) do
			renderable = self:getDeserializedRenderable(renderable)

			renderable.origin:drawScaledCircle(renderable.radius, renderable.color)
		end

		local playerOrigin = origins[player.eid]
		local playerOriginAnimated = self.animations[player.eid]:think(playerOrigin)

		local playerFoVOrigin = player:getOrigin():clone():offset(0, 0, 46)
		local clientOrigin = LocalPlayer:getOrigin()
		--- @type Vector2
		local drawPosBottom = playerOrigin:getVector2()
		--- @type Vector2
		local drawPosBottomAnimated = playerOriginAnimated:getVector2()

		if not drawPosBottom or not drawPosBottomAnimated then
			break
		end

		drawPosBottomAnimated:offset(8, 8)

		local colorBase = Color:hexa(Panorama.GameStateAPI.GetPlayerColor(player:getSteamId64()))
		local colorTeam = colorBase:clone()
		local colorMuted = ColorList.FONT_MUTED:clone()
		local colorNormal = ColorList.FONT_NORMAL:clone()
		local colorName = ColorList.FONT_NORMAL:clone():darken(0.15)
		local colorError = ColorList.ERROR:clone()
		local colorBg = ColorList.BACKGROUND_1
		local alphaModDistance = Math.getClamped(Math.getInversedFloat(clientOrigin:getDistance(playerFoVOrigin), Math.getClamped(2500, 1500, 2500)), 0, 1)
		local alphaModFovOuter = Math.getClamped(Math.getInversedFloat(cameraAngles:getFov(cameraOrigin, playerFoVOrigin), 60), 0.25, 1)
		local alphaModFovInner = Math.getClamped(Math.getFloat(Client.getScreenDimensionsCenter():getMaxDiff(drawPosBottomAnimated:clone():offset(60, 22)) - 20, 225), 0, 1)
		local alphaModStack = 1

		if stacks[player.eid] then
			alphaModStack = stacks[player.eid]
		end

		colorTeam.a = math.min(alphaModDistance, alphaModFovOuter, alphaModFovInner, alphaModStack) * 255
		colorMuted.a = colorTeam.a * 0.25
		colorNormal.a = colorTeam.a
		colorName.a = colorTeam.a
		colorError.a = colorTeam.a

		drawPosBottom:drawCircle(2, colorMuted)
		drawPosBottom:drawLine(drawPosBottomAnimated, colorMuted)

		drawPosBottomAnimated:clone():offset(-2):drawSurfaceRectangle(Vector2:new(2, 35), colorTeam)
		drawPosBottomAnimated:offset(4)
		drawPosBottomAnimated:clone():offset(-4):drawSurfaceRectangleGradient(
			Vector2:new(150, 35),
			colorBg:clone():setAlpha(math.min(colorTeam.a, 255)),
			colorBg:clone():setAlpha(0),
			"h"
		)

		drawPosBottomAnimated:offset(4)

		-- Client has stopped updating.
		if Time.getUnixTimestamp() - info.lastUpdateAt > 5 then
			drawPosBottomAnimated:offset(0, 0):drawSurfaceText(Font.TINY, colorError, "l", player:getName())
			drawPosBottomAnimated:offset(0, 12):drawSurfaceText(Font.SMALL, colorError, "l", "Lost connection to client")
		else
			local isBombCarrier = AiUtility.bombCarrier and AiUtility.bombCarrier:is(player)

			if isBombCarrier then
				self:drawBombIcon(drawPosBottomAnimated:clone():offset(0, 7), colorTeam.a)

				drawPosBottomAnimated:offset(24)
			end

			drawPosBottomAnimated:offset(0, 0):drawSurfaceText(Font.TINY, colorName, "l", player:getName())
			drawPosBottomAnimated:offset(0, 12):drawSurfaceText(Font.SMALL, colorNormal, "l", info.activity)
		end
	until true end
end

--- @return nil
function AiProcessInfo:renderGrenades()
	local names = {
		CFlashbangProjectile = "Flashbang",
		CBaseCSGrenadeProjectile = "HE Grenade",
		CMolotovProjectile = "Molotov",
		CSmokeGrenadeProjectile = "Smoke",
	}

	local colors = {
		CFlashbangProjectile = Color:hsla(200, 0.8, 0.8),
		CBaseCSGrenadeProjectile = Color:hsla(10, 0.8, 0.6),
		CMolotovProjectile = Color:hsla(25, 0.8, 0.6),
		CSmokeGrenadeProjectile = Color:hsla(0, 0, 0.8),
	}

	for _, grenade in Entity.find({
		Weapons.SMOKE_PROJECTILE,
		Weapons.GRENADE_PROJECTILE,
		Weapons.MOLOTOV_PROJECTILE
	}) do repeat
		-- Grenade entities are NODRAW on explode. Because reasons.
		-- Luckily we can check when the explode FX begins and use that to not draw the ESP.
		if grenade:m_nExplodeEffectTickBegin() ~= 0 then
			break
		end

		-- CS:GO is fucking stupid.
		-- HE and Flashbangs are the same thing.
		-- But one has 99 damage and the other has 100 and it's not the HE grenade.
		if grenade.classname == Weapons.GRENADE_PROJECTILE and grenade:m_flDamage() == 100 then
			grenade.classname = "CFlashbangProjectile"
		end

		local origin = grenade:m_vecOrigin()
		local predictedOrigin = origin + grenade:m_vecVelocity() * 0.5
		local color = colors[grenade.classname]
		local trajectoryColor = color:clone():setAlpha(100)

		origin:drawScaledCircleOutline(30, 10, color)
		origin:drawSurfaceText(Font.TINY, color, "c", names[grenade.classname])
		origin:drawLine(predictedOrigin, trajectoryColor, 0.5)
	until true end
end

--- @return void
function AiProcessInfo:think()
	if not self.isLoggingEnabled then
		return
	end

	local activity
	local behavior
	local priority
	local threatLevel = 0
	local currentTarget
	local errors = {}
	local warnings = {}
	local pathGoal
	local task

	if Server.isIngame() then
		if self.ai.currentState then
			activity = self.ai.currentState.activity
			behavior = self.ai.currentState.name
			priority = self.ai.lastPriority

			if AiUtility.isClientThreatenedMajor then
				threatLevel = 2
			elseif AiUtility.isClientThreatenedMinor then
				threatLevel = 1
			end

			if self.ai.currentState.name == "Engage" and self.ai.states.engage.bestTarget then
				currentTarget = self.ai.states.engage.bestTarget.eid
			end
		end

		if not Table.isEmpty(Logger.errorsCache) then
			errors = Logger.errorsCache
		end

		if not Table.isEmpty(Logger.warningsCache) then
			warnings = Logger.warningsCache
		end

		if Pathfinder.path and Pathfinder.path.endGoal then
			pathGoal = {
				x = Pathfinder.path.endGoal.origin.x,
				y = Pathfinder.path.endGoal.origin.y,
				z = Pathfinder.path.endGoal.origin.z
			}

			task = Pathfinder.path.task
		end
	end

	local steamid = LocalPlayer:getSteamId64()

	--- @type AiClientInfo
	local info = {
		isEnabled = self.isAiEnabled,
		isOk = priority ~= nil,
		activity = activity,
		behavior = behavior,
		priority = priority,
		threatLevel = threatLevel,
		userdata = self.userdata,
		renderables = self.renderables,
		steamid64 = steamid,
		lastUpdateAt = Time.getUnixTimestamp(),
		currentTarget = currentTarget,
		errors = errors,
		warnings = warnings,
		pathGoal = pathGoal,
		task = task
	}

	writefile(string.format(self.infoPath, steamid), json.stringify(info))

	self.userdata = {}
	self.renderables = {}
end

--- @param renderable AiClientInfoRenderable
--- @return AiClientInfoRenderable
function AiProcessInfo:getSerializedRenderable(renderable)
	if not renderable.origin then
		return
	end

	--- @type AiClientInfoRenderable
	local serialized = {}

	serialized.color = {r = renderable.color.r, g = renderable.color.g, b = renderable.color.b, a = renderable.color.a}
	serialized.origin = renderable.origin:__serialize()
	serialized.isOutlined = renderable.isOutlined
	serialized.radius = renderable.radius
	serialized.thickness = renderable.thickness

	return serialized
end

--- @param serialized AiClientInfoRenderable
--- @return AiClientInfoRenderable
function AiProcessInfo:getDeserializedRenderable(serialized)
	--- @type AiClientInfoRenderable
	local deserialized = {}

	deserialized.color = Color:newFromTable(serialized.color)
	deserialized.origin = Vector3:newFromTable(serialized.origin)
	deserialized.isOutlined = serialized.isOutlined
	deserialized.radius = serialized.radius
	deserialized.thickness = serialized.thickness

	return deserialized
end

--- @param drawPos Vector2
--- @return void
function AiProcessInfo:drawBombIcon(drawPos, alpha)
	local colorBombA = Color:hsla(33, 0.0, 0.6, alpha)
	local colorBombB = Color:hsla(33, 0.0, 0.3, alpha)

	drawPos:drawSurfaceRectangle(Vector2:new(18, 22), colorBombA)

	drawPos:clone():offset(1, -3):drawSurfaceRectangle(Vector2:new(2, 3), colorBombA)
	drawPos:clone():offset(8, -3):drawSurfaceRectangle(Vector2:new(2, 3), colorBombA)
	drawPos:clone():offset(15, -3):drawSurfaceRectangle(Vector2:new(2, 3), colorBombA)
	drawPos:clone():offset(-3, 3):drawSurfaceRectangle(Vector2:new(3, 8), colorBombA)

	drawPos:offset(2, 2):drawSurfaceRectangle(Vector2:new(14, 6), colorBombB)

	drawPos:offset(0, 8):drawSurfaceRectangle(Vector2:new(4, 4), colorBombB)
	drawPos:offset(5, 0):drawSurfaceRectangle(Vector2:new(4, 4), colorBombB)
	drawPos:offset(5, 0):drawSurfaceRectangle(Vector2:new(4, 4), colorBombB)

	drawPos:offset(-10, 5):drawSurfaceRectangle(Vector2:new(4, 4), colorBombB)
	drawPos:offset(5, 0):drawSurfaceRectangle(Vector2:new(4, 4), colorBombB)
	drawPos:offset(5, 0):drawSurfaceRectangle(Vector2:new(4, 4), colorBombB)
end

return Nyx.class("AiProcessInfo", AiProcessInfo, AiProcessBase)
--}}}
