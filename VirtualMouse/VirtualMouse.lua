--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local PerlinNoise = require "gamesense/Nyx/v1/Api/PerlinNoise"
local Player = require "gamesense/Nyx/v1/Api/Player"
local SecondOrderDynamics = require "gamesense/Nyx/v1/Api/SecondOrderDynamics"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiSense = require "gamesense/Nyx/v1/Dominion/Ai/AiSense"
local AiThreats = require "gamesense/Nyx/v1/Dominion/Ai/AiThreats"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Localization = require "gamesense/Nyx/v1/Dominion/Utility/Localization"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local ViewNoiseType = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouseNoiseType"
--}}}

--{{{ VirtualMouse
--- @class VirtualMouse : Class
--- @field activeViewAngles Angle
--- @field blockMouseControlTimer Timer
--- @field buildup number
--- @field buildupCooldownTime number
--- @field buildupCooldownTimer Timer
--- @field buildupLastAngles Angle
--- @field buildupThreshold number
--- @field currentNoise VirtualMouseNoise
--- @field dynamic SecondOrderDynamics
--- @field isAllowedToWatchCorners boolean
--- @field isBlocked boolean
--- @field isCrosshairLerpingToZero boolean
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
--- @field lookAheadOrigin Vector3
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
--- @field noise VirtualMouseNoiseType
--- @field passiveViewAngles Angle
--- @field pathCrosshairPlacement Vector3
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
local VirtualMouse = {
	noise = ViewNoiseType
}

--- @return void
function VirtualMouse.__setup()
	VirtualMouse.initFields()
	VirtualMouse.initMenu()
	VirtualMouse.initEvents()
end

--- @return void
function VirtualMouse.initFields()
	VirtualMouse.aimPunchAngles = Angle:new(0, 0)
	VirtualMouse.isCrosshairUsingVelocity = false
	VirtualMouse.lastCameraAngles = LocalPlayer.getCameraAngles()
	VirtualMouse.lookAtAngles = LocalPlayer.getCameraAngles()
	VirtualMouse.lookSpeed = 0
	VirtualMouse.lookSpeedDelay = Math.getRandomFloat(0.25, 0.6)
	VirtualMouse.lookSpeedDelayTimer = Timer:new():start()
	VirtualMouse.lookSpeedDelayed = 0
	VirtualMouse.lookSpeedModifier = 1.4
	VirtualMouse.recoilControl = 2
	VirtualMouse.useCooldown = Timer:new():startThenElapse()
	VirtualMouse.velocity = Angle:new()
	VirtualMouse.velocityBoundary = 16
	VirtualMouse.velocityGainModifier = 0.55
	VirtualMouse.velocityResetSpeed = 120
	VirtualMouse.viewAngles = LocalPlayer.getCameraAngles()
	VirtualMouse.lastIdleAngle = Angle:new()
	VirtualMouse.viewPitchOffset = 0
	VirtualMouse.pitchFine = 0
	VirtualMouse.pitchSoft = 0
	VirtualMouse.yawFine = 0
	VirtualMouse.yawSoft = 0
	VirtualMouse.lookSpeedIdeal = 10
	VirtualMouse.buildup = 0
	VirtualMouse.buildupThreshold = 90
	VirtualMouse.buildupCooldownTime = 0
	VirtualMouse.buildupCooldownTimer = Timer:new():startThenElapse()
	VirtualMouse.blockMouseControlTimer = Timer:new():startThenElapse()
	VirtualMouse.dynamic = SecondOrderDynamics:new(2, 4.4, 0, 0.22, Angle, LocalPlayer.getCameraAngles() or Angle:new())

	VirtualMouse.setNoiseType(ViewNoiseType.none)
end

--- @return void
function VirtualMouse.initEvents()
	Callbacks.frame(function()
		VirtualMouse.render()
	end)

	Callbacks.setupCommand(function(cmd)
		if not MenuGroup.master:get() or not MenuGroup.enableMouseControl:get() or not MenuGroup.enableAi:get() then
			return
		end

		VirtualMouse.setViewAngles()
		VirtualMouse.think(cmd)
	end, true)

	Callbacks.setupCommand(function(cmd)
		VirtualMouse.resetViewParameters()
	end, false)

	Callbacks.levelInit(function()
		VirtualMouse.blockMouseControlTimer:start()
	end)

	Callbacks.roundPrestart(function()
		VirtualMouse.blockMouseControlTimer:start()
	end)

	Pathfinder.onNewPath(function()
		VirtualMouse.lookAheadOrigin = nil
		VirtualMouse.pathCrosshairPlacement = nil
	end)
end

--- @return void
function VirtualMouse.initMenu()
	MenuGroup.enableMouseControl = MenuGroup.group:addCheckbox(" > Enable Mouse Control"):addCallback(function(item)
		VirtualMouse.isEnabled = item:get()
	end):setParent(MenuGroup.master)
end

--- @return void
function VirtualMouse.render()
	if not Debug.isRenderingVirtualMouse then
		return
	end

	if not LocalPlayer:isAlive() then
		return
	end

	if VirtualMouse.lookState then
		Client.getScreenDimensionsCenter():offset(0, 20):drawSurfaceText(Font.SMALL_BOLD, Color.WHITE, "c", VirtualMouse.lookState)
	end

	if not VirtualMouse.lookAtAngles then
		return
	end

	local lookAtOrigin = LocalPlayer.getEyeOrigin() + VirtualMouse.lookAtAngles:getForward() * 128

	lookAtOrigin:drawCircleOutline(15, 10, Color:hsla(1, 1, 1, 100))

	if VirtualMouse.lookAheadOrigin and not VirtualMouse.activeViewAngles then
		VirtualMouse.lookAheadOrigin:drawCircleOutline(8, 4, Color:hsla(1, 1, 1, 255))
		lookAtOrigin:drawLine(VirtualMouse.lookAheadOrigin, Color:hsla(1, 1, 1, 255))
	end

	if not VirtualMouse.buildupCooldownTimer:isElapsed(VirtualMouse.buildupCooldownTime) then
		lookAtOrigin:drawCircleOutline(20, 4, Color:hsla(0, 0.8, 0.6, 255))
	end
end

--- @return void
function VirtualMouse.setViewAngles()
	if not VirtualMouse.blockMouseControlTimer:isElapsed(1) then
		local cameraAngles = LocalPlayer.getCameraAngles()

		VirtualMouse.viewAngles = cameraAngles
		VirtualMouse.lookAtAngles = cameraAngles
		VirtualMouse.lastCameraAngles = cameraAngles

		return
	end

	if not VirtualMouse.isEnabled then
		return
	end

	-- Match camera angles to AI view angles.
	if VirtualMouse.viewAngles then
		LocalPlayer.setCameraAngles(VirtualMouse.lookAtAngles)
	end

	if VirtualMouse.isBlocked then
		return
	end

	-- Apply movement recorder angles.
	-- Immediately exit this method, so that only the raw recorded angles are applied.
	if Pathfinder.isReplayingMovementRecording then
		VirtualMouse.lookState = "VirtualMouse recorded"

		VirtualMouse.viewAngles:setFromAngle(Pathfinder.movementRecorderAngle)

		return
	end

	-- Switching look state and resetting mouse movement delay.
	if VirtualMouse.lookState ~= VirtualMouse.lookStateCached then
		if Debug.isLoggingLookState then
			Logger.console(Logger.INFO, Localization.viewNewState, VirtualMouse.lookState)
		end

		VirtualMouse.delayMovement()

		VirtualMouse.lookStateCached = VirtualMouse.lookState
	end

	VirtualMouse.setDelayedLookSpeed()

	local isAirStrafing = LocalPlayer:m_vecVelocity().z > -50 and not LocalPlayer:isFlagActive(Player.flags.FL_ONGROUND) and Pathfinder.isAirStrafeJump

	-- Do not delay mouse movement speed under some conditions.
	if not VirtualMouse.isLookSpeedDelayed or Pathfinder.movementRecorderAngle or isAirStrafing then
		VirtualMouse.lookSpeed = VirtualMouse.lookSpeedIdeal
	end

	-- VirtualMouse angles we want to look at.
	-- It's overriden by AI behaviours, look ahead of the active path, or rest.
	--- @type Angle
	local idealViewAngles = LocalPlayer.getCameraAngles()
	local smoothingCutoffThreshold = 0

	if isAirStrafing and Pathfinder.isOnValidPath() then
		VirtualMouse.setAirStrafe(idealViewAngles)
	elseif Pathfinder.isObstructedByObstacle or Pathfinder.isObstructedByDoor then
		-- Remove obstructions in front of the player.
		VirtualMouse.setIdealRemoveObstructions(idealViewAngles)
	elseif Pathfinder.movementRecorderAngle then
		-- If Pathfinder "is replaying" is not true, but this value is set,
		-- then the Pathfinder is about to execute a recorded movement,
		-- and the angle is the starting direction for the movement.
		VirtualMouse.setIdealRecorded(idealViewAngles)
	elseif VirtualMouse.activeViewAngles then
		-- AI wants to look at something particular.
		VirtualMouse.setIdealActive(idealViewAngles)

		if LocalPlayer:m_bIsScoped() == 1 then
			smoothingCutoffThreshold = 0.2
		else
			smoothingCutoffThreshold = 0.35
		end
	elseif VirtualMouse.passiveViewAngles then
		-- Allows AI routines to control mouse without also overriding an AI state that is running concurrently.
		VirtualMouse.setIdealPassive(idealViewAngles)
	elseif Pathfinder.isOnValidPath() then
		-- Handle the "buildup" of mouse movement delta that would result in the virtual mouse leaving the mousemat.
		VirtualMouse.handleBuildup()

		if VirtualMouse.buildupCooldownTimer:isElapsed(VirtualMouse.buildupCooldownTime) then
			-- Perform generic look behaviour.
			VirtualMouse.setIdealPathCrosshairPlacement(idealViewAngles)

			-- Watch corners enemies are actually occluded by.
			VirtualMouse.setIdealWatchCorner(idealViewAngles)
		else
			VirtualMouse.setNoiseType(ViewNoiseType.minor)
		end

		smoothingCutoffThreshold = 1
	else
		VirtualMouse.lookState = "None"
	end

	--- @type Angle
	local targetViewAngles = idealViewAngles

	-- Makes the crosshair have noise.
	VirtualMouse.setTargetNoise(targetViewAngles)

	-- Set the mouse interlopation algorithm. Rigid relies on lerp, dynamic is 2nd order dynamics.
	-- 2OD is considerably more realistic, at the slight cost of accuracy and the occassional bug.
	if Config.virtualMouseMode == "rigid" then
		VirtualMouse.setTargetVelocity(targetViewAngles)
	elseif Config.virtualMouseMode == "dynamic" then
		VirtualMouse.setTargetDynamic(targetViewAngles)
	end

	if VirtualMouse.isCrosshairLerpingToZero then
		VirtualMouse.isCrosshairLerpingToZero = false
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
	VirtualMouse.interpolateViewAngles(targetViewAngles)
end

--- @return void
function VirtualMouse.fireWeapon()
	VirtualMouse.isFiringWeapon = true
end

--- @return void
function VirtualMouse.resetViewParameters()
	VirtualMouse.activeViewAngles = nil
	VirtualMouse.passiveViewAngles = nil
	VirtualMouse.isFiringWeapon = false
	VirtualMouse.isInUse = false
	VirtualMouse.isBlocked = false

	-- Reset noise. Defaults to none at all.
	VirtualMouse.setNoiseType(ViewNoiseType.none)
end

--- @return void
function VirtualMouse.block()
	VirtualMouse.isBlocked = true
end

--- @return void
function VirtualMouse.blockBuildup()
	VirtualMouse.buildup = 0

	VirtualMouse.buildupCooldownTimer:elapse()
end

--- @return void
function VirtualMouse.handleBuildup()
	local cameraAngles = LocalPlayer.getCameraAngles()

	if not VirtualMouse.buildupLastAngles then
		VirtualMouse.buildupLastAngles = cameraAngles
	end

	local delta = (VirtualMouse.buildupLastAngles - cameraAngles):normalize()

	VirtualMouse.buildup = VirtualMouse.buildup + delta.y
	VirtualMouse.buildupLastAngles = cameraAngles

	if math.abs(VirtualMouse.buildup) < VirtualMouse.buildupThreshold then
		return
	end

	VirtualMouse.buildup = 0
	VirtualMouse.buildupThreshold = Math.getRandomFloat(125,  165)
	VirtualMouse.buildupCooldownTime = Math.getRandomFloat(0.25, 0.8)

	VirtualMouse.buildupCooldownTimer:start()
end

--- @return void
function VirtualMouse.delayMovement()
	VirtualMouse.lookSpeed = 0
	VirtualMouse.lookSpeedDelayed = 0
	VirtualMouse.lookSpeedDelayTimer:start()
	VirtualMouse.lookSpeedDelay = Math.getRandomFloat(VirtualMouse.lookSpeedDelayMin, VirtualMouse.lookSpeedDelayMax)
end

--- @return void
function VirtualMouse.setDelayedLookSpeed()
	if VirtualMouse.lookSpeedDelayTimer:isElapsed(VirtualMouse.lookSpeedDelay) then
		VirtualMouse.lookSpeedDelayed = Math.getClamped(VirtualMouse.lookSpeedDelayed + 30 * Time.getDelta(), 0, VirtualMouse.lookSpeedIdeal)
	end

	VirtualMouse.lookSpeed = VirtualMouse.lookSpeedDelayed
end

--- @param targetViewAngles Angle
--- @return void
function VirtualMouse.interpolateViewAngles(targetViewAngles)
	targetViewAngles:normalize()

	VirtualMouse.viewAngles:lerpTickrate(targetViewAngles, VirtualMouse.lookSpeed * VirtualMouse.lookSpeedModifier)
end

--- @param noise VirtualMouseNoise
--- @return void
function VirtualMouse.setNoiseType(noise)
	VirtualMouse.currentNoise = noise

	if not VirtualMouse.currentNoise then
		VirtualMouse.currentNoise = ViewNoiseType.none
	end
end

--- @param targetViewAngles Angle
--- @return void
function VirtualMouse.setTargetNoise(targetViewAngles)
	-- Noise is NONE or not worth calculating.
	if VirtualMouse.currentNoise.timeExponent == 0 then
		return
	end

	-- Randomise when and for how long the noise is applied to the mouse.
	if VirtualMouse.currentNoise.isRandomlyToggled then
		if VirtualMouse.currentNoise.toggleIntervalTimer:isElapsedThenStop(VirtualMouse.currentNoise.toggleInterval) then
			VirtualMouse.currentNoise.toggleInterval = Math.getRandomFloat(VirtualMouse.currentNoise.toggleIntervalMin, VirtualMouse.currentNoise.toggleIntervalMax)

			VirtualMouse.currentNoise.togglePeriodTimer:start()
		end

		if VirtualMouse.currentNoise.togglePeriodTimer:isStarted() then
			if not VirtualMouse.currentNoise.togglePeriodTimer:isElapsed(VirtualMouse.currentNoise.togglePeriod) then
				VirtualMouse.setNaturalNoise()

				VirtualMouse.lastIdleAngle = Angle:new(
					VirtualMouse.pitchFine + VirtualMouse.pitchSoft,
					VirtualMouse.yawFine + VirtualMouse.yawSoft
				)
			else
				VirtualMouse.currentNoise.togglePeriod = Math.getRandomFloat(VirtualMouse.currentNoise.togglePeriodMin, VirtualMouse.currentNoise.togglePeriodMax)

				VirtualMouse.currentNoise.togglePeriodTimer:stop()
				VirtualMouse.currentNoise.toggleIntervalTimer:start()
			end
		end

		targetViewAngles:offsetByAngle(VirtualMouse.lastIdleAngle)

		return
	end

	VirtualMouse.setNaturalNoise()

	local angle = Angle:new(
		VirtualMouse.pitchFine + VirtualMouse.pitchSoft,
		VirtualMouse.yawFine + VirtualMouse.yawSoft
	)

	targetViewAngles:offsetByAngle(angle)
end

--- @return void
function VirtualMouse.setNaturalNoise()
	-- Scale the noise based on velocity.
	local velocityMod = 1

	-- Change between "in movement" and "standing still" noise parameters.
	if VirtualMouse.currentNoise.isBasedOnVelocity then
		local velocity = LocalPlayer:m_vecVelocity():getMagnitude()

		velocityMod = Math.getClamped(Math.getFloat(5 + velocity, 450) * 1, 0, 450)
	end

	-- How intense the noise is.
	local timeExponent = Time.getRealtime() * VirtualMouse.currentNoise.timeExponent

	-- High frequency, low amplitude.
	VirtualMouse.pitchFine = PerlinNoise(
		VirtualMouse.currentNoise.pitchFineX * timeExponent,
		VirtualMouse.currentNoise.pitchFineY * timeExponent,
		VirtualMouse.currentNoise.pitchFineZ * timeExponent
	) * 2 * velocityMod

	-- Low frequency, high amplitude.
	VirtualMouse.pitchSoft = PerlinNoise(
		VirtualMouse.currentNoise.pitchSoftX * timeExponent,
		VirtualMouse.currentNoise.pitchSoftY * timeExponent,
		VirtualMouse.currentNoise.pitchSoftZ * timeExponent
	) * 10 * velocityMod

	-- High frequency, low amplitude.
	VirtualMouse.yawFine = PerlinNoise(
		VirtualMouse.currentNoise.yawFineX * timeExponent,
		VirtualMouse.currentNoise.yawFineY * timeExponent,
		VirtualMouse.currentNoise.yawFineZ * timeExponent
	) * 2 * velocityMod

	-- Low frequency, high amplitude.
	VirtualMouse.yawSoft = PerlinNoise(
		VirtualMouse.currentNoise.yawSoftX * timeExponent,
		VirtualMouse.currentNoise.yawSoftY * timeExponent,
		VirtualMouse.currentNoise.yawSoftZ * timeExponent
	) * 10 * velocityMod
end

--- @param targetViewAngles Angle
--- @return void
function VirtualMouse.setTargetDynamic(targetViewAngles)
	targetViewAngles:setFromAngle(VirtualMouse.dynamic:thinkNormalize(targetViewAngles))
end

--- @param targetViewAngles Angle
--- @return void
function VirtualMouse.setTargetVelocity(targetViewAngles)
	if not VirtualMouse.isCrosshairUsingVelocity then
		VirtualMouse.isCrosshairUsingVelocity = false

		return
	end

	local cameraAngles = LocalPlayer.getCameraAngles()

	-- Velocity increase is the difference between the last time we checked the camera angles and now.
	VirtualMouse.velocity = VirtualMouse.velocity + VirtualMouse.lastCameraAngles:getDiff(cameraAngles) * VirtualMouse.velocityGainModifier
	VirtualMouse.lastCameraAngles = cameraAngles

	-- Clamp the velocity within boundary.
	VirtualMouse.velocity.p = Math.getClamped(VirtualMouse.velocity.p, -VirtualMouse.velocityBoundary, VirtualMouse.velocityBoundary)
	VirtualMouse.velocity.y = Math.getClamped(VirtualMouse.velocity.y, -VirtualMouse.velocityBoundary, VirtualMouse.velocityBoundary)

	-- Reset the velocity to 0,0 over time.
	VirtualMouse.velocity:approach(Angle:new(), VirtualMouse.velocityResetSpeed)

	-- Velocity sine. This should make the over-swing become non-parallel to the aim target.
	local velocitySine = Angle:new(Animate.sine(0, Math.getClamped(VirtualMouse.velocity:getMagnitude() * 0.33, -3, 3), 1), 0)

	targetViewAngles:setFromAngle(targetViewAngles + (VirtualMouse.velocity + velocitySine))
end

--- @param targetViewAngles Angle
--- @return void
function VirtualMouse.setTargetCurve(targetViewAngles)
	-- Sine wave float the angles.
	local floatPitch = Animate.sine(0, 25, 4)
	local floatYaw = Animate.sine(0, 25, 2)

	-- Get the absolute difference of the angles.
	local deltaPitch = math.abs(targetViewAngles.p - VirtualMouse.viewAngles.p)
	local deltaYaw = math.abs(targetViewAngles.p - VirtualMouse.viewAngles.p)

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
function VirtualMouse.setIdealRecorded(idealViewAngles)
	VirtualMouse.lookState = "VirtualMouse recorded pre-execute"
	VirtualMouse.lookSpeedIdeal = 4.6

	idealViewAngles:setFromAngle(Pathfinder.movementRecorderAngle)
end

--- @param idealViewAngles Angle
--- @return void
function VirtualMouse.setIdealActive(idealViewAngles)
	idealViewAngles:setFromAngle(VirtualMouse.activeViewAngles)
end

--- @param idealViewAngles Angle
--- @return void
function VirtualMouse.setIdealPassive(idealViewAngles)
	idealViewAngles:setFromAngle(VirtualMouse.passiveViewAngles)
end

--- @param idealViewAngles Angle
--- @return void
function VirtualMouse.setAirStrafe(idealViewAngles)
	local lookAheadNode = Pathfinder.path.nodes[Pathfinder.path.idx]

	if not lookAheadNode then
		return
	end

	if LocalPlayer:getOrigin():getDistance2(lookAheadNode.origin) < 30 then
		return
	end

	local angle = LocalPlayer.getEyeOrigin():getAngle(lookAheadNode.origin:clone():offset(0, 0, 46))

	angle.p = Math.getClamped(angle.p, -15, 15)

	-- Generate our look ahead view angles.
	idealViewAngles:setFromAngle(angle)

	-- Shake the mouse movement.
	VirtualMouse.setNoiseType(ViewNoiseType.none)

	VirtualMouse.lookState = "VirtualMouse air-strafe"
	VirtualMouse.lookSpeedIdeal = 7
	VirtualMouse.lookSpeedDelayMin = 0.05
	VirtualMouse.lookSpeedDelayMax = 0.1
end

--- @param idealViewAngles Angle
--- @return void
function VirtualMouse.setIdealPathCrosshairPlacement(idealViewAngles)
	local currentNode = Pathfinder.path.node

	if Pathfinder.isAscendingLadder then
		idealViewAngles:setFromAngle(currentNode.direction:clone():set(-75))

		VirtualMouse.lookState = "VirtualMouse ladder-up"
		VirtualMouse.lookSpeedIdeal = 6
		VirtualMouse.lookSpeedDelayMin = 0
		VirtualMouse.lookSpeedDelayMax = 0

		return
	elseif Pathfinder.isDescendingLadder then
		idealViewAngles:setFromAngle(currentNode.direction:clone():set(89))

		VirtualMouse.lookState = "VirtualMouse ladder-down"
		VirtualMouse.lookSpeedIdeal = 6
		VirtualMouse.lookSpeedDelayMin = 0
		VirtualMouse.lookSpeedDelayMax = 0

		return
	end

	--- @type Vector3
	local lastVisibleOrigin
	local eyeOrigin = LocalPlayer.getEyeOrigin()
	local isOk = true
	local occludedCount = 0
	local occludedThreshold = 4

	if AiThreats.threatLevel >= AiThreats.threatLevels.LOW then
		occludedThreshold = 2
	end

	for pathIdx = Pathfinder.path.idx + 1, Pathfinder.path.finalIdx do
		local source = Pathfinder.path.nodes[pathIdx]
		local target = Pathfinder.path.nodes[pathIdx + 1]

		if not source or not target then
			local lastNode = Pathfinder.path.endGoal

			lastVisibleOrigin = lastNode.eyeOrigin:clone():offset(0, 0, -25)

			break
		end

		local float = Math.getClampedFloat(source.eyeOrigin:getDistance(target.eyeOrigin), 350, 0, 350)
		local steps = math.ceil(float * 5)
		local scalar = 1 / steps

		for i = 1, steps do
			local offsetOrigin = source.eyeOrigin:getLerp(target.eyeOrigin, i * scalar)

			local trace = Trace.getLineToPosition(
				eyeOrigin,
				offsetOrigin,
				AiUtility.traceOptionsVisible,
				"VirtualMouse.setIdealPathCrosshairPlacement<FindVisibleNode>"
			)

			if trace.isIntersectingGeometry then
				occludedCount = occludedCount + 1

				if occludedCount >= occludedThreshold then
					isOk = false

					break
				end
			end

			lastVisibleOrigin = offsetOrigin
		end

		if not isOk then
			break
		end
	end

	if not lastVisibleOrigin then
		return
	end

	if not VirtualMouse.pathCrosshairPlacement then
		VirtualMouse.pathCrosshairPlacement = lastVisibleOrigin
	end

	VirtualMouse.pathCrosshairPlacement:lerp(lastVisibleOrigin, 10 * Time.delta)

	idealViewAngles:setFromAngle(eyeOrigin:getAngle(VirtualMouse.pathCrosshairPlacement))

	-- Shake the mouse movement.
	VirtualMouse.setNoiseType(ViewNoiseType.moving)

	VirtualMouse.lookState = "VirtualMouse path"
	VirtualMouse.lookSpeedIdeal = 6
	VirtualMouse.lookSpeedDelayMin = 0.05
	VirtualMouse.lookSpeedDelayMax = 0.1
end

--- @param idealViewAngles Angle
--- @return void
function VirtualMouse.setIdealWatchCorner(idealViewAngles)
	if not VirtualMouse.isAllowedToWatchCorners then
		VirtualMouse.isAllowedToWatchCorners = true

		return
	end

	if not AiThreats.highestThreat then
		return
	end

	local threatOrigin = AiThreats.crosshairPlacements[AiThreats.highestThreat.eid]

	if not threatOrigin then
		return
	end

	local isAllowedToForceCheck = false

	if LocalPlayer:isTerrorist() and AiUtility.isBombPlanted() and LocalPlayer:getOrigin():getDistance(AiUtility.plantedBomb:m_vecOrigin()) < 1250 then
		isAllowedToForceCheck = true
	end

	if not isAllowedToForceCheck and AiSense.getAwareness(AiThreats.highestThreat) >= AiSense.awareness.RECENT_MOVED then
		return
	end

	idealViewAngles:setFromAngle(LocalPlayer.getEyeOrigin():getAngle(threatOrigin))

	VirtualMouse.setNoiseType(ViewNoiseType.moving)

	VirtualMouse.lookState = "VirtualMouse watch-corner"
	VirtualMouse.lookSpeedIdeal = 6.5
	VirtualMouse.lookSpeedDelayMin = 0
	VirtualMouse.lookSpeedDelayMax = 0
end

--- @param idealViewAngles Angle
--- @return void
function VirtualMouse.setIdealRemoveObstructions(idealViewAngles)
	local clientOrigin = LocalPlayer:getOrigin()
	local node = Pathfinder.path.node

	if not node.direction then
		return
	end

	local maxDiff = LocalPlayer.getCameraAngles():getMaxDiff(node.direction)

	idealViewAngles:setFromAngle(node.direction)

	VirtualMouse.lookState = "VirtualMouse obstructions"
	VirtualMouse.lookSpeedIdeal = 6
	VirtualMouse.lookSpeedDelayMin = 0
	VirtualMouse.lookSpeedDelayMax = 0

	if clientOrigin:getDistance2(node.origin) < 16 and maxDiff < 35 and VirtualMouse.useCooldown:isElapsedThenRestart(1) then
		if Pathfinder.isObstructedByObstacle then
			VirtualMouse.isFiringWeapon = true
		elseif Pathfinder.isObstructedByDoor then
			VirtualMouse.isInUse = true
		end
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function VirtualMouse.think(cmd)
	if not VirtualMouse.isEnabled then
		return
	end

	if not VirtualMouse.blockMouseControlTimer:isElapsed(1) then
		return
	end

	if not VirtualMouse.viewAngles then
		return
	end

	local correctedViewAngles = VirtualMouse.viewAngles:clone()

	if VirtualMouse.isFiringWeapon then
		cmd.in_attack = true
	end

	if VirtualMouse.isInUse then
		cmd.in_use = true
	end
	
	if VirtualMouse.isRcsEnabled then
		local aimPunchAngles = LocalPlayer:m_aimPunchAngle() * VirtualMouse.recoilControl

		correctedViewAngles = ((correctedViewAngles - aimPunchAngles)):normalize()
	end

	VirtualMouse.lookAtAngles = correctedViewAngles
	VirtualMouse.isViewLocked = false

	cmd.pitch = correctedViewAngles.p
	cmd.yaw = correctedViewAngles.y
end

--- @param origin Vector3
--- @param speed number
--- @param noise VirtualMouseNoiseType
--- @return void
function VirtualMouse.lookAtLocation(origin, speed, noise, note)
	if VirtualMouse.isViewLocked then
		return
	end

	VirtualMouse.activeViewAngles = LocalPlayer.getEyeOrigin():getAngle(origin)
	VirtualMouse.lookSpeedIdeal = speed
	VirtualMouse.lastLookAtLocationOrigin = origin
	VirtualMouse.lookState = note

	VirtualMouse.setNoiseType(noise or ViewNoiseType.none)
end

--- @param angle Angle
--- @param speed number
--- @param noise VirtualMouseNoiseType
--- @return void
function VirtualMouse.lookAlongAngle(angle, speed, noise, note)
	if VirtualMouse.isViewLocked then
		return
	end

	VirtualMouse.activeViewAngles = angle:clone()
	VirtualMouse.lookSpeedIdeal = speed
	VirtualMouse.lastLookAtLocationOrigin = nil
	VirtualMouse.lookState = note

	VirtualMouse.setNoiseType(noise or ViewNoiseType.none)
end

--- @param direction Vector3
--- @param speed number
--- @param noise VirtualMouseNoiseType
--- @return void
function VirtualMouse.lookInDirection(direction, speed, noise, note)
	if VirtualMouse.isViewLocked then
		return
	end

	VirtualMouse.activeViewAngles = direction:getAngleFromUnitVector()
	VirtualMouse.lookSpeedIdeal = speed
	VirtualMouse.lastLookAtLocationOrigin = nil
	VirtualMouse.lookState = note

	VirtualMouse.setNoiseType(noise or ViewNoiseType.none)
end

--- @param origin Vector3
--- @return void
function VirtualMouse.lookAtLocationPassively(origin)
	if VirtualMouse.isViewLocked then
		return
	end

	VirtualMouse.passiveViewAngles = LocalPlayer.getEyeOrigin():getAngle(origin)
end

--- @param angle Angle
--- @return void
function VirtualMouse.lookAlongAnglePassively(angle)
	if VirtualMouse.isViewLocked then
		return
	end

	VirtualMouse.passiveViewAngles = angle:clone()
end

--- @param direction Vector3
--- @return void
function VirtualMouse.lookInDirectionPassively(direction)
	if VirtualMouse.isViewLocked then
		return
	end

	VirtualMouse.passiveViewAngles = direction:getAngleFromUnitVector()
end

return Nyx.class("VirtualMouse", VirtualMouse)
--}}}
