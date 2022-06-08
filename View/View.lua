--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local PerlinNoise = require "gamesense/Nyx/v1/Api/PerlinNoise"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local NodeType = require "gamesense/Nyx/v1/Dominion/Traversal/Node/NodeType"
local ViewNoiseType = require "gamesense/Nyx/v1/Dominion/View/ViewNoiseType"
--}}}

--{{{ View
--- @class View : Class
--- @field aimPunchAngles Angle
--- @field currentNoise ViewNoise
--- @field isAllowedToWatchCorners boolean
--- @field isCrosshairSmoothed boolean
--- @field isCrosshairUsingVelocity boolean
--- @field isEnabled boolean
--- @field isRcsEnabled boolean
--- @field isViewLocked boolean
--- @field lastCameraAngles Angle
--- @field lastLookAtLocationOrigin Vector3
--- @field lookAtAngles Angle
--- @field lookState string
--- @field lookSpeed number
--- @field lookSpeedDelay Timer
--- @field lookSpeedDelayed number
--- @field lookSpeedDelayMax number
--- @field lookSpeedDelayMin number
--- @field lookSpeedDelayTimer Timer
--- @field lookSpeedIdeal number
--- @field lookSpeedModifier number
--- @field lookState string
--- @field lookStateCached string
--- @field nodegraph Nodegraph
--- @field noise ViewNoiseType
--- @field overrideViewAngles Angle
--- @field pitchFine number
--- @field pitchSoft number
--- @field recoilControl number
--- @field targetViewAngles Angle
--- @field useCooldown Timer
--- @field velocity Angle
--- @field velocityBoundary number
--- @field velocityGainModifier number
--- @field velocityResetSpeed number
--- @field viewAngles Angle
--- @field viewPitchOffset number
--- @field yawFine number
--- @field yawSoft number
--- @field watchCornerTimer Timer
--- @field watchCornerOrigin Vector3
local View = {
	noise = ViewNoiseType
}

--- @return void
function View.__setup()
	View.initFields()
	View.initMenu()
end

--- @return void
function View.initFields()
	View.aimPunchAngles = Angle:new(0, 0)
	View.isCrosshairUsingVelocity = false
	View.lastCameraAngles = Client.getCameraAngles()
	View.lookAtAngles = Client.getCameraAngles()
	View.lookSpeed = 0
	View.lookSpeedDelay = Math.getRandomFloat(0.25, 0.6)
	View.lookSpeedDelayTimer = Timer:new():start()
	View.lookSpeedDelayed = 0
	View.lookSpeedModifier = 1.2
	View.recoilControl = 2
	View.useCooldown = Timer:new():start()
	View.velocity = Angle:new()
	View.velocityBoundary = 20
	View.velocityGainModifier = 0.7
	View.velocityResetSpeed = 100
	View.viewAngles = Client.getCameraAngles()
	View.viewPitchOffset = 0
	View.pitchFine = 0
	View.pitchSoft = 0
	View.yawFine = 0
	View.yawSoft = 0
	View.lookSpeedIdeal = 0
	View.watchCornerTimer = Timer:new():startThenElapse()

	View.setNoiseType(ViewNoiseType.none)
end

--- @return void
function View.initMenu()
	MenuGroup.enableMouseControl = MenuGroup.group:addCheckbox(" > Enable Mouse Control"):addCallback(function(item)
		View.isEnabled = item:get()
	end):setParent(MenuGroup.master)
end

--- @return void
function View.setViewAngles()
	if not View.isEnabled then
		return
	end

	-- Match camera angles to AI view angles.
	if View.viewAngles then
		Client.setCameraAngles(View.lookAtAngles)
	end

	if View.lookState ~= View.lookStateCached then
		if Debug.isLoggingLookState then
			Logger.console(-1, "New mouse control '%s'.", View.lookState)
		end

		View.delayMovement()

		View.lookStateCached = View.lookState
	end

	View.setDelayedLookSpeed()

	-- View angles we want to look at.
	-- It's overriden by AI behaviours, look ahead of the active path, or rest.
	--- @type Angle
	local idealViewAngles = Client.getCameraAngles()
	local smoothingCutoffThreshold = 0

	if View.overrideViewAngles then
		-- AI wants to look at something particular.
		View.setIdealOverride(idealViewAngles)

		smoothingCutoffThreshold = 0.6
	elseif Pathfinder.isOk() then
		-- Perform generic look behaviour.
		View.setIdealLookAhead(idealViewAngles)
		-- Watch corners enemies are actually occluded by.
		View.setIdealWatchCorner(idealViewAngles)

		smoothingCutoffThreshold = 1
	else
		View.lookState = "None"
	end

	--- @type Angle
	local targetViewAngles = idealViewAngles

	-- Apply velocity on angles. Creates the effect of "over-shooting" the target point
	-- when moving the mouse far and fast.
	View.setTargetVelocity(targetViewAngles)

	-- Makes the crosshair curve.
	View.setTargetCurve(targetViewAngles)

	-- Makes the crosshair have noise.
	View.setTargetNoise(targetViewAngles)

	if View.isCrosshairSmoothed then
		View.isCrosshairSmoothed = false
	else
		local cameraAngles = Client.getCameraAngles()

		-- Prevent smoothing all the way down to 0 delta.
		-- Real humans don't smoothly move their mouse directly and precisely onto the exact point
		-- in space they want to look at. It is approximate and falls just short. 0.5 yaw/pitch delta
		-- is accurate, but cuts off just before the mouse will appear to be literally lerping to a point.
		if cameraAngles:getMaxDiff(targetViewAngles) < smoothingCutoffThreshold then
			return
		end
	end

	-- Lerp the real view angles.
	View.interpolateViewAngles(targetViewAngles)
end

--- @return void
function View.delayMovement()
	if View.lookSpeedDelayMax == 0 then
		return
	end

	View.lookSpeedDelayTimer:restart()
	View.lookSpeedDelayed = Math.getClamped(View.lookSpeedDelayed - 30 * Time.getDelta(), 0, View.lookSpeedIdeal)
	View.lookSpeedDelay = Math.getRandomFloat(View.lookSpeedDelayMin, View.lookSpeedDelayMax)
end

--- @return void
function View.setDelayedLookSpeed()
	if View.lookSpeedDelayMax == 0 then
		View.lookSpeed = View.lookSpeedIdeal

		return
	end

	if View.lookSpeedDelayTimer:isElapsed(View.lookSpeedDelay) then
		View.lookSpeedDelayed = Math.getClamped(View.lookSpeedDelayed + 40 * Time.getDelta(), 0, View.lookSpeedIdeal)
	end

	View.lookSpeed = View.lookSpeedDelayed
end

--- @param targetViewAngles Angle
--- @return void
function View.interpolateViewAngles(targetViewAngles)
	targetViewAngles:normalize()

	View.viewAngles:lerpTickrate(targetViewAngles, math.min(20, View.lookSpeed * View.lookSpeedModifier))
end

--- @param noise ViewNoise
--- @return void
function View.setNoiseType(noise)
	View.currentNoise = noise

	if not View.currentNoise then
		View.currentNoise = ViewNoiseType.none
	end
end

--- @param targetViewAngles Angle
--- @return void
function View.setTargetNoise(targetViewAngles)
	-- Noise is NONE or not worth calculating.
	if View.currentNoise.timeExponent == 0 then
		return
	end

	-- Randomise when and for how long the noise is applied to the mouse.
	if View.currentNoise.isRandomlyToggled then
		if View.currentNoise.toggleIntervalTimer:isElapsedThenStop(View.currentNoise.toggleInterval) then
			View.currentNoise.toggleInterval = Math.getRandomFloat(View.currentNoise.toggleIntervalMin, View.currentNoise.toggleIntervalMax)

			View.currentNoise.togglePeriodTimer:start()
		end

		if View.currentNoise.togglePeriodTimer:isStarted() then
			if not View.currentNoise.togglePeriodTimer:isElapsed(View.currentNoise.togglePeriod) then
				targetViewAngles:set(targetViewAngles.p + View.pitchFine + View.pitchSoft, targetViewAngles.y + View.yawFine + View.yawSoft)
			else
				View.currentNoise.togglePeriod = Math.getRandomFloat(View.currentNoise.togglePeriodMin, View.currentNoise.togglePeriodMax)

				View.currentNoise.togglePeriodTimer:stop()
				View.currentNoise.toggleIntervalTimer:start()
			end
		end

		return
	end

	-- Scale the noise based on velocity.
	local velocityMod = 1

	-- Change between "in movement" and "standing still" noise parameters.
	if View.currentNoise.isBasedOnVelocity then
		local velocity = LocalPlayer:m_vecVelocity():getMagnitude()

		velocityMod = Math.getClamped(Math.getFloat(5 + velocity, 450) * 1, 0, 450)
	end

	-- How intense the noise is.
	local timeExponent = Time.getRealtime() * View.currentNoise.timeExponent

	-- High frequency, low amplitude.
	View.pitchFine = PerlinNoise(
		View.currentNoise.pitchFineX * timeExponent,
		View.currentNoise.pitchFineY * timeExponent,
		View.currentNoise.pitchFineZ * timeExponent
	) * 2 * velocityMod

	-- Low frequency, high amplitude.
	View.pitchSoft = PerlinNoise(
		View.currentNoise.pitchSoftX * timeExponent,
		View.currentNoise.pitchSoftY * timeExponent,
		View.currentNoise.pitchSoftZ * timeExponent
	) * 10 * velocityMod

	-- High frequency, low amplitude.
	View.yawFine = PerlinNoise(
		View.currentNoise.yawFineX * timeExponent,
		View.currentNoise.yawFineY * timeExponent,
		View.currentNoise.yawFineZ * timeExponent
	) * 2 * velocityMod

	-- Low frequency, high amplitude.
	View.yawSoft = PerlinNoise(
		View.currentNoise.yawSoftX * timeExponent,
		View.currentNoise.yawSoftY * timeExponent,
		View.currentNoise.yawSoftZ * timeExponent
	) * 10 * velocityMod

	targetViewAngles:set(targetViewAngles.p + View.pitchFine + View.pitchSoft, targetViewAngles.y + View.yawFine + View.yawSoft)
end

--- @param targetViewAngles Angle
--- @return void
function View.setTargetVelocity(targetViewAngles)
	if not View.isCrosshairUsingVelocity then
		View.isCrosshairUsingVelocity = false

		return
	end

	local cameraAngles = Client.getCameraAngles()

	-- Velocity increase is the difference between the last time we checked the camera angles and now.
	View.velocity = View.velocity + View.lastCameraAngles:getDiff(cameraAngles) * View.velocityGainModifier
	View.lastCameraAngles = cameraAngles

	-- Clamp the velocity within boundary.
	View.velocity.p = Math.getClamped(View.velocity.p, -View.velocityBoundary, View.velocityBoundary)
	View.velocity.y = Math.getClamped(View.velocity.y, -View.velocityBoundary, View.velocityBoundary)

	-- Reset the velocity to 0,0 over time.
	View.velocity:approach(Angle:new(), View.velocityResetSpeed)

	-- Velocity sine. This should make the over-swing become non-parallel to the aim target.
	local velocitySine = Angle:new(Animate.sine(0, Math.getClamped(View.velocity:getMagnitude() * 0.5, -8, 8), 1), 0)

	targetViewAngles:setFromAngle(targetViewAngles + (View.velocity + velocitySine))
end

--- @param targetViewAngles Angle
--- @return void
function View.setTargetCurve(targetViewAngles)
	-- Sine wave float the angles.
	local floatPitch = Animate.sine(0, 50, 5)
	local floatYaw = Animate.sine(0, 50, 2)

	-- Get the absolute difference of the angles.
	local deltaPitch = math.abs(targetViewAngles.p - View.viewAngles.p)
	local deltaYaw = math.abs(targetViewAngles.p - View.viewAngles.p)

	-- Scale the floating effect based on the difference.
	local modPitch = Math.getClamped(Math.getFloat(deltaPitch, 180), 0, 1)
	local modYaw = Math.getClamped(Math.getFloat(deltaYaw, 50), 0, 1)

	targetViewAngles:set(
		targetViewAngles.p + floatPitch * modPitch,
		targetViewAngles.y + floatYaw * modYaw
	)
end

--- @param idealViewAngles Angle
--- @return void
function View.setIdealOverride(idealViewAngles)
	idealViewAngles:setFromAngle(View.overrideViewAngles)
end

--- @param idealViewAngles Angle
--- @return void
function View.setIdealLookAhead(idealViewAngles)
	local currentNode = Pathfinder.path.node

	if Pathfinder.isAscendingLadder then
		idealViewAngles:setFromAngle(currentNode.direction:clone():set(-45))

		View.lookState = "View generic"
		View.lookSpeedIdeal = 6
		View.lookSpeedDelayMin = 0
		View.lookSpeedDelayMax = 0

		return
	elseif Pathfinder.isDescendingLadder then
		idealViewAngles:setFromAngle(currentNode.direction:clone():set(45))

		View.lookState = "View generic"
		View.lookSpeedIdeal = 6
		View.lookSpeedDelayMin = 0
		View.lookSpeedDelayMax = 0

		return
	end

	--- @type NodeTypeBase
	local lookAheadNode

	-- How far in the path to look ahead.
	local lookAheadTo = 4

	local i = 0

	-- Select a node ahead in the path, and look closer until we find a valid node.
	while not lookAheadNode and lookAheadTo do
		lookAheadNode = Pathfinder.path.nodes[Pathfinder.path.idx + lookAheadTo]

		lookAheadTo = lookAheadTo - 1

		i = i + 1

		if i > 50 then
			error("Client freeze prevention (View.setIdealLookAhead).")
		end
	end

	-- A valid node was found.
	if not lookAheadNode then
		return
	end

	-- Do not look at last node.
	if lookAheadTo == 0 then
		return
	end

	local isLookingDirectlyAhead = false

	if Pathfinder.path.node.isJump then
		isLookingDirectlyAhead = true
	end

	local previousNode = Pathfinder.path.nodes[Pathfinder.path.idx - 1]

	if previousNode and previousNode.isJump then
		isLookingDirectlyAhead = true
	end

	-- Look in direction of jumps to increase accuracy.
	if isLookingDirectlyAhead then
		local nextNode = Pathfinder.path.nodes[Pathfinder.path.idx + 1]

		if nextNode then
			lookAheadNode = nextNode
		end
	end

	local lookOrigin = lookAheadNode.origin:clone()

	-- We want to look roughly head height of the goal.
	lookOrigin:offset(0, 0, 46)

	-- Generate our look ahead view angles.
	idealViewAngles:setFromAngle(Client.getEyeOrigin():getAngle(lookOrigin))

	-- Shake the mouse movement.
	View.setNoiseType(ViewNoiseType.moving)

	View.lookState = "View generic"
	View.lookSpeedIdeal = 6
	View.lookSpeedDelayMin = 0.25
	View.lookSpeedDelayMax = 0.5
end

--- @param idealViewAngles Angle
--- @return void
function View.setIdealWatchCorner(idealViewAngles)
	if not View.isAllowedToWatchCorners then
		View.isAllowedToWatchCorners = true

		return
	end

	-- Force the AI to look at the corner for 1.5 seconds to prevent dithering,
	-- as AiUtility.clientThreatenedFromOrigin is rapidly set and unset.
	if AiUtility.clientThreatenedFromOrigin then
		View.watchCornerOrigin = AiUtility.clientThreatenedFromOrigin

		View.watchCornerTimer:restart()
	end

	if View.watchCornerTimer:isElapsed(1.5) then
		return
	end

	idealViewAngles:setFromAngle(Client.getEyeOrigin():getAngle(View.watchCornerOrigin))

	View.setNoiseType(ViewNoiseType.moving)

	View.lookState = "View generic"
	View.lookSpeedIdeal = 6.5
	View.lookSpeedDelayMin = 0.25
	View.lookSpeedDelayMax = 0.5
end

--- @param cmd SetupCommandEvent
--- @return void
function View.think(cmd)
	if not View.isEnabled then
		return
	end

	if not View.viewAngles then
		return
	end

	local aimPunchAngles = LocalPlayer:m_aimPunchAngle()
	local correctedViewAngles = View.viewAngles:clone()

	if View.isRcsEnabled then
		View.aimPunchAngles = View.aimPunchAngles + (aimPunchAngles - View.aimPunchAngles) * 20 * Time.getDelta()

		correctedViewAngles = (correctedViewAngles - View.aimPunchAngles * View.recoilControl):normalize()
	end

	correctedViewAngles:normalize()

	View.lookAtAngles = correctedViewAngles
	View.overrideViewAngles = nil
	View.isViewLocked = false

	cmd.pitch = correctedViewAngles.p
	cmd.yaw = correctedViewAngles.y

	-- Reset noise. Defaults to none at all.
	View.setNoiseType(ViewNoiseType.none)

	local clientOrigin = LocalPlayer:getOrigin()

	-- Shoot out cover.
	if Pathfinder.isObstructedByObstacle then
		local node = Pathfinder.path.node
		local maxDiff = correctedViewAngles:getMaxDiff(node.direction)

		View.overrideViewAngles = node.direction
		View.lookSpeedIdeal = 4
		View.isViewLocked =  true

		if clientOrigin:getDistance2(node.origin) < 20 and maxDiff < 20 and View.useCooldown:isElapsedThenRestart(0.5) then
			cmd.in_attack = true
		end
	end

	-- Use doors.
	if Pathfinder.isObstructedByDoor then
		local node = Pathfinder.path.node
		local maxDiff = correctedViewAngles:getMaxDiff(node.direction)

		View.overrideViewAngles = node.direction
		View.lookSpeedIdeal = 4
		View.isViewLocked =  true

		if clientOrigin:getDistance2(node.origin) < 20 and maxDiff < 20 and View.useCooldown:isElapsedThenRestart(0.5) then
			cmd.in_use = true
		end
	end
end

--- @param origin Vector3
--- @param speed number
--- @param noise number
--- @return void
function View.lookAtLocation(origin, speed, noise, note)
	if View.isViewLocked then
		return
	end

	View.overrideViewAngles = Client.getEyeOrigin():getAngle(origin)
	View.lookSpeedIdeal = speed
	View.lastLookAtLocationOrigin = origin
	View.lookState = note

	View.setNoiseType(noise or ViewNoiseType.none)
end

--- @param angle Angle
--- @param speed number
--- @param noise number
--- @return void
function View.lookAlongAngle(angle, speed, noise, note)
	if View.isViewLocked then
		return
	end

	View.overrideViewAngles = angle:clone()
	View.lookSpeedIdeal = speed
	View.lastLookAtLocationOrigin = nil
	View.lookState = note

	View.setNoiseType(noise or ViewNoiseType.none)
end

--- @param direction Vector3
--- @param speed number
--- @param noise number
--- @return void
function View.lookInDirection(direction, speed, noise, note)
	if View.isViewLocked then
		return
	end

	View.overrideViewAngles = direction:getAngleFromForward()
	View.lookSpeedIdeal = speed
	View.lastLookAtLocationOrigin = nil
	View.lookState = note

	View.setNoiseType(noise or ViewNoiseType.none)
end

return Nyx.class("View", View)
--}}}
