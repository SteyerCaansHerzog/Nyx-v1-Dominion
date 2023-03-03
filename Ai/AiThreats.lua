--{{{ Dependencies
local Benchmark = require "gamesense/Nyx/v1/Api/Benchmark"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local NodeType = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeType"
--}}}

--{{{ Definitions
--- @class ThreatLevel
local ThreatLevel = {
	NONE = 0, -- No threats.
	LOW = 1, -- Threats far away.
	MEDIUM = 2, -- Threats able to peek within 10-15 seconds.
	HIGH = 3, -- Threats able to peek us within 5-10 seconds.
	EXTREME = 4, -- Threats are able to peek us within 1-4 seconds, or are visible.
}
--}}}

--{{{ AiThreats
--- @class AiThreats : Class
--- @field cacheRefreshRequired boolean[]
--- @field clientVisgraph NodeTypeTraverse[]
--- @field clientVisgraphOrigin Vector3
--- @field closestVisibleEnemyNodes NodeTypeTraverse[]
--- @field determineThreatIndex number
--- @field crosshairPlacements Vector3[]
--- @field crosshairPlacementsIdeal Vector3[]
--- @field enemyThreatLevels number[]
--- @field enemyVisgraphOrigins Vector3[]
--- @field enemyVisgraphs table<number, NodeTypeTraverse[]>
--- @field highestThreat Player
--- @field highestThreatOrigin Vector3
--- @field lastClosestVisibleEnemyNodes NodeTypeTraverse[]
--- @field lastUpdatedThreatTimers Timer[]
--- @field processEnemyIndex number
--- @field threatCount number
--- @field threatDetectionTimer Timer
--- @field threatLevel number
--- @field threatLevels ThreatLevel
--- @field threats Player[]
--- @field threatVisgraph NodeTypeTraverse[]
--- @field totalThreats number
--- @field visibleEnemyNodes table<number, NodeTypeTraverse[]>
local AiThreats = {
	threatLevels = ThreatLevel
}

--- @return void
function AiThreats:__setup()
	Callbacks.init(function()
		AiThreats.reset()
	end)

	Callbacks.roundPrestart(function()
		AiThreats.reset()
	end)

	Callbacks.playerDeath(function(e)
		if not e.victim:isEnemy() then
			return
		end

		AiThreats.clearCachedEnemy(e.victim)
	end)

	Callbacks.setupCommand(function()
		AiThreats.think()
	end, true)

	Callbacks.frame(function()
		AiThreats.render()
	end)
end

--- @return void
function AiThreats.reset()
	AiThreats.cacheRefreshRequired = {}
	AiThreats.clientVisgraph = {}
	AiThreats.clientVisgraphOrigin = nil
	AiThreats.closestVisibleEnemyNodes = {}
	AiThreats.determineThreatIndex = 0
	AiThreats.crosshairPlacements = {}
	AiThreats.crosshairPlacementsIdeal = {}
	AiThreats.enemyThreatLevels = {}
	AiThreats.enemyVisgraphOrigins = {}
	AiThreats.enemyVisgraphs = {}
	AiThreats.lastClosestVisibleEnemyNodes = {}
	AiThreats.lastUpdatedThreatTimers = {}
	AiThreats.processEnemyIndex = 0
	AiThreats.threatCount = 0
	AiThreats.threatDetectionTimer = Timer:new():startThenElapse()
	AiThreats.threatLevel = ThreatLevel.NONE
	AiThreats.threats = {}
	AiThreats.threatVisgraph = {}
	AiThreats.totalThreats = 0
	AiThreats.visibleEnemyNodes = {}
end

--- @return void
function AiThreats.think()
	AiThreats.processClient()
	AiThreats.processEnemies()
	AiThreats.determineThreats()
	AiThreats.setThreatLevel()
end

--- @return void
function AiThreats.render()
	if not Debug.isRenderingThreatDetection then
		return
	end

	if AiThreats.threatLevel then
		local map = {
			[ThreatLevel.NONE] = "No Threats",
			[ThreatLevel.LOW] = "Low",
			[ThreatLevel.MEDIUM] = "Medium",
			[ThreatLevel.HIGH] = "High",
			[ThreatLevel.EXTREME] = "Extreme"
		}

		local mod = Math.getInversedFloat(AiThreats.threatLevel, 4) * 80
		local str = map[AiThreats.threatLevel]
		local color = Color:hsla(mod, 0.8, 0.6, 255)

		Client.drawIndicatorFrame(color, str)
	end

	local clientEyeOrigin = LocalPlayer.getEyeOrigin()
	local drawn = {}

	for _, visibleToClient in pairs(AiThreats.clientVisgraph) do
		clientEyeOrigin:drawLine(visibleToClient.origin, Color:hsla(120, 0.8, 0.6, 150))
		visibleToClient.origin:drawScaledCircle(30, Color:hsla(120, 0.8, 0.6, 150))

		for _, visibleByProxy in pairs(visibleToClient.visgraph) do
			if not drawn[visibleByProxy.id] then
				visibleByProxy.origin:drawScaledCircle(30, Color:hsla(1, 1, 1, 75))
				visibleToClient.origin:drawLine(visibleByProxy.origin, Color:hsla(1, 1, 1, 15))
			end

			drawn[visibleByProxy.id] = true
		end

		drawn[visibleToClient.id] = true
	end

	for eid, enemyVisibility in pairs(AiThreats.enemyVisgraphs) do repeat
		local eyeOrigin = AiThreats.enemyVisgraphOrigins[eid]:clone():offset(0, 0, 64)
		local drawnEnemy = {}

		for _, visibleToEnemy in pairs(enemyVisibility) do
			for _, visibleByProxy in pairs(visibleToEnemy.visgraph) do
				if not drawnEnemy[visibleByProxy.id] then
					eyeOrigin:drawLine(visibleByProxy.origin, Color:hsla(35, 0.8, 0.6, 50))
					visibleByProxy.origin:drawScaledCircle(30, Color:hsla(35, 0.8, 0.6, 150))

					drawnEnemy[visibleByProxy.id] = true
				end
			end

			drawnEnemy[visibleToEnemy.id] =  true

			eyeOrigin:drawLine(visibleToEnemy.origin, Color:hsla(0, 0.8, 0.6, 150))
			visibleToEnemy.origin:drawScaledCircle(30, Color:hsla(0, 0.8, 0.6, 150))
		end
	until true end

	for _, nodes in pairs(AiThreats.visibleEnemyNodes) do
		for _, node in pairs(nodes) do
			node.origin:drawScaledCircleOutline(60, 20, Color:hsla(0, 0.8, 0.6, 150))
		end
	end

	for _, node in pairs(AiThreats.closestVisibleEnemyNodes) do
		node.origin:drawScaledCircleOutline(60, 20, Color.WHITE)
	end

	for _, origin in pairs(AiThreats.crosshairPlacements) do
		origin:drawScaledCircleOutline(60, 10, Color:hsla(115, 0.8, 0.6, 255))
	end
end

--- @param player Player
--- @param maxNodes number
--- @param maxTraces number
--- @param maxRange number
--- @return void
function AiThreats.getPlayerVisgraph(player, maxNodes, maxTraces, maxRange)
	maxNodes = maxNodes or 8
	maxTraces = maxTraces or 8
	maxRange = maxRange or 512

	local origin = player:getOrigin()
	local eyeOrigin = origin:clone():offset(0, 0, 64)
	local nodes = Nodegraph.getWithinOfType(origin, maxRange, NodeType.traverse)
	local i = 0
	local count = 0
	local visibility = {}

	for _, node in Table.sortedPairs(nodes, function(a, b)
		return origin:getDistance(a.floorOrigin) < origin:getDistance(b.floorOrigin)
	end) do repeat
		i = i + 1

		if i > maxTraces then
			goto exitGetVisgraph
		end

		if count >= maxNodes then
			goto exitGetVisgraph
		end

		local trace = Trace.getLineToPosition(
			eyeOrigin,
			node.eyeOrigin,
			AiUtility.traceOptionsVisible,
			"AiThreats.getVisGraph<FindVisible>"
		)

		if trace.isIntersectingGeometry then
			break
		end

		count = count + 1
		visibility[node.id] = node
	until true end

	::exitGetVisgraph::

	return visibility
end

--- @return void
function AiThreats.processClient()
	local lastOrigin = AiThreats.clientVisgraphOrigin
	local origin = LocalPlayer:getOrigin()

	if lastOrigin and origin:getDistance(lastOrigin) < 16 then
		return
	end

	AiThreats.clientVisgraphOrigin = origin
	AiThreats.clientVisgraph = AiThreats.getPlayerVisgraph(LocalPlayer, 15, 25, 300)

	for k, _ in pairs(AiThreats.cacheRefreshRequired) do
		AiThreats.cacheRefreshRequired[k] = true
	end
end

--- @return void
function AiThreats.processEnemies()
	AiThreats.processEnemyIndex = AiThreats.processEnemyIndex + 1

	if AiThreats.processEnemyIndex > Table.getCount(AiUtility.enemies) then
		AiThreats.processEnemyIndex = 1
	end

	local index = 0

	for _, enemy in Table.sortedPairs(AiUtility.enemies, function(a, b)
		return a.eid < b.eid
	end) do repeat
		index = index + 1

		if index ~= AiThreats.processEnemyIndex then
			break
		end

		local lastOrigin = AiThreats.enemyVisgraphOrigins[enemy.eid]
		local enemyOrigin = enemy:getOrigin()

		if lastOrigin and enemyOrigin:getDistance(lastOrigin) < 64 then
			break
		end

		AiThreats.enemyVisgraphOrigins[enemy.eid] = enemyOrigin
		AiThreats.enemyVisgraphs[enemy.eid] = AiThreats.getPlayerVisgraph(enemy, 8, 15, 600)
		AiThreats.cacheRefreshRequired[enemy.eid] = true
	until true end
end

--- @param player Player
--- @return void
function AiThreats.clearCachedEnemy(player)
	AiThreats.closestVisibleEnemyNodes[player.eid] = nil
	AiThreats.crosshairPlacements[player.eid] = nil
	AiThreats.crosshairPlacementsIdeal[player.eid] = nil
	AiThreats.enemyThreatLevels[player.eid] = nil
	AiThreats.enemyVisgraphOrigins[player.eid] = nil
	AiThreats.enemyVisgraphs[player.eid] = nil
	AiThreats.lastClosestVisibleEnemyNodes[player.eid] = nil
	AiThreats.threats[player.eid] = nil
	AiThreats.visibleEnemyNodes[player.eid] = nil
	AiThreats.cacheRefreshRequired[player.eid] = true
end

--- @return void
function AiThreats.setThreatLevel()
	local highestThreatLevel = ThreatLevel.NONE

	for _, threatLevel in pairs(AiThreats.enemyThreatLevels) do
		if threatLevel > highestThreatLevel then
			highestThreatLevel = threatLevel
		end
	end

	AiThreats.threatLevel = highestThreatLevel
end

--- @param eid number
--- @param visgraph NodeTypeTraverse[]
--- @return boolean
function AiThreats.isThreatExtremeAndUpdateVisibleEnemyVisgraph(eid, visgraph)
	local eyeOrigin = LocalPlayer.getEyeOrigin()

	if AiUtility.visibleEnemies[eid] then
		return true
	end

	-- Only run this if the threat level to an enemy is high.
	if not AiThreats.enemyThreatLevels[eid] or AiThreats.enemyThreatLevels[eid] < ThreatLevel.HIGH then
		return false
	end

	local visibleNodes = {}
	local i = 0
	--- @type NodeTypeTraverse
	local closestNode
	local closestAngle = math.huge
	local visgraphOrigin = AiThreats.enemyVisgraphOrigins[eid]
	local angleToEnemy = eyeOrigin:getAngle(visgraphOrigin)
	local isExtremeThreatLevel = false

	for _, visibleToEnemy in pairs(visgraph) do repeat
		local trace = Trace.getLineToPosition(
			eyeOrigin,
			visibleToEnemy.eyeOrigin,
			AiUtility.traceOptionsVisible,
			"AiThreats.setVisibleEnemyVisgraphToClient<FindVisibleNode>"
		)

		if trace.isIntersectingGeometry then
			break
		end

		isExtremeThreatLevel = true

		if not visibleToEnemy:is(Node.traverseGeneric) then
			break
		end

		i = i + 1
		visibleNodes[i] = visibleToEnemy

		local angleToNode = eyeOrigin:getAngle(visibleToEnemy.eyeOrigin)
		local delta = angleToEnemy:getAbsDiff(angleToNode).y

		if delta < closestAngle then
			closestAngle = delta
			closestNode = visibleToEnemy
		end
	until true end

	AiThreats.closestVisibleEnemyNodes[eid] = closestNode
	AiThreats.visibleEnemyNodes[eid] = visibleNodes

	return isExtremeThreatLevel
end

--- @return void
function AiThreats.updateThreatVisgraph()
	local threatVisgraph = {}

	for _, enemyVisgraph in pairs(AiThreats.enemyVisgraphs) do
		for _, visibleToEnemy in pairs(enemyVisgraph) do
			threatVisgraph[visibleToEnemy.id] = visibleToEnemy

			for _, visibleToEnemyProxy in pairs(visibleToEnemy.visgraph) do
				threatVisgraph[visibleToEnemyProxy.id] = visibleToEnemyProxy
			end
		end
	end

	AiThreats.threatVisgraph = threatVisgraph
end

--- @return void
function AiThreats.updateClosestThreat()
	local highestThreatLevel = ThreatLevel.NONE
	local closestDistance = math.huge
	local origin = LocalPlayer:getOrigin()
	local closestThreat
	local closestThreatOrigin

	for eid, visgraphOrigin in pairs(AiThreats.enemyVisgraphOrigins) do
		local threatLevel = AiThreats.enemyThreatLevels[eid]
		local distance = origin

		if threatLevel >= highestThreatLevel and distance < closestDistance then
			closestDistance = distance
			highestThreatLevel = threatLevel
			closestThreat = eid
			closestThreatOrigin = visgraphOrigin
		end
	end

	AiThreats.highestThreat = closestThreat and Player:new(closestThreat)
	AiThreats.highestThreatOrigin = closestThreatOrigin
end

--- @return void
function AiThreats.updateCrosshairPlacements()
	local eyeOrigin = LocalPlayer.getEyeOrigin()

	for eid, _ in pairs(AiThreats.enemyVisgraphOrigins) do
		AiThreats.crosshairPlacementsIdeal[eid] = nil
	end

	local valid = {}

	for eid, node in pairs(AiThreats.closestVisibleEnemyNodes) do repeat
		valid[eid] = true

		local threatLevel = AiThreats.enemyThreatLevels[eid]

		if threatLevel < ThreatLevel.HIGH then
			break
		end

		if AiUtility.visibleEnemies[eid] then
			break
		end

		local visgraphOrigin = AiThreats.enemyVisgraphOrigins[eid]:clone():offset(0, 0, 64)
		local direction = node.eyeOrigin:getForward(visgraphOrigin)

		for i = 0, 16 do
			local distanceToStep = i * 16
			local offsetOrigin = node.eyeOrigin +  direction * distanceToStep

			local trace = Trace.getLineToPosition(
				eyeOrigin,
				offsetOrigin,
				AiUtility.traceOptionsVisible,
				"AiThreats.updateCrosshairPlacements<FindVisible>"
			)

			if trace.isIntersectingGeometry then
				break
			end

			AiThreats.crosshairPlacementsIdeal[eid] = offsetOrigin
			AiThreats.lastClosestVisibleEnemyNodes[eid] = node
		end
	until true end

	-- Clear any placements that have become null.
	for eid, _ in pairs(AiThreats.enemyVisgraphs) do
		if not valid[eid] then
			AiThreats.crosshairPlacements[eid] = nil
		end
	end
end

--- @param eid number
--- @return void
function AiThreats.updateCrosshairPlacementOrigin(eid)
	if not AiThreats.crosshairPlacements[eid] and AiThreats.crosshairPlacementsIdeal[eid] then
		AiThreats.crosshairPlacements[eid] = AiThreats.crosshairPlacementsIdeal[eid]
	end

	if AiThreats.crosshairPlacements[eid] and AiThreats.crosshairPlacementsIdeal[eid] then
		AiThreats.crosshairPlacements[eid]:lerp(AiThreats.crosshairPlacementsIdeal[eid], 10 * Time.delta)
	else
		AiThreats.crosshairPlacements[eid] = nil
	end
end

--- @return void
function AiThreats.determineThreats()
	-- No visgraphs to process.
	if Table.isEmpty(AiThreats.enemyVisgraphs) then
		AiThreats.threatLevel = ThreatLevel.NONE

		return
	end

	AiThreats.determineThreatIndex = AiThreats.determineThreatIndex + 1

	if AiThreats.determineThreatIndex > Table.getCount(AiThreats.enemyVisgraphs) then
		AiThreats.determineThreatIndex = 1
	end

	local index = 0
	local visgraphs, eids = Table.getSortedByKey(AiThreats.enemyVisgraphs)
	local origin = LocalPlayer:getOrigin()
	local isAnyVisgraphUpdated = false

	--- @param enemyVisgraph NodeTypeTraverse[]
	for _, enemyVisgraph in pairs(visgraphs) do repeat
		index = index + 1

		local eid = eids[index]
		local isProcessed = AiThreats.enemyThreatLevels[eid] ~= nil

		-- Do this every tick.
		AiThreats.updateCrosshairPlacementOrigin(eid)

		if isProcessed then
			if index ~= AiThreats.determineThreatIndex then
				break
			end

			if not AiThreats.cacheRefreshRequired[eid] then
				break
			end
		end

		AiThreats.cacheRefreshRequired[eid] = false

		--- @type NodeTypeTraverse[]
		local visgraph = enemyVisgraph
		local isUpdated = true
		local transientThreatLevel = ThreatLevel.NONE

		for _, visibleToClient in pairs(AiThreats.clientVisgraph) do
			for _, visibleToEnemy in pairs(enemyVisgraph) do
				if visibleToClient.visgraph[visibleToEnemy.id] then
					transientThreatLevel = ThreatLevel.HIGH

					goto exitDetermineThreats
				end

				for _, visibleToClientProxy in pairs(visibleToClient.visgraph) do
					if transientThreatLevel == ThreatLevel.MEDIUM then
						break
					end

					if visibleToClientProxy.visgraph[visibleToEnemy.id] then
						local clientDistance = origin:getDistance(visibleToClientProxy.floorOrigin)
						local visgraphOriginDistance = AiThreats.enemyVisgraphOrigins[eid]:getDistance(visibleToClientProxy.floorOrigin)

						if clientDistance < 500 or visgraphOriginDistance < 500 then
							transientThreatLevel = ThreatLevel.MEDIUM
						else
							transientThreatLevel = ThreatLevel.LOW
						end
					end
				end
			end
		end

		::exitDetermineThreats::

		-- No visgraph has been processed.
		if not isUpdated then
			break
		end

		isAnyVisgraphUpdated = true

		local isExtreme = AiThreats.isThreatExtremeAndUpdateVisibleEnemyVisgraph(eid, visgraph)

		if isExtreme then
			transientThreatLevel = ThreatLevel.EXTREME
		end

		-- We want to ignore the timer if the threat level is going up.
		local isThreatLevelUpgraded = transientThreatLevel > AiThreats.threatLevel

		if not AiThreats.threatDetectionTimer:isElapsed(1) and not isThreatLevelUpgraded then
			break
		end

		if transientThreatLevel ~= AiThreats.enemyThreatLevels[eid] then
			AiThreats.threatDetectionTimer:start()
		end

		-- This is set to nil when the visgraph becomes invalid.
		AiThreats.enemyThreatLevels[eid] = transientThreatLevel
		AiThreats.threats[eid] = Player:new(eid)
	until true end

	AiThreats.totalThreats = Table.getCount(AiThreats.threats)

	if isAnyVisgraphUpdated then
		AiThreats.updateClosestThreat()
		AiThreats.updateThreatVisgraph()
	end

	AiThreats.updateCrosshairPlacements()
end

return Nyx.class("AiThreats", AiThreats)
--}}}
