--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
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
--- @field isAllowedToWatchCorners boolean
--- @field isCrosshairSmoothed boolean
--- @field isCrosshairUsingVelocity boolean
--- @field isEnabled boolean
--- @field isRcsEnabled boolean
--- @field isViewLocked boolean
--- @field lastCameraAngles Angle
--- @field lastLookAtLocationOrigin Vector3
--- @field lookAtAngles Angle
--- @field lookNote string
--- @field lookSpeed number
--- @field lookSpeedModifier number
--- @field nodegraph Nodegraph
--- @field currentNoise ViewNoise
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
local View = {
	noise = ViewNoiseType
}

--- @return void
function View.__setup()
	View.initFields()
	View.initEvents()
	View.initMenu()
end

--- @return void
function View.initFields()
	View.aimPunchAngles = Angle:new(0, 0)
	View.isCrosshairUsingVelocity = true
	View.lastCameraAngles = Client.getCameraAngles()
	View.lookAtAngles = Client.getCameraAngles()
	View.lookSpeed = 0
	View.lookSpeedModifier = 1.2
	View.recoilControl = 2
	View.useCooldown = Timer:new():start()
	View.velocity = Angle:new()
	View.velocityBoundary = 25
	View.velocityGainModifier = 0.7
	View.velocityResetSpeed = 100
	View.viewAngles = Client.getCameraAngles()
	View.viewPitchOffset = 0
	View.pitchFine = 0
	View.pitchSoft = 0
	View.yawFine = 0
	View.yawSoft = 0

	View.setNoiseType(ViewNoiseType.none)
end

--- @return void
function View.initEvents()
	Callbacks.setupCommand(function(cmd)
		if not MenuGroup.master:get() or not MenuGroup.enableView:get() then
			return
		end

		View.setViewAngles()
		View.think(cmd)
	end)
end

--- @return void
function View.initMenu()
	MenuGroup.enableView = MenuGroup.group:addCheckbox(" > Enable Mouse Control"):setParent(MenuGroup.master)
end

--- @return void
function View.setViewAngles()
	-- Match camera angles to AI view angles.
	if View.viewAngles then
		Client.setCameraAngles(View.lookAtAngles)
	end

	-- View angles we want to look at.
	-- It's overriden by AI behaviours, look ahead of the active path, or rest.
	--- @type Angle
	local idealViewAngles = Client.getCameraAngles()
	local smoothingCutoffThreshold = 0

	if View.overrideViewAngles then
		-- AI wants to look at something particular.
		View.setIdealOverride(idealViewAngles)

		smoothingCutoffThreshold = 0.5
	elseif Pathfinder.isOk() then
		-- Perform generic look behaviour.
		View.setIdealLookAhead(idealViewAngles)
		-- Watch corners enemies are actually occluded by.
		View.setIdealWatchCorner(idealViewAngles)

		smoothingCutoffThreshold = 1
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

--- @param targetViewAngles Angle
--- @return void
function View.interpolateViewAngles(targetViewAngles)
	targetViewAngles:normalize()

	View.viewAngles:lerp(targetViewAngles, math.min(20, View.lookSpeed * View.lookSpeedModifier))
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
		-- Toggle interval handles how long to wait until we start applying noise.
		if View.currentNoise.toggleIntervalTimer:isElapsedThenStop(View.currentNoise.toggleInterval) then
			View.currentNoise.toggleInterval = Client.getRandomFloat(View.currentNoise.toggleIntervalMin, View.currentNoise.toggleIntervalMax)

			View.currentNoise.togglePeriodTimer:start()
		end

		-- Period interval handles how long we apply the noise for.
		if View.currentNoise.togglePeriodTimer:isStarted() then
			if View.currentNoise.togglePeriodTimer:isElapsedThenStop(View.currentNoise.togglePeriod) then
				View.currentNoise.togglePeriod = Client.getRandomFloat(View.currentNoise.togglePeriodMin, View.currentNoise.togglePeriodMax)

				View.currentNoise.toggleIntervalTimer:start()
			end
		else
			targetViewAngles:set(targetViewAngles.p + View.pitchFine + View.pitchSoft, targetViewAngles.y + View.yawFine + View.yawSoft)

			-- We're not applying noise right now.
			return
		end
	end

	-- Scale the noise based on velocity.
	local velocityMod = 1

	-- Change between "in movement" and "standing still" noise parameters.
	if View.currentNoise.isBasedOnVelocity then
		local velocity = AiUtility.client:m_vecVelocity():getMagnitude()

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
		View.isCrosshairUsingVelocity = true

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

	local lookOrigin = lookAheadNode.origin:clone()

	-- We want to look roughly head height of the goal.
	lookOrigin:offset(0, 0, 46)

	-- Set look speed so we don't use the speed set by AI behaviour.
	View.lookSpeed = 6.5
	View.lookNote = "View look ahead of path"

	-- Generate our look ahead view angles.
	idealViewAngles:setFromAngle(Client.getEyeOrigin():getAngle(lookOrigin))

	-- Shake the mouse movement.
	View.setNoiseType(ViewNoiseType.moving)
end

--- @param idealViewAngles Angle
--- @return void
function View.setIdealWatchCorner(idealViewAngles)
	if not View.isAllowedToWatchCorners then
		View.isAllowedToWatchCorners = true

		return
	end

	-- I actually refactored something for once, instead of doing it in 4 places in slightly different ways.
	-- No, don't open AiStateEvade. Don't look in there.
	if AiUtility.clientThreatenedFromOrigin then
		idealViewAngles:setFromAngle(Client.getEyeOrigin():getAngle(AiUtility.clientThreatenedFromOrigin))

		View.lookSpeed = 4
		View.lookNote = "View watch corner"

		View.setNoiseType(ViewNoiseType.moving)

		return
	end
end

--- @param cmd SetupCommandEvent
--- @return void
function View.think(cmd)
	if not View.viewAngles then
		return
	end

	local aimPunchAngles = AiUtility.client:m_aimPunchAngle()
	local correctedViewAngles = View.viewAngles:clone()

	if View.isRcsEnabled then
		View.aimPunchAngles = View.aimPunchAngles + (aimPunchAngles - View.aimPunchAngles) * 20 * Time.getDelta()

		correctedViewAngles = (correctedViewAngles - View.aimPunchAngles * View.recoilControl):normalize()
	end

	View.lookAtAngles = correctedViewAngles
	View.overrideViewAngles = nil
	View.isViewLocked = false

	cmd.pitch = correctedViewAngles.p
	cmd.yaw = correctedViewAngles.y

	-- Reset noise. Defaults to none at all.
	View.setNoiseType(ViewNoiseType.none)

	if Config.isDebugging then
		Logger.console(0, View.lookNote)
	end

	View.lookNote = nil

	local clientOrigin = AiUtility.client:getOrigin()

	-- Shoot out cover.
	if Pathfinder.isObstructedByObstacle then
		local node = Pathfinder.path.node
		local maxDiff = correctedViewAngles:getMaxDiff(node.direction)

		View.overrideViewAngles = node.direction
		View.lookSpeed = 4
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
		View.lookSpeed = 4
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
	View.lookSpeed = speed
	View.lastLookAtLocationOrigin = origin
	View.lookNote = note

	View.setNoiseType(noise or ViewNoiseType.none)
end

--- @param angle Angle
--- @param speed number
--- @param noise number
--- @return void
function View.lookInDirection(angle, speed, noise, note)
	if View.isViewLocked then
		return
	end

	View.overrideViewAngles = angle
	View.lookSpeed = speed
	View.lastLookAtLocationOrigin = nil
	View.lookNote = note

	View.setNoiseType(noise or ViewNoiseType.none)
end

return Nyx.class("View", View)
--}}}
