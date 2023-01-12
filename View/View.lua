--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local PerlinNoise = require "gamesense/Nyx/v1/Api/PerlinNoise"
local SecondOrderDynamics = require "gamesense/Nyx/v1/Api/SecondOrderDynamics"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local ViewNoiseType = require "gamesense/Nyx/v1/Dominion/View/ViewNoiseType"
--}}}

--{{{ View
--- @class View : Class
--- @field aimPunchAngles Angle
--- @field blockMouseControlTimer Timer
--- @field buildup number
--- @field buildupCooldownTime number
--- @field buildupCooldownTimer Timer
--- @field buildupLastAngles Angle
--- @field buildupThreshold number
--- @field currentNoise ViewNoise
--- @field dynamic SecondOrderDynamics
--- @field isAllowedToWatchCorners boolean
--- @field isCrosshairSmoothed boolean
--- @field isCrosshairUsingVelocity boolean
--- @field isEnabled boolean
--- @field isFiringWeapon boolean
--- @field isInUse boolean
--- @field isLookSpeedDelayed boolean
--- @field isRcsEnabled boolean
--- @field isViewLocked boolean
--- @field lastCameraAngles Angle
--- @field lastIdleAngle Angle
--- @field lastLookAtLocationOrigin Vector3
--- @field lookAtAngles Angle
--- @field lookSpeed number
--- @field lookSpeedDelay Timer
--- @field lookSpeedDelayed number
--- @field lookSpeedDelayMax number
--- @field lookSpeedDelayMin number
--- @field lookSpeedDelayTimer Timer
--- @field lookSpeedIdeal number
--- @field lookSpeedModifier number
--- @field lookState string
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
--- @field watchCornerOrigin Vector3
--- @field watchCornerTimer Timer
--- @field yawFine number
--- @field yawSoft number
local View = {
	noise = ViewNoiseType
}

--- @return void
function View.__setup()
	View.initFields()
	View.initMenu()
	View.initEvents()
end

--- @return void
function View.initFields()
	View.aimPunchAngles = Angle:new(0, 0)
	View.isCrosshairUsingVelocity = false
	View.lastCameraAngles = LocalPlayer.getCameraAngles()
	View.lookAtAngles = LocalPlayer.getCameraAngles()
	View.lookSpeed = 0
	View.lookSpeedDelay = Math.getRandomFloat(0.25, 0.6)
	View.lookSpeedDelayTimer = Timer:new():start()
	View.lookSpeedDelayed = 0
	View.lookSpeedModifier = 1.4
	View.recoilControl = 2
	View.useCooldown = Timer:new():startThenElapse()
	View.velocity = Angle:new()
	View.velocityBoundary = 16
	View.velocityGainModifier = 0.55
	View.velocityResetSpeed = 120
	View.viewAngles = LocalPlayer.getCameraAngles()
	View.lastIdleAngle = Angle:new()
	View.viewPitchOffset = 0
	View.pitchFine = 0
	View.pitchSoft = 0
	View.yawFine = 0
	View.yawSoft = 0
	View.lookSpeedIdeal = 0
	View.watchCornerTimer = Timer:new():startThenElapse()
	View.buildup = 0
	View.buildupThreshold = 90
	View.buildupCooldownTime = 0
	View.buildupCooldownTimer = Timer:new():startThenElapse()
	View.blockMouseControlTimer = Timer:new():startThenElapse()

	View.dynamic = SecondOrderDynamics:new(2, 4.4, 0, 0.22, Angle, LocalPlayer.getCameraAngles() or Angle:new())

	View.setNoiseType(ViewNoiseType.none)
end

--- @return void
function View.initEvents()
	Callbacks.setupCommand(function(cmd)
		if not MenuGroup.master:get() or not MenuGroup.enableMouseControl:get() or not MenuGroup.enableAi:get() then
			return
		end

		View.setViewAngles()
		View.think(cmd)
	end, true)

	Callbacks.setupCommand(function(cmd)
		View.resetViewParameters()
	end, false)

	Callbacks.levelInit(function()
		View.blockMouseControlTimer:restart()
	end)

	Callbacks.roundPrestart(function()
		View.blockMouseControlTimer:restart()
	end)
end

--- @return void
function View.initMenu()
	MenuGroup.enableMouseControl = MenuGroup.group:addCheckbox(" > Enable Mouse Control"):addCallback(function(item)
		View.isEnabled = item:get()
	end):setParent(MenuGroup.master)
end

--- @return void
function View.setViewAngles()
	if not View.blockMouseControlTimer:isElapsed(1) then
		local cameraAngles = LocalPlayer.getCameraAngles()

		View.viewAngles = cameraAngles
		View.lookAtAngles = cameraAngles
		View.lastCameraAngles = cameraAngles

		return
	end

	if not View.isEnabled then
		return
	end

	-- Match camera angles to AI view angles.
	if View.viewAngles then
		LocalPlayer.setCameraAngles(View.lookAtAngles)
	end

	-- Apply movement recorder angles.
	-- Immediately exit this logic, so that only the raw recorded angles are applied.
	if Pathfinder.isReplayingMovementRecording then
		View.lookState = "View recorded"

		View.viewAngles:setFromAngle(Pathfinder.movementRecorderAngle)

		return
	end

	if View.lookState ~= View.lookStateCached then
		if Debug.isLoggingLookState then
			Logger.console(Logger.INFO, Localization.viewNewState, View.lookState)
		end

		View.delayMovement()

		View.lookStateCached = View.lookState
	end

	View.setDelayedLookSpeed()

	if not View.isLookSpeedDelayed or Pathfinder.movementRecorderAngle then
		View.lookSpeed = View.lookSpeedIdeal
	end

	-- View angles we want to look at.
	-- It's overriden by AI behaviours, look ahead of the active path, or rest.
	--- @type Angle
	local idealViewAngles = LocalPlayer.getCameraAngles()
	local smoothingCutoffThreshold = 0

	if Pathfinder.isObstructedByObstacle or Pathfinder.isObstructedByDoor then
		-- Remove obstructions in front of the player.
		View.setIdealRemoveObstructions(idealViewAngles)
	elseif Pathfinder.movementRecorderAngle then
		-- If Pathfinder "is replaying" is not true, but this value is set,
		-- then the Pathfinder is about to execute a recorded movement,
		-- and the angle is the starting direction for the movement.
		View.setIdealRecorded(idealViewAngles)
	elseif View.overrideViewAngles then
		-- AI wants to look at something particular.
		View.setIdealOverride(idealViewAngles)

		if LocalPlayer:m_bIsScoped() == 1 then
			smoothingCutoffThreshold = 0.2
		else
			smoothingCutoffThreshold = 0.35

		end
	elseif Pathfinder.isOnValidPath() then
		-- Handle the "buildup" of mouse movement delta that would result in the virtual mouse leaving the mousemat.
		View.handleBuildup()

		if View.buildupCooldownTimer:isElapsed(View.buildupCooldownTime) then
			-- Perform generic look behaviour.
			View.setIdealLookAhead(idealViewAngles)
			-- Watch corners enemies are actually occluded by.
			View.setIdealWatchCorner(idealViewAngles)
		else
			View.setNoiseType(ViewNoiseType.minor)
		end

		smoothingCutoffThreshold = 1
	else
		View.lookState = "None"
	end

	--- @type Angle
	local targetViewAngles = idealViewAngles

	-- Makes the crosshair have noise.
	View.setTargetNoise(targetViewAngles)

	if Config.virtualMouseMode == "rigid" then
		View.setTargetVelocity(targetViewAngles)
	elseif Config.virtualMouseMode == "dynamic" then
		View.setTargetDynamic(targetViewAngles)
	end

	if View.isCrosshairSmoothed then
		View.isCrosshairSmoothed = false
	else
		local cameraAngles = LocalPlayer.getCameraAngles()

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
function View.fireWeapon()
	View.isFiringWeapon = true
end

--- @return void
function View.resetViewParameters()
	View.overrideViewAngles = nil
	View.isFiringWeapon = false
	View.isInUse = false

	-- Reset noise. Defaults to none at all.
	View.setNoiseType(ViewNoiseType.none)
end

--- @return void
function View.blockBuildup()
	View.buildup = 0

	View.buildupCooldownTimer:elapse()
end

--- @return void
function View.handleBuildup()
	local cameraAngles = LocalPlayer.getCameraAngles()

	if not View.buildupLastAngles then
		View.buildupLastAngles = cameraAngles
	end

	local delta = (View.buildupLastAngles - cameraAngles):normalize()

	View.buildup = View.buildup + delta.y
	View.buildupLastAngles = cameraAngles

	if math.abs(View.buildup) < View.buildupThreshold then
		return
	end

	View.buildup = 0
	View.buildupThreshold = Math.getRandomFloat(125,  165)
	View.buildupCooldownTime = Math.getRandomFloat(0.25, 0.8)

	View.buildupCooldownTimer:restart()
end

--- @return void
function View.delayMovement()
	View.lookSpeed = 0
	View.lookSpeedDelayed = 0
	View.lookSpeedDelayTimer:restart()
	View.lookSpeedDelay = Math.getRandomFloat(View.lookSpeedDelayMin, View.lookSpeedDelayMax)
end

--- @return void
function View.setDelayedLookSpeed()
	if View.lookSpeedDelayTimer:isElapsed(View.lookSpeedDelay) then
		View.lookSpeedDelayed = Math.getClamped(View.lookSpeedDelayed + 30 * Time.getDelta(), 0, View.lookSpeedIdeal)
	end

	View.lookSpeed = View.lookSpeedDelayed
end

--- @param targetViewAngles Angle
--- @return void
function View.interpolateViewAngles(targetViewAngles)
	targetViewAngles:normalize()

	View.viewAngles:lerpTickrate(targetViewAngles, View.lookSpeed * View.lookSpeedModifier)
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
				View.setNaturalNoise()

				View.lastIdleAngle = Angle:new(
					View.pitchFine + View.pitchSoft,
					View.yawFine + View.yawSoft
				)
			else
				View.currentNoise.togglePeriod = Math.getRandomFloat(View.currentNoise.togglePeriodMin, View.currentNoise.togglePeriodMax)

				View.currentNoise.togglePeriodTimer:stop()
				View.currentNoise.toggleIntervalTimer:start()
			end
		end

		targetViewAngles:offsetByAngle(View.lastIdleAngle)

		return
	end

	View.setNaturalNoise()

	local angle = Angle:new(
		View.pitchFine + View.pitchSoft,
		View.yawFine + View.yawSoft
	)

	targetViewAngles:offsetByAngle(angle)
end

--- @return void
function View.setNaturalNoise()
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
end

--- @param targetViewAngles Angle
--- @return void
function View.setTargetDynamic(targetViewAngles)
	targetViewAngles:setFromAngle(View.dynamic:thinkNormalize(targetViewAngles))
end

--- @param targetViewAngles Angle
--- @return void
function View.setTargetVelocity(targetViewAngles)
	if not View.isCrosshairUsingVelocity then
		View.isCrosshairUsingVelocity = false

		return
	end

	local cameraAngles = LocalPlayer.getCameraAngles()

	-- Velocity increase is the difference between the last time we checked the camera angles and now.
	View.velocity = View.velocity + View.lastCameraAngles:getDiff(cameraAngles) * View.velocityGainModifier
	View.lastCameraAngles = cameraAngles

	-- Clamp the velocity within boundary.
	View.velocity.p = Math.getClamped(View.velocity.p, -View.velocityBoundary, View.velocityBoundary)
	View.velocity.y = Math.getClamped(View.velocity.y, -View.velocityBoundary, View.velocityBoundary)

	-- Reset the velocity to 0,0 over time.
	View.velocity:approach(Angle:new(), View.velocityResetSpeed)

	-- Velocity sine. This should make the over-swing become non-parallel to the aim target.
	local velocitySine = Angle:new(Animate.sine(0, Math.getClamped(View.velocity:getMagnitude() * 0.33, -3, 3), 1), 0)

	targetViewAngles:setFromAngle(targetViewAngles + (View.velocity + velocitySine))
end

--- @param targetViewAngles Angle
--- @return void
function View.setTargetCurve(targetViewAngles)
	-- Sine wave float the angles.
	local floatPitch = Animate.sine(0, 25, 4)
	local floatYaw = Animate.sine(0, 25, 2)

	-- Get the absolute difference of the angles.
	local deltaPitch = math.abs(targetViewAngles.p - View.viewAngles.p)
	local deltaYaw = math.abs(targetViewAngles.p - View.viewAngles.p)

	-- Scale the floating effect based on the difference.
	local modPitch = Math.getClamped(Math.getFloat(deltaPitch, 180), 0, 1)
	local modYaw = Math.getClamped(Math.getFloat(deltaYaw, 180), 0, 1)

	targetViewAngles:set(
		targetViewAngles.p + floatPitch * modPitch,
		targetViewAngles.y + floatYaw * modYaw
	)
end

--- @param idealViewAngles Angle
--- @return void
function View.setIdealRecorded(idealViewAngles)
	View.lookState = "View recorded pre-execute"
	View.lookSpeedIdeal = 4.6

	idealViewAngles:setFromAngle(Pathfinder.movementRecorderAngle)
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
		idealViewAngles:setFromAngle(currentNode.direction:clone():set(-75))

		View.lookState = "View generic"
		View.lookSpeedIdeal = 6
		View.lookSpeedDelayMin = 0
		View.lookSpeedDelayMax = 0

		return
	elseif Pathfinder.isDescendingLadder then
		idealViewAngles:setFromAngle(currentNode.direction:clone():set(89))

		View.lookState = "View generic"
		View.lookSpeedIdeal = 6
		View.lookSpeedDelayMin = 0
		View.lookSpeedDelayMax = 0

		return
	end

	--- @type NodeTypeBase
	local lookAheadNode
	local lookAheadBy = 4

	if AiUtility.isClientThreatenedMinor
		or (AiUtility.closestEnemy and LocalPlayer:getOrigin():getDistance(AiUtility.closestEnemy:getOrigin()) < 1250)
	then
		lookAheadBy = 2
	end

	-- How far in the path to look ahead.
	local lookAheadTo = lookAheadBy

	local i = 0

	-- Select a node ahead in the path, and look closer until we find a valid node.
	while not lookAheadNode and lookAheadTo do
		lookAheadNode = Pathfinder.path.nodes[Pathfinder.path.idx + lookAheadTo]

		lookAheadTo = lookAheadTo - 1

		i = i + 1

		if i > 50 then
			Logger.console(Logger.ERROR, Localization.viewFreezePrevention)

			return
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
		-- isLookingDirectlyAhead = true todo
	end

	local previousNode = Pathfinder.path.nodes[Pathfinder.path.idx - 1]

	if previousNode and previousNode.isJump then
		-- isLookingDirectlyAhead = true todo
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

	local lookAngle = LocalPlayer.getEyeOrigin():getAngle(lookOrigin)

	if currentNode.isJump then
		lookAngle.p = 0
	end

	-- Generate our look ahead view angles.
	idealViewAngles:setFromAngle(lookAngle)

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

	idealViewAngles:setFromAngle(LocalPlayer.getEyeOrigin():getAngle(View.watchCornerOrigin))

	View.setNoiseType(ViewNoiseType.moving)

	View.lookState = "View generic"
	View.lookSpeedIdeal = 6.5
	View.lookSpeedDelayMin = 0.25
	View.lookSpeedDelayMax = 0.5
end

--- @param idealViewAngles Angle
--- @return void
function View.setIdealRemoveObstructions(idealViewAngles)
	local clientOrigin = LocalPlayer:getOrigin()
	local node = Pathfinder.path.node

	if not node.direction then
		return
	end

	local maxDiff = LocalPlayer.getCameraAngles():getMaxDiff(node.direction)

	idealViewAngles:setFromAngle(node.direction)

	View.lookState = "View generic"
	View.lookSpeedIdeal = 6
	View.lookSpeedDelayMin = 0
	View.lookSpeedDelayMax = 0

	if clientOrigin:getDistance2(node.origin) < 35 and maxDiff < 35 and View.useCooldown:isElapsedThenRestart(1) then
		if Pathfinder.isObstructedByObstacle then
			View.isFiringWeapon = true
		elseif Pathfinder.isObstructedByDoor then
			View.isInUse = true
		end
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function View.think(cmd)
	if not View.blockMouseControlTimer:isElapsed(1) then
		return
	end

	if not View.isEnabled then
		return
	end

	if not View.viewAngles then
		return
	end

	local correctedViewAngles = View.viewAngles:clone()

	if View.isFiringWeapon then
		cmd.in_attack = true
	end

	if View.isInUse then
		cmd.in_use = true
	end

	local aimPunchAngles = LocalPlayer:m_aimPunchAngle()

	if View.isRcsEnabled then
		View.aimPunchAngles = View.aimPunchAngles + (aimPunchAngles - View.aimPunchAngles) * 20 * Time.getDelta()

		correctedViewAngles = (correctedViewAngles - View.aimPunchAngles * View.recoilControl):normalize()
	end

	correctedViewAngles:normalize()

	View.lookAtAngles = correctedViewAngles
	View.isViewLocked = false

	cmd.pitch = correctedViewAngles.p
	cmd.yaw = correctedViewAngles.y
end

--- @param origin Vector3
--- @param speed number
--- @param noise number
--- @return void
function View.lookAtLocation(origin, speed, noise, note)
	if View.isViewLocked then
		return
	end

	View.overrideViewAngles = LocalPlayer.getEyeOrigin():getAngle(origin)
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
