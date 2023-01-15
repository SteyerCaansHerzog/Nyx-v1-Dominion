--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Math = require "gamesense/Nyx/v1/Api/Math"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AStar = require "gamesense/Nyx/v1/Dominion/Traversal/AStar"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local NodeType = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeType"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
--}}}

--{{{ Definitions
--- @class PathfinderOptions
--- @field goalReachedRadius number
--- @field isAllowedToTraverseInactives boolean
--- @field isCachingRequest boolean
--- @field isClearingActivePath boolean
--- @field isCorrectingGoalZ boolean
--- @field isCounterStrafingOnGoal boolean
--- @field isPathfindingByCollisionLineOnFailure boolean
--- @field isPathfindingFromNearestNodeIfNoConnections boolean
--- @field isPathfindingToNearestNodeIfNoConnections boolean
--- @field isPathfindingToNearestNodeOnFailure boolean
--- @field onFailedToFindPath fun(): void
--- @field onFoundPath fun(): void
--- @field onReachedGoal fun(): void
--- @field startOriginOverride Vector3
--- @field task string

--- @class PathfinderPath
--- @field endGoal NodeTypeGoal
--- @field errorMessage string
--- @field finalIdx number
--- @field idx number
--- @field isDoorInPath boolean
--- @field isDuckInPath boolean
--- @field isJumpInPath boolean
--- @field isLadderInPath boolean
--- @field isObstacleInPath boolean
--- @field isOk boolean
--- @field node NodeTypeBase
--- @field nodeCount number
--- @field nodes NodeTypeBase[]
--- @field startGoal NodeTypeBase
--- @field task string

--- @class PathfinderRequest
--- @field endOrigin Vector3
--- @field options PathfinderOptions
--- @field startOrigin Vector3
--- @field targetNode NodeTypeBase

--- @class PathfinderPathDebugNode
--- @field node NodeTypeBase
--- @field error string

--- @class PathfinderPathDebug
--- @field username string
--- @field task string
--- @field nodes PathfinderPathDebugNode[]
--- @field isOk boolean
--- @field startOrigin Vector3
--- @field endOrigin Vector3
--- @field dateTimeFormatted string
--}}}

--{{{ Pathfinder
--- @class Pathfinder : Class
--- @field avoidTeammatesAngle Angle
--- @field avoidTeammatesDirection string
--- @field avoidTeammatesDuration number
--- @field avoidTeammatesTimer Timer
--- @field blockedBombsite NodeTypeObjective
--- @field cachedLastRequest PathfinderRequest
--- @field deactivatedNodesPool NodeTypeBase[]
--- @field directMovementAngle Angle
--- @field goalConnectionCollisions table<number, NodeTypeBaseConnectionCollision[]>
--- @field goalGapCollisions table<number, NodeTypeBaseGapCollision[]>
--- @field isAllowedToAvoidTeammates boolean
--- @field isAllowedToDuck boolean
--- @field isAllowedToJump boolean
--- @field isAllowedToMove boolean
--- @field isAllowedToRandomlyJump boolean
--- @field isAllowedToWalk boolean
--- @field isAscendingLadder boolean
--- @field isAvoidingTeammate boolean
--- @field isCounterStrafing boolean
--- @field isDescendingLadder boolean
--- @field isDucking boolean
--- @field isEnabled boolean
--- @field isInsideInferno boolean
--- @field isInsideSmoke boolean
--- @field isJumping boolean
--- @field isLoggingEnabled boolean
--- @field isObstructedByDoor boolean
--- @field isObstructedByObstacle boolean
--- @field isObstructedByTeammate boolean
--- @field isReadyToReplayMovementRecording boolean
--- @field isReplayingMovementRecording boolean
--- @field isWalking boolean
--- @field lastMovementAngle Angle
--- @field lastRequest PathfinderRequest
--- @field moveDuckTimer Timer
--- @field movementRecorderAngle Angle
--- @field movementRecorderTimer Timer
--- @field moveObstructedTimer Timer
--- @field moveOnGroundTimer Timer
--- @field nodeClassesInTentativePath NodeTypeBase[]
--- @field path PathfinderPath
--- @field pathDebug PathfinderPathDebug
--- @field pathfindInterval number
--- @field pathfindIntervalTimer Timer
--- @field randomJumpIntervalTime number
--- @field randomJumpIntervalTimer Timer
local Pathfinder = {}

--- @return void
function Pathfinder.__setup()
	Pathfinder.initFields()
	Pathfinder.initEvents()
	Pathfinder.initMenu()

	Logger.console(Logger.OK, Localization.pathfinderReady)
end

--- @return void
function Pathfinder.initFields()
	Pathfinder.isLoggingEnabled = true
	Pathfinder.avoidTeammatesDirection = "Left"
	Pathfinder.avoidTeammatesDuration = 0.6
	Pathfinder.avoidTeammatesTimer = Timer:new()
	Pathfinder.isAllowedToDuck = true
	Pathfinder.isAllowedToJump = true
	Pathfinder.isAllowedToWalk = true
	Pathfinder.isEnabled = true
	Pathfinder.moveDuckTimer = Timer:new()
	Pathfinder.moveObstructedTimer = Timer:new()
	Pathfinder.moveOnGroundTimer = Timer:new()
	Pathfinder.pathfindInterval = 0.2
	Pathfinder.pathfindIntervalTimer = Timer:new():startThenElapse()
	Pathfinder.goalConnectionCollisions = {}
	Pathfinder.goalGapCollisions = {}
	Pathfinder.movementRecorderTimer = Timer:new()
	Pathfinder.randomJumpIntervalTime = Math.getRandomFloat(0, 160)
	Pathfinder.randomJumpIntervalTimer = Timer:new():start()
end

--- @return void
function Pathfinder.initEvents()
	Callbacks.setupCommand(function(cmd)
		if not Pathfinder.isEnabled then
			return
		end

		Pathfinder.traverseActivePath(cmd)
		Pathfinder.handleRecorders()

		-- Allow the jump interval timer to elapse and restart itself.
		-- Otherwise, the AI will jump at the first opportunity it gets, which is usually right as the round begins.
		Pathfinder.randomJumpIntervalTimer:isElapsedThenRestart(Pathfinder.randomJumpIntervalTime)
	end, true)

	Callbacks.setupCommand(function()
		if not Pathfinder.isEnabled then
			return
		end

		Pathfinder.handleLastRequest()
		Pathfinder.handleBlockedRoutes()
		Pathfinder.resetMoveParameters()
	end, false)

	Callbacks.frame(function()
		Pathfinder.render()
	end)

	Callbacks.roundStart(function()
		-- Prevent pathfinding from a previous round.
		Pathfinder.clearActivePathAndLastRequest()

		-- Reactivate any deactivated nodes.
		for _, node in pairs(Nodegraph.getOfType(NodeType.traverse)) do
			node:activate()
		end

		-- Execute all block nodes.
		for _, node in pairs(Nodegraph.get(Node.hintBlock)) do
			node:block(Nodegraph)
		end

		Pathfinder.blockedBombsite = nil
	end)

	Callbacks.bombSpawned(function(e)
		local bombsite = Nodegraph.getClosestBombsite(e.bomb:m_vecOrigin())

		Pathfinder.blockRoute(bombsite)
	end)

	Callbacks.hostageFollows(function(e)
		if e.player:isLocalPlayer() then
			Pathfinder.blockRoute()
		end
	end)

	Callbacks.smokeGrenadeDetonate(function(e)
		--- @type NodeTypeBase[]
		local pool = {}
		local smokeBounds = e.origin:getBounds(Vector3.align.UP, 144, 144, 72)

		for _, node in pairs(Nodegraph.getOfType(NodeType.traverse)) do repeat
			if not node.origin:isInBounds(smokeBounds) then
				break
			end

			node.isOccludedBySmoke = true

			table.insert(pool, node)
		until true end

		Client.fireAfter(18, function()
			for _, node in pairs(pool) do
				node.isOccludedBySmoke = false
			end
		end)
	end)

	Callbacks.infernoStartBurn(function(e)
		--- @type NodeTypeBase[]
		local pool = {}
		local bounds = e.origin:getBounds(Vector3.align.CENTER, 128, 128, 48)

		for _, node in pairs(Nodegraph.getOfType(NodeType.traverse)) do repeat
			if node.origin:isInBounds(bounds) then
				break
			end

			node.isOccludedByInferno = true

			table.insert(pool, node)
		until true end

		Client.fireAfter(7, function()
			for _, node in pairs(pool) do
				node.isOccludedByInferno = false
			end
		end)
	end)
end

--- @return void
function Pathfinder.initMenu()
	MenuGroup.enablePathfinder = MenuGroup.group:addCheckbox(" > Enable Pathfinder"):setParent(MenuGroup.master)
	MenuGroup.enableMovement = MenuGroup.group:addCheckbox("    > Enable Movement"):setParent(MenuGroup.enablePathfinder)
	MenuGroup.visualisePath = MenuGroup.group:addCheckbox("    > Visualise Path"):setParent(MenuGroup.enablePathfinder)
end

--- @param bombsite NodeTypeObjective
--- @return void
function Pathfinder.blockRoute(bombsite)
	if not LocalPlayer:isCounterTerrorist() then
		return
	end

	-- Run all block nodes.
	Node.hintBlockRoute.block(Nodegraph, bombsite and bombsite.bombsite or nil)

	Pathfinder.blockedBombsite = bombsite
end

--- @return void
function Pathfinder.handleBlockedRoutes()
	-- This may be legacy code at this point.
	-- Doesn't handle the hostage gamemode.
	if not Pathfinder.blockedBombsite then
		return
	end

	if LocalPlayer:getOrigin():getDistance(Pathfinder.blockedBombsite.origin) > 1500 then
		return
	end

	-- Reactivate blocked nodes if the AI is near the bombsite.
	for _, node in pairs(Nodegraph.get(Node.hintBlockRoute)) do
		for _, blockedNode in pairs(node.blockedNodes) do
			blockedNode:activate()
		end
	end

	Pathfinder.blockedBombsite = nil
end

--- @param nodes NodeTypeBase[]
--- @return void
function Pathfinder.activateMany(nodes)
	for _, node in pairs(nodes) do
		node:activate()
	end
end

--- @param nodes NodeTypeBase[]
--- @return void
function Pathfinder.deactivateMany(nodes)
	for _, node in pairs(nodes) do
		node:deactivate()
	end
end

--- @return void
function Pathfinder.render()
	if not MenuGroup.visualisePath:get() then
		return
	end

	if not Pathfinder.path then
		return
	end

	if not Pathfinder.path.isOk then
		local drawPos = Client.getScreenDimensionsCenter():set(nil, 200)
		local bgDims = Vector2:new(500, 50)

		drawPos:drawBlur(bgDims, true)
		drawPos:drawSurfaceRectangleOutline(4, 2, bgDims, ColorList.ERROR, true)
		drawPos:drawSurfaceRectangle(bgDims, ColorList.BACKGROUND_1, true)
		drawPos:clone():offset(0, -20):drawSurfaceText(Font.LARGE, ColorList.ERROR, "c", Pathfinder.path.errorMessage)

		return
	end

	for i, node in pairs(Pathfinder.path.nodes) do
		node:render(Nodegraph, false)

		local nextNode = Pathfinder.path.nodes[i + 1]

		if nextNode then
			if i == Pathfinder.path.idx - 1 then
				node.origin:drawLine(nextNode.origin, ColorList.OK, 0.25)
			elseif i >= Pathfinder.path.idx then
				node.origin:drawLine(nextNode.origin, ColorList.INFO, 0.25)
			else
				node.origin:drawLine(nextNode.origin, Color:hsla(235, 0.16, 0.66, 100), 0.25)
			end
		end

		if i == Pathfinder.path.idx then
			node.origin:drawScaledCircleOutline(100, 20, ColorList.OK)
		elseif i > Pathfinder.path.idx - 1 then
			node.origin:drawScaledCircleOutline(60, 10, ColorList.INFO)
		else
			node.origin:drawScaledCircleOutline(60, 10, Color:hsla(235, 0.16, 0.66, 100))
		end
	end
end

--- @return void
function Pathfinder.syncClientState()
	Pathfinder.clientState.isOnGround = LocalPlayer:getFlag(Player.flags.FL_ONGROUND)
	Pathfinder.clientState.origin = LocalPlayer:getOrigin()
end

--- @return void
function Pathfinder.canRandomlyJump()
	Pathfinder.isAllowedToRandomlyJump = true
end

--- @return void
function Pathfinder.blockJumping()
	Pathfinder.isAllowedToJump = false
	Pathfinder.isAllowedToRandomlyJump = false
end

--- @return void
function Pathfinder.blockTeammateAvoidance()
	Pathfinder.isAllowedToAvoidTeammates = false
end

--- @return void
function Pathfinder.standStill()
	Pathfinder.isAllowedToMove = false
	Pathfinder.isAllowedToRandomlyJump = false
end

--- @return void
function Pathfinder.walk()
	Pathfinder.isWalking = true
	Pathfinder.isAllowedToRandomlyJump = false
end

--- @return void
function Pathfinder.duck()
	Pathfinder.isDucking = true
	Pathfinder.isAllowedToRandomlyJump = false
end

--- @return void
function Pathfinder.jump()
	Pathfinder.isJumping = true
	Pathfinder.isAllowedToRandomlyJump = false
end

--- @return void
function Pathfinder.counterStrafe()
	Pathfinder.isCounterStrafing = true
end

--- @param direction Vector3
--- @param isClearingActivePath boolean
--- @return void
function Pathfinder.moveInDirection(direction, isClearingActivePath)
	Pathfinder.directMovementAngle = direction:getAngleFromForward()

	if isClearingActivePath then
		Pathfinder.clearActivePathAndLastRequest()
	end
end

--- @param angle Angle
--- @param isClearingActivePath boolean
--- @return void
function Pathfinder.moveAtAngle(angle, isClearingActivePath)
	Pathfinder.directMovementAngle = angle:clone()

	if isClearingActivePath then
		Pathfinder.clearActivePathAndLastRequest()
	end
end

--- @param origin Vector3
--- @param options PathfinderOptions
--- @return PathfinderPath
function Pathfinder.moveToLocation(origin, options)
	if not origin then
		error(string.format(Localization.pathfinderNoOrigin, options.task), 2)
	end

	Pathfinder.lastRequest = {
		endOrigin = origin,
		options = options
	}
end

--- @param node NodeTypeBase
--- @param options PathfinderOptions
--- @return PathfinderPath
function Pathfinder.moveToNode(node, options)
	if not node then
		error(string.format(Localization.pathfinderNoOrigin, options.task), 2)
	end

	Pathfinder.lastRequest = {
		endOrigin = node.origin,
		options = options,
		targetNode = node
	}
end

--- @return void
function Pathfinder.handleRecorders()
	local teammateOrigins = {}

	for _, teammate in pairs(AiUtility.teammates) do
		table.insert(teammateOrigins, teammate:getOrigin())
	end

	for _, node in pairs(Nodegraph.get(Node.traverseRecorderStart)) do
		local isOccupied = false

		for _, origin in pairs(teammateOrigins) do
			if node.origin:getDistance(origin) < 145 then
				isOccupied = true

				break
			end
		end

		if isOccupied then
			node:deactivate()
		elseif not node.isActive then
			node:activate()
		end
	end
end

--- @return void
function Pathfinder.retryLastRequest()
	if not Pathfinder.cachedLastRequest then
		return
	end

	Pathfinder.lastRequest = Pathfinder.cachedLastRequest
	Pathfinder.lastRequest.startOrigin = LocalPlayer:getOrigin()
end

--- @return boolean
function Pathfinder.isOnValidPath()
	if not Pathfinder.path then
		return false
	end

	if not Pathfinder.path.isOk then
		return false
	end

	if not Pathfinder.path.node then
		return false
	end

	return true
end

--- @return boolean
function Pathfinder.isIdle()
	if Pathfinder.path then
		return false
	end

	if Pathfinder.lastRequest then
		return false
	end

	return true
end

--- @return void
function Pathfinder.ifIdleThenRetryLastRequest()
	if not Pathfinder.isIdle() then
		return
	end

	if not Pathfinder.cachedLastRequest then
		return false
	end

	if LocalPlayer:getOrigin():getDistance2(Pathfinder.cachedLastRequest.endOrigin) <= Pathfinder.cachedLastRequest.options.goalReachedRadius then
		return
	end

	Pathfinder.retryLastRequest()
end

--- @return void
function Pathfinder.clearActivePath()
	Pathfinder.path = nil
end

--- @return void
function Pathfinder.clearLastRequest()
	Pathfinder.lastRequest = nil

	Pathfinder.cleanupLastRequest()
end

--- @return void
function Pathfinder.cleanupLastRequest()
	Nodegraph.clearType(NodeType.goal)
end

--- @param isReleasingHandleLock boolean
--- @return void
function Pathfinder.clearActivePathAndLastRequest(isReleasingHandleLock)
	Pathfinder.clearActivePath()
	Pathfinder.clearLastRequest()

	if isReleasingHandleLock then
		Pathfinder.pathfindIntervalTimer:elapse()
	end
end

--- @return void
function Pathfinder.flushRequest()
	Pathfinder.clearActivePathAndLastRequest(true)

	Pathfinder.cachedLastRequest = nil
end

--- @return void
function Pathfinder.handleCurrentRequest()
	Pathfinder.createPath()
end

--- @return void
function Pathfinder.handleLastRequest()
	-- Pathfinding is not enabled.
	if not MenuGroup.enablePathfinder:get() then
		return
	end

	-- No request to handle.
	if not Pathfinder.lastRequest then
		return
	end

	-- Prevent spamming the A* algorithm.
	if not Pathfinder.pathfindIntervalTimer:isElapsedThenRestart(Pathfinder.pathfindInterval) then
		return
	end

	-- Don't path while the player is in-air.
	if not LocalPlayer:getFlag(Player.flags.FL_ONGROUND) then
		return
	end

	Pathfinder.createPath()
end

--- @return void
function Pathfinder.createPath()
	-- Get pathfind request options.
	local pathfinderOptions = Pathfinder.lastRequest.options or {}

	-- Set any missing options to default values.
	Table.setMissing(pathfinderOptions, {
		goalReachedRadius = 15,
		isAllowedToTraverseInactives = false,
		isCachingRequest = true,
		isClearingActivePath = true,
		isCorrectingGoalZ = true,
		isCounterStrafingOnGoal = false,
		isPathfindingByCollisionLineOnFailure = false,
		isPathfindingFromNearestNodeIfNoConnections = true,
		isPathfindingToNearestNodeIfNoConnections = false,
		isPathfindingToNearestNodeOnFailure = false,
		task = "Unnamed task",
	})

	Pathfinder.lastRequest.startOrigin = LocalPlayer:getOrigin()
	Pathfinder.lastRequest.options = pathfinderOptions

	-- Path start.
	local startGoal = Node.goalStart:new({
		origin = pathfinderOptions.startOriginOverride and pathfinderOptions.startOriginOverride or Pathfinder.lastRequest.startOrigin:clone():offset(0, 0, 18)
	})

	local endGoalOrigin = Pathfinder.lastRequest.endOrigin

	-- Emit a warning, we may be trying to pathfind to a blank vector.
	if endGoalOrigin:isZero() then
		Logger.console(Logger.WARNING, Localization.pathfinderEndGoalIsZero)
	end

	-- Path end.
	local endGoal = Node.goalEnd:new({
		origin = endGoalOrigin:clone():offset(0, 0, 18)
	})

	-- Ensure nodes comply with human collision hull.
	Pathfinder.correctGoalOrigin(startGoal)
	Pathfinder.correctGoalOrigin(endGoal)

	-- Correct Z axis of nodes.
	if pathfinderOptions.isCorrectingGoalZ then
		-- Do not correct the Z if we're on a ladder.
		-- Otherwise we'll have to pathfind from the bottom again.
		if not LocalPlayer:isMoveType(Player.moveType.LADDER) then
			Pathfinder.correctGoalZ(startGoal)
		end

		Pathfinder.correctGoalZ(endGoal)
	end

	-- We're already within range.
	if LocalPlayer:getOrigin():getDistance(endGoal.origin) < pathfinderOptions.goalReachedRadius then
		return
	end

	-- Clear any active path.
	if pathfinderOptions.isClearingActivePath then
		Pathfinder.clearActivePath()
	end

	-- Remove previous goals.
	Pathfinder.cleanupLastRequest()

	-- Add the start and end of the path.
	Nodegraph.addMany({
		startGoal,
		endGoal
	}, false)

	-- Setup node connections.
	startGoal:setConnections(Nodegraph, {
		isCollisionInfoSaved = true,
		isInversingConnections = true,
		isRestrictingConnections = true,
		isTestingForGaps = true,
		isUsingHumanCollisionTest = true,
		maxConnections = 8,
	})

	endGoal:setConnections(Nodegraph, {
		isCollisionInfoSaved = true,
		isInversingConnections = true,
		isRestrictingConnections = true,
		isTestingForGaps = true,
		isUsingHumanCollisionTest = true,
		maxConnections = 8,
	})

	if Debug.isDisplayingConnectionCollisions then
		Pathfinder.goalConnectionCollisions = {
			startGoal.connectionCollisions
		}

		return
	end

	if Debug.isDisplayingGapCollisions then
		Pathfinder.goalGapCollisions = {
			startGoal.gapCollisions
		}

		return
	end

	-- No connections for start node.
	if startGoal:isConnectionless() then
		if pathfinderOptions.isPathfindingFromNearestNodeIfNoConnections then
			local closest = Nodegraph.getClosestOfType(LocalPlayer:getOrigin(), NodeType.traverse)

			startGoal.origin = closest.origin:clone()

			startGoal:setConnections(Nodegraph, {
				isCollisionInfoSaved = true,
				isInversingConnections = true,
				isRestrictingConnections = true,
				isTestingForGaps = true,
				isUsingHumanCollisionTest = true,
				maxConnections = 8,
			})
		else
			Pathfinder.failPath(pathfinderOptions, nil, "Start is out of bounds", 1)

			return
		end
	end

	-- No connections to goal node.
	if endGoal:isConnectionless() then
		if pathfinderOptions.isPathfindingToNearestNodeIfNoConnections then
			local closest = Nodegraph.getClosestOfType(Pathfinder.lastRequest.endOrigin, NodeType.traverse)

			endGoal.origin = closest.origin:clone()

			endGoal:setConnections(Nodegraph, {
				isCollisionInfoSaved = true,
				isInversingConnections = true,
				isRestrictingConnections = true,
				isTestingForGaps = true,
				isUsingHumanCollisionTest = true,
				maxConnections = 8,
			})
		elseif pathfinderOptions.isPathfindingByCollisionLineOnFailure then
			endGoal:setConnections(Nodegraph, {
				isCollisionInfoSaved = true,
				isInversingConnections = true,
				isRestrictingConnections = true,
				isTestingForGaps = true,
				isUsingHumanCollisionTest = true,
				isUsingLineCollisionTest = true,
				maxConnections = 8,
			})
		else
			Pathfinder.failPath(pathfinderOptions, endGoal, "Goal is unreachable", 1)

			return
		end
	end

	-- Find a path.
	local tentativePath = Pathfinder.getPath(startGoal, endGoal, pathfinderOptions)

	-- We didn't find a path.
	if not tentativePath then
		-- Try to find a path to the nearest node.
		if pathfinderOptions.isPathfindingToNearestNodeOnFailure then
			endGoal = Nodegraph.getClosestOfType(Pathfinder.lastRequest.endOrigin, NodeType.traverse)
			tentativePath = Pathfinder.getPath(startGoal, endGoal, pathfinderOptions)
		end

		-- Still no path.
		if not tentativePath then
			Pathfinder.failPath(pathfinderOptions, endGoal, "No path available", 2)

			return
		end
	end

	local isDuckInPath = false
	local isJumpInPath = false

	-- Execute callbacks and set nodes in path.
	for _, node in pairs(tentativePath) do
		node:onIsInPath(Nodegraph)

		if node.isDuck then
			isDuckInPath = true
		end

		if node.isJump then
			isJumpInPath = true
		end
	end

	-- Setup data for current path.
	if pathfinderOptions.isCachingRequest then
		Pathfinder.cachedLastRequest = Pathfinder.lastRequest
	end

	Pathfinder.lastRequest = nil

	Pathfinder.path = {
		endGoal = endGoal,
		idx = 1,
		finalIdx = #tentativePath,
		isDoorInPath = Pathfinder.nodeClassesInTentativePath[Node.traverseDoor.__classid],
		isDuckInPath = isDuckInPath,
		isJumpInPath = isJumpInPath,
		isLadderInPath = Pathfinder.nodeClassesInTentativePath[Node.traverseLadderTop.__classid] or Pathfinder.nodeClassesInTentativePath[Node.traverseLadderTop.__classid],
		isObstacleInPath = Pathfinder.nodeClassesInTentativePath[Node.traverseBreakObstacle.__classid],
		isOk = true,
		node = startGoal,
		nodeCount = #tentativePath,
		nodes = tentativePath,
		path = tentativePath,
		startGoal = startGoal,
		task = pathfinderOptions.task,
	}

	Pathfinder.pathDebug.isOk = true

	if pathfinderOptions.onFoundPath then
		pathfinderOptions.onFoundPath()
	end

	Pathfinder.clearLastRequest()

	-- We're already on the start goal. We can ignore it.
	Pathfinder.incrementPath("remove start goal")

	if Pathfinder.isLoggingEnabled then
		Logger.console(Logger.INFO, Localization.pathfinderNewTask, pathfinderOptions.task)
	end
end

--- @param options PathfinderOptions
--- @param goal NodeTypeGoal|nil
--- @param error string
--- @return void
function Pathfinder.failPath(options, goal, error, code)
	Pathfinder.path = {
		isOk = false,
		errorMessage = error,
		startOrigin = Pathfinder.lastRequest.startOrigin,
		endOrigin = Pathfinder.lastRequest.endOrigin,
	}

	local time = Time.getDateTime()

	if not Pathfinder.pathDebug then
		Pathfinder.pathDebug = {}
	end

	Pathfinder.pathDebug.username = LocalPlayer:getName()
	Pathfinder.pathDebug.task = Pathfinder.lastRequest.options.task
	Pathfinder.pathDebug.isOk = false
	Pathfinder.pathDebug.startOrigin = Pathfinder.lastRequest.startOrigin
	Pathfinder.pathDebug.endOrigin = Pathfinder.lastRequest.endOrigin
	Pathfinder.pathDebug.dateTimeFormatted = string.format(
		"%02d/%02d/%02d @ %02d:%02d",
		time.day, time.month, time.year, time.hour, time.minute
	)

	if options.onFailedToFindPath then
		options.onFailedToFindPath()
	end

	Pathfinder.flushPathDebug()
	Pathfinder.cleanupLastRequest()

	if not Pathfinder.isLoggingEnabled then
		return
	end

	if goal then
		local node = Pathfinder.lastRequest.targetNode

		if node then
			Logger.console(code, Localization.pathfinderFailedKnownGoal, Pathfinder.lastRequest.options.task, error, node.id, node.name)
		else
			node = Nodegraph.getClosest(goal.origin)

			Logger.console(code, Localization.pathfinderFailedGuessGoal, Pathfinder.lastRequest.options.task, error, node.id, node.name, node.origin:__tostring())
		end

	else
		Logger.console(code, Localization.pathfinderFailed, Pathfinder.lastRequest.options.task, error)
	end
end

--- @return void
function Pathfinder.flushPathDebug()
	if not Pathfinder.pathDebug.nodes then
		return
	end

	local filename = string.format(Config.getPath("Resource/Data/PathfinderPathDebug_%s.json"), LocalPlayer:getSteamId64())

	--- @type PathfinderPathDebug
	local data = {
		task = Pathfinder.pathDebug.task,
		username = Pathfinder.pathDebug.username,
		dateTimeFormatted = Pathfinder.pathDebug.dateTimeFormatted,
		startOrigin = Pathfinder.pathDebug.startOrigin:__serialize(),
		endOrigin = Pathfinder.pathDebug.endOrigin:__serialize()
	}

	for _, debug in pairs(Pathfinder.pathDebug.nodes) do
		if debug.error then
			table.insert(data, {
				node = debug.node.id,
				error = debug.error
			})
		end
	end

	writefile(filename, json.stringify(data))
end

--- @return void
function Pathfinder.loadPathDebug(steamid64)
	if steamid64 == nil and Pathfinder.pathDebug ~= nil then
		Pathfinder.pathDebug = nil

		Logger.console(Logger.OK, "Unloaded previously stored failed path.")

		return
	end

	local filename = string.format(Config.getPath("Resource/Data/PathfinderPathDebug_%s.json"), steamid64)
	local filedata = readfile(filename)

	if not filedata then
		Logger.console(Logger.ERROR, "Cannot load stored failed path for SteamID64 '%s' as the file does not exist.", steamid64)

		return
	end

	--- @type PathfinderPathDebug
	local data = json.parse(filedata)

	Pathfinder.pathDebug = {
		nodes = {},
		isOk = false,
		task = data.task,
		username = data.username,
		dateTimeFormatted = data.dateTimeFormatted,
		startOrigin = Vector3:newFromTable(data.startOrigin),
		endOrigin = Vector3:newFromTable(data.endOrigin)
	}

	for _, debug in pairs(data) do
		if Nodegraph.nodes[debug.node] then
			table.insert(Pathfinder.pathDebug.nodes, {
				node = Nodegraph.nodes[debug.node],
				error = debug.error
			})
		end
	end

	Logger.console(Logger.OK, "[%s] Loaded previously stored failed path for [%s] '%s': %s.", data.dateTimeFormatted, steamid64, data.username, data.task)
end

--- @param start NodeTypeGoal
--- @param goal NodeTypeGoal
--- @param options PathfinderOptions
--- @return NodeTypeBase[]
function Pathfinder.getPath(start, goal, options)
	Pathfinder.nodeClassesInTentativePath = {}
	Pathfinder.pathDebug = {
		nodes = {}
	}

	local idx = 0

	return AStar.findPath(start, goal, Nodegraph.pathableNodes, true, function(node, neighbor)
		idx = neighbor.id

		--- @type PathfinderPathDebugNode
		Pathfinder.pathDebug.nodes[idx] = {
			node = neighbor
		}

		if not node.connections[neighbor.id] then
			Pathfinder.pathDebug.nodes[idx].error = "IS NOT CONNECTED"

			return false
		end

		if not neighbor.isActive then
			Pathfinder.pathDebug.nodes[idx].error = "IS NOT ACTIVE"

			return false
		end

		if neighbor.isJump then
			local zDelta = neighbor.origin.z - node.origin.z

			if zDelta > neighbor.zDeltaThreshold then
				Pathfinder.pathDebug.nodes[idx].error = "IS OVER ZDELTA THRESHOLD"

				return false
			end

			if node.isGoal and (zDelta > neighbor.zDeltaGoalThreshold) then
				Pathfinder.pathDebug.nodes[idx].error = "IS OVER ZDELTA THRESHOLD"

				return false
			end
		end

		if node.isRecorder or neighbor.isRecorder then
			Pathfinder.pathDebug.nodes[idx].error = "IS RECORDER AND CURRENTLY BLOCKED"

			return false
		end

		if not node.isRecorder and (neighbor.isRecorder and neighbor:is(Node.traverseRecorderEnd)) then
			Pathfinder.pathDebug.nodes[idx].error = "IS RECORDER END"

			return false
		end

		Pathfinder.nodeClassesInTentativePath[neighbor.__classid] = true

		return true
	end)
end

--- @param node NodeTypeBase
--- @return void
function Pathfinder.correctGoalZ(node)
	local trace = Trace.getHullInDirection(
		node.origin,
		Vector3.align.DOWN,
		Vector3:newBounds(Vector3.align.CENTER, 15, 15, 18),
		AiUtility.traceOptionsPathfinding,
		"Pathfinder.correctGoalZ<FindFloor>"
	)

	node.origin:setFromVector(trace.endPosition)
end

--- @param node NodeTypeBase
--- @return void
function Pathfinder.correctGoalOrigin(node)
	node.origin:offset(0, 0, 18)

	local trace = Trace.getHullInPlace(
		node.origin,
		Vector3:newBounds(Vector3.align.CENTER, 15, 15, 18),
		AiUtility.traceOptionsPathfinding,
		"Pathfinder.correctGoalOrigin<FindCorrectedOrigin>"
	)

	node.origin:setFromVector(trace.endPosition)
end

--- This code was written through a process of trial and error that lasted several months. I do not want to refactor it.
--- Otherwise I will more than likely break the AI.
---
--- @param cmd SetupCommandEvent
--- @return void
function Pathfinder.traverseActivePath(cmd)
	if not MenuGroup.master:get() or not MenuGroup.enablePathfinder:get() then
		return
	end

	Pathfinder.isObstructedByObstacle = false
	Pathfinder.isObstructedByDoor = false
	Pathfinder.isObstructedByTeammate = false
	Pathfinder.isAscendingLadder = false
	Pathfinder.isDescendingLadder = false
	Pathfinder.isReplayingMovementRecording = false
	Pathfinder.movementRecorderAngle = nil

	if not Pathfinder.isAllowedToMove and not Pathfinder.isInsideInferno then
		return
	end

	if LocalPlayer:getFlag(Player.flags.FL_ONGROUND) then
		Pathfinder.moveOnGroundTimer:ifPausedThenStart()
	else
		Pathfinder.moveOnGroundTimer:restart()
	end

	Pathfinder.airDuck(cmd)
	Pathfinder.handleMovementOptions(cmd)

	if Pathfinder.directMovementAngle then
		Pathfinder.ejectFromLadder(cmd)
		Pathfinder.createMove(cmd, Pathfinder.directMovementAngle)

		return
	end

	if not Pathfinder.isOnValidPath() then
		Pathfinder.ejectFromLadder(cmd)

		return
	end

	if not Pathfinder.cachedLastRequest then
		Pathfinder.ejectFromLadder(cmd)

		return
	end

	local pathfinderOptions = Pathfinder.cachedLastRequest.options

	-- Not sure why this is necessary. Don't know how the path is getting to the end
	-- but the Path itself still exists.
	if not Pathfinder.path or not Pathfinder.path.node then
		Pathfinder.clearActivePath()

		return
	end

	local currentNode = Pathfinder.path.node
	local previousNode = Pathfinder.path.nodes[Pathfinder.path.idx - 1]

	if not pathfinderOptions.isAllowedToTraverseInactives and not currentNode.isActive then
		Pathfinder.retryLastRequest()

		return
	end

	local clientOrigin = LocalPlayer:getOrigin()
	local isClientOnGround = LocalPlayer:getFlag(Player.flags.FL_ONGROUND)
	local clientSpeed = LocalPlayer:m_vecVelocity():getMagnitude()
	local angleToNode = clientOrigin:getAngle(currentNode.pathOrigin)
	local distance2d = clientOrigin:getDistance2(currentNode.pathOrigin)
	local distanceToGoal = clientOrigin:getDistance(Pathfinder.path.endGoal.origin)
	local isGoal = currentNode:is(Pathfinder.path.endGoal)
	local isAllowedToRandomlyJump = Pathfinder.isAllowedToRandomlyJump

	Pathfinder.isAllowedToRandomlyJump = false

	if currentNode.isDuck then
		if previousNode and previousNode.isDuck then
			Pathfinder.moveDuckTimer:restart()
		elseif distance2d < 35 then
			Pathfinder.moveDuckTimer:restart()
		end
	end

	if Pathfinder.moveDuckTimer:isNotElapsedThenStop(1) then
		Pathfinder.duck()
	end

	if isGoal and pathfinderOptions.isCounterStrafingOnGoal and distance2d < pathfinderOptions.goalReachedRadius * 2 then
		Pathfinder.counterStrafe()
	end

	local isAllowedToCreateMove = true

	if currentNode.isJump then
		local jumpHandlers = {
			[Node.traverseClamber.__classid] = function()
				if distance2d > 20 then
					return
				end

				if not Pathfinder.moveOnGroundTimer:isElapsed(0.1) then
					return
				end

				if currentNode.origin.z - clientOrigin.z > 25 then
					if Pathfinder.moveObstructedTimer:isElapsed(0.16) then
						Pathfinder.duck()
					end

					if Pathfinder.moveObstructedTimer:isElapsed(0.3) and clientSpeed < 50 then
						Pathfinder.jump()
						Pathfinder.incrementPath("clamber")
					end
				else
					Pathfinder.incrementPath("clamber too low)")
				end
			end,
			[Node.traverseClimb.__classid] = function()
				if distance2d > 50 then
					return
				end

				if not Pathfinder.moveOnGroundTimer:isElapsed(0.1) then
					return
				end

				if currentNode.origin.z - clientOrigin.z > 25 then
					if Pathfinder.moveObstructedTimer:isElapsed(0.01) then
						Pathfinder.duck()
					end

					if Pathfinder.moveObstructedTimer:isElapsed(0.05) and clientSpeed < 75 then
						Pathfinder.jump()

						Pathfinder.incrementPath("climb")
					end
				else
					Pathfinder.incrementPath("climb too low")
				end
			end,
			[Node.traverseVault.__classid] = function()
				if distance2d > 25 then
					return
				end

				if not Pathfinder.moveOnGroundTimer:isElapsed(0.1) then
					return
				end

				Pathfinder.jump()
				Pathfinder.incrementPath("vault")
			end,
			[Node.traverseGap.__classid] = function()
				if distance2d < 40 then
					Pathfinder.isWalking = false
				end

				local distance = 25

				if not isClientOnGround then
					distance = 64
				end

				if distance2d > distance then
					return
				end

				isAllowedToCreateMove = false

				Pathfinder.jump()
				Pathfinder.incrementPath("gap")

				-- Skip a double-gap node.
				if previousNode and previousNode:is(Node.traverseGap) then
					Pathfinder.incrementPath("gap next")
				end
			end,
			[Node.traverseDrop.__classid] = function()
				if distance2d > 20 then
					return
				end

				Pathfinder.incrementPath("drop")
			end
		}

		if Pathfinder.isAllowedToJump then
			jumpHandlers[currentNode.__classid]()
		end
	elseif currentNode:is(Node.traverseBreakObstacle) then
		Pathfinder.detectObstacles(currentNode)

		if not Pathfinder.isObstructedByObstacle and distance2d < 40 then
			Pathfinder.incrementPath("obstacle broken")
		end
	elseif currentNode:is(Node.traverseDoor) then
		Pathfinder.detectDoors(currentNode)

		if not Pathfinder.isObstructedByDoor and distance2d < 30 then
			Pathfinder.incrementPath("door open")
		end
	elseif currentNode:is(Node.traverseLadderBottom) then
		if distance2d < 55 then
			Pathfinder.isAscendingLadder = true
		end

		if distance2d < 20 then
			isAllowedToCreateMove = false

			if not LocalPlayer:isMoveType(Player.moveType.LADDER) then
				Pathfinder.createMove(cmd, currentNode.direction)

				cmd.in_jump = true
			else
				-- Set cmds manually to exactly the values needed to climb.
				cmd.forwardmove = 450
				cmd.in_forward = true
				cmd.in_back = false
				cmd.sidemove = 0
				cmd.in_moveleft = false
				cmd.in_moveright = false
				cmd.in_speed = false
				cmd.in_duck = false
				cmd.in_use = false
			end
		end

		local ladderTop = Pathfinder.path.nodes[Pathfinder.path.idx + 1]
		local zDelta = clientOrigin.z - ladderTop.origin.z

		if zDelta > 0 then
			-- Pass over both ladder nodes as we held onto the bottom.
			Pathfinder.incrementPath("ascend ladder")
			Pathfinder.incrementPath("ascend ladder")
		end
	elseif currentNode:is(Node.traverseLadderTop) then
		if distance2d < 20 then
			isAllowedToCreateMove = false

			if not LocalPlayer:isMoveType(Player.moveType.LADDER) then
				Pathfinder.createMove(cmd, currentNode.direction)
			else
				-- Set cmds manually to exactly the values needed to climb.
				cmd.forwardmove = 450
				cmd.in_forward = true
				cmd.in_back = false
				cmd.sidemove = 0
				cmd.in_moveleft = false
				cmd.in_moveright = false
				cmd.in_speed = false
				cmd.in_duck = false
				cmd.in_use = false

				Pathfinder.isDescendingLadder = true

				local ladderBottom = Pathfinder.path.nodes[Pathfinder.path.idx + 1]
				local zDelta = clientOrigin.z - ladderBottom.origin.z

				if zDelta < 150 then
					cmd.in_jump = true

					-- Pass over both ladder nodes as we held onto the top.
					Pathfinder.incrementPath("descend ladder")
					Pathfinder.incrementPath("descend ladder")
				end
			end
		end
	elseif currentNode:is(Node.traverseRecorderStart) then
		--- @type NodeTraverseRecorderStart
		local recorderStart = currentNode
		local nextNode = Pathfinder.path.nodes[Pathfinder.path.idx + 1]

		-- We do not want to use a recorder if the next node is not the end of the recorder.
		if nextNode and recorderStart.endPoint.id == nextNode.id then
			if not Pathfinder.isReadyToReplayMovementRecording and distance2d > 20 then
				Pathfinder.movementRecorderTimer:stop()
			end

			if not Pathfinder.isReadyToReplayMovementRecording and distance2d < 10 then
				Pathfinder.counterStrafe()
				Pathfinder.walk()
			end

			if distance2d < 2 then
				Pathfinder.movementRecorderTimer:ifPausedThenStart()

				if Pathfinder.movementRecorderTimer:isElapsed(0.2) then
					Pathfinder.isReadyToReplayMovementRecording = true
				end
			else
				Pathfinder.movementRecorderTimer:stop()
			end

			if distance2d < 70 then
				Pathfinder.movementRecorderAngle = currentNode.direction
			end

			if Pathfinder.isReadyToReplayMovementRecording then
				--- @type NodeTraverseRecorderStart
				local node = currentNode
				local tick = node:getNextTick()

				if tick then
					Pathfinder.isReplayingMovementRecording = true
					Pathfinder.movementRecorderAngle = Angle:new(tick.pitch, tick.yaw)

					for field, value in pairs(tick) do
						cmd[field] = value
					end
				else
					Pathfinder.isReadyToReplayMovementRecording = false

					Pathfinder.incrementPath("finish recorder")
					Pathfinder.incrementPath("finish recorder")
				end

				return
			end
		elseif distance2d < 20 then
			Pathfinder.incrementPath("skip recorder")
		end
	else
		local clearDistance

		if currentNode:is(NodeType.goal) then
			clearDistance = pathfinderOptions.goalReachedRadius
		else
			clearDistance = isClientOnGround and 20 or 40
		end

		if distance2d < clearDistance then
			Pathfinder.incrementPath("pass node")
		end
	end

	if isAllowedToCreateMove then
		Pathfinder.createMove(cmd, angleToNode)
		Pathfinder.avoidGeometry(cmd)
		Pathfinder.avoidTeammates(cmd)
	end

	-- Randomly jump, because humans do that sometimes.
	if Pathfinder.randomJumpIntervalTimer:isElapsedThenRestart(Pathfinder.randomJumpIntervalTime)
		and isAllowedToRandomlyJump
		and not AiUtility.isClientThreatenedMinor
		and distanceToGoal > 1000
	then
		Pathfinder.randomJumpIntervalTime = Math.getRandomFloat(1, 90)

		Pathfinder.jump()
	end

	-- Handle any changes to movement options as a result of the path.
	Pathfinder.handleMovementOptions(cmd)

	if AiUtility.gameRules:m_bFreezePeriod() ~= 1 then
		if clientSpeed < 64 then
			Pathfinder.moveObstructedTimer:ifPausedThenStart()
		else
			Pathfinder.moveObstructedTimer:stop()
		end

		if Pathfinder.moveObstructedTimer:isElapsedThenStop(1.5) then
			if MenuGroup.enableMovement:get()  then
				Logger.console(Logger.WARNING, Localization.pathfinderObstructed)

				Pathfinder.retryLastRequest()
			else
				Logger.console(Logger.WARNING, Localization.pathfinderMovementDisabled)
			end

		end
	end

	-- We've reached the end of the path.
	if not Pathfinder.path.node then
		if pathfinderOptions.onReachedGoal then
			pathfinderOptions.onReachedGoal()
		end

		Pathfinder.clearActivePath()
	end
end

--- @return void
function Pathfinder.resetMoveParameters()
	Pathfinder.directMovementAngle = nil
	Pathfinder.isAllowedToDuck = true
	Pathfinder.isAllowedToJump = true
	Pathfinder.isAllowedToMove = true
	Pathfinder.isAllowedToWalk = true
	Pathfinder.isCounterStrafing = false
	Pathfinder.isDucking = false
	Pathfinder.isJumping = false
	Pathfinder.isWalking = false
end

--- @return void
function Pathfinder.incrementPath(note)
	local lastNode = Pathfinder.path.node

	if Debug.isLoggingPathfinderMoveOntoNextNode then
		Logger.console(Logger.INFO, "Incremented path (%s): [%i] %s.", note, lastNode.id, lastNode.name)
	end

	if lastNode then
		lastNode:onIsPassed(Nodegraph)
	end

	Pathfinder.path.idx = Pathfinder.path.idx + 1

	local nextNode = Pathfinder.path.nodes[Pathfinder.path.idx]

	Pathfinder.path.node = nextNode

	if nextNode then
		nextNode:onIsNext(Nodegraph, Pathfinder.path)
	end

	Pathfinder.isAscendingLadder = false
	Pathfinder.isDescendingLadder = false
end

--- @param cmd SetupCommandEvent
--- @return void
function Pathfinder.ejectFromLadder(cmd)
	if LocalPlayer:getMoveType() == Player.moveType.LADDER then
		cmd.in_jump = true
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function Pathfinder.handleMovementOptions(cmd)
	local clientOrigin = LocalPlayer:getOrigin()

	if Pathfinder.isAllowedToDuck and Pathfinder.isDucking then
		cmd.in_duck = true
	end

	if Pathfinder.isAllowedToJump and Pathfinder.isJumping then
		cmd.in_jump = true
	end

	for _, inferno in Entity.find("CInferno") do
		if clientOrigin:getDistance(inferno:m_vecOrigin()) < 300 then
			return
		end
	end

	if Pathfinder.isCounterStrafing then
		MenuGroup.standaloneQuickStopRef:set(true)
	else
		MenuGroup.standaloneQuickStopRef:set(false)
	end

	if Pathfinder.isAllowedToWalk and Pathfinder.isWalking then
		cmd.in_speed = true
	end
end

--- @param node NodeTraverseBreakObstacle
--- @return void
function Pathfinder.detectObstacles(node)
	-- Prevent team damage if possible.
	if Pathfinder.isObstructedByTeammate then
		return
	end

	local detectionOrigin = node.origin:clone():offset(0, 0, 40)
	local detectionOffset = detectionOrigin + node.direction:getForward() * 64
	local trace = Trace.getLineToPosition(detectionOrigin, detectionOffset, AiUtility.traceOptionsPathfinding, "Pathfinder.detectObstacles<FindObstacle>")

	if trace.isIntersectingGeometry then
		Pathfinder.isObstructedByObstacle = true
	end
end

--- @param node NodeTraverseDoor
--- @return void
function Pathfinder.detectDoors(node)
	local detectionOrigin = node.origin:clone():offset(0, 0, 64)
	local detectionOffset = detectionOrigin + node.direction:getForward() * 64
	local trace = Trace.getLineToPosition(detectionOrigin, detectionOffset, AiUtility.traceOptionsPathfinding, "Pathfinder.detectDoors<FindDoor>")

	if trace.isIntersectingGeometry then
		Pathfinder.isObstructedByDoor = true
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function Pathfinder.avoidTeammates(cmd)
	if not Pathfinder.lastMovementAngle then
		return
	end

	if AiUtility.gameRules:m_bFreezePeriod() == 1 then
		return
	end

	local isBlocked = false
	local clientOrigin = LocalPlayer:getOrigin()
	local collisionOrigin = clientOrigin:clone():offset(0, 0, 36) + (Pathfinder.lastMovementAngle:clone():set(0):getForward() * 40)
	local collisionBounds = collisionOrigin:getBounds(Vector3.align.CENTER, 20, 20, 40)
	--- @type Player
	local blockingTeammate

	for _, teammate in pairs(AiUtility.teammates) do
		if teammate:getOrigin():offset(0, 0, 32):isInBounds(collisionBounds) then
			isBlocked = true

			blockingTeammate = teammate

			break
		end
	end

	if not isBlocked then
		Pathfinder.isAvoidingTeammate = false
		Pathfinder.avoidTeammatesAngle = nil

		return
	end

	Pathfinder.isObstructedByTeammate = true

	if not Pathfinder.avoidTeammatesAngle then
		Pathfinder.avoidTeammatesAngle = LocalPlayer.getEyeOrigin():getAngle(blockingTeammate:getEyeOrigin())
	end

	Pathfinder.avoidTeammatesTimer:ifPausedThenStart()

	if Pathfinder.avoidTeammatesTimer:isElapsedThenStop(Pathfinder.avoidTeammatesDuration) then
		Pathfinder.avoidTeammatesDirection = Math.getChance(2) and "Left" or "Right"
		Pathfinder.avoidTeammatesDuration = Math.getRandomFloat(0.66, 1)
	end

	local directionMethod = string.format("get%s", Pathfinder.avoidTeammatesDirection)
	local eyeOrigin = LocalPlayer.getEyeOrigin()
	local movementAngles = Pathfinder.lastMovementAngle
	local directionOffset = eyeOrigin + movementAngles[directionMethod](movementAngles) * 150

	if not Pathfinder.isAllowedToAvoidTeammates then
		Pathfinder.isAllowedToAvoidTeammates = true

		return
	end

	Pathfinder.isAvoidingTeammate = true
	Pathfinder.isAllowedToRandomlyJump = false

	Pathfinder.createMove(cmd, eyeOrigin:getAngle(directionOffset))
end

--- @param cmd SetupCommandEvent
--- @return void
function Pathfinder.avoidGeometry(cmd)
	if not Pathfinder.lastMovementAngle then
		return false
	end

	local isDucking = LocalPlayer:getFlag(Player.flags.FL_DUCKING)
	local clientOrigin = LocalPlayer:getOrigin()
	local origin = clientOrigin:offset(0, 0, 18)
	local boundsTraceOrigin = clientOrigin:clone():offset(0, 0, 36)
	local moveAngle = Pathfinder.lastMovementAngle
	local moveAngleForward = moveAngle:getForward()
	local boundsOrigin = origin + moveAngleForward * 20
	local bounds = Vector3:newBounds(Vector3.align.UP, 8, 8, isDucking and 18 or 27)
	local directions = {
		Left = Angle.getLeft,
		Right = Angle.getRight
	}

	--- @type Angle
	local avoidAngle
	local clipCount = 0

	for _, direction in pairs(directions) do
		--- @type Vector3
		local checkDirection = direction(moveAngle)
		local boundsTraceOffset = boundsOrigin + checkDirection * 20
		local trace = Trace.getHullToPosition(boundsTraceOrigin, boundsTraceOffset, bounds, AiUtility.traceOptionsPathfinding, "Pathfinder.avoidGeometry<FindClip>")

		if trace.isIntersectingGeometry then
			local avoidDirection = clientOrigin - checkDirection * 8

			avoidAngle = clientOrigin:getAngle(avoidDirection)
			clipCount = clipCount + 1
		end
	end

	if avoidAngle and clipCount ~= 2 then
		Pathfinder.createMove(cmd, avoidAngle)

		Pathfinder.isAllowedToRandomlyJump = false

		return true
	end

	return false
end

--- @param cmd SetupCommandEvent
--- @return void
function Pathfinder.airDuck(cmd)
	if LocalPlayer:getFlag(Player.flags.FL_ONGROUND) then
		return
	end

	if LocalPlayer:m_vecVelocity().z > 0 then
		cmd.in_duck = true
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function Pathfinder.createMoveForward(cmd)
	if not MenuGroup.enableMovement:get() then
		return
	end

	cmd.forwardmove = 450
	cmd.in_forward = true
end

--- @param cmd SetupCommandEvent
--- @param angle Angle
--- @return void
function Pathfinder.createMove(cmd, angle)
	if not MenuGroup.enableMovement:get() then
		return
	end

	angle:set(0)

	Pathfinder.lastMovementAngle = angle

	if not Config.isEmulatingRealUserInput then
		cmd.move_yaw = angle.y
		cmd.forwardmove = 450

		return
	end

	local directions = {
		[0] = function()
			cmd.forwardmove = 450
			cmd.in_forward = true
		end,
		[-45] = function()
			cmd.forwardmove = 450
			cmd.sidemove = 450
			cmd.in_forward = true
			cmd.in_moveright = true
		end,
		[-90] = function()
			cmd.sidemove = 450
			cmd.in_moveright = true
		end,
		[-135] = function()
			cmd.forwardmove = -450
			cmd.sidemove = 450
			cmd.in_moveright = true
			cmd.in_back = true
		end,
		[180] = function()
			cmd.forwardmove = -450
			cmd.in_back = true
		end,
		[135] = function()
			cmd.forwardmove = -450
			cmd.sidemove = -450
			cmd.in_back = true
			cmd.in_moveleft = true
		end,
		[90] = function()
			cmd.sidemove = -450
			cmd.in_moveleft = true
		end,
		[45] = function()
			cmd.forwardmove = 450
			cmd.sidemove = -450
			cmd.in_forward = true
			cmd.in_moveleft = true
		end
	}

	--- @type fun(): void
	local closestCallback
	local lowestDelta = math.huge

	for yaw, callback in pairs(directions) do
		local directionAngle = Angle:new(0, yaw + cmd.move_yaw):normalize()
		local deltaAngle = directionAngle:getAbsDiff(angle)

		if deltaAngle.y < lowestDelta then
			lowestDelta = deltaAngle.y
			closestCallback = callback
		end
	end

	if closestCallback then
		closestCallback()
	end
end

return Nyx.class("Pathfinder", Pathfinder)
--}}}
