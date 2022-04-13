--{{{ Dependencies
local Animate = require "gamesense/Nyx/v1/Api/Animate"
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local ISurface = require "gamesense/Nyx/v1/Api/ISurface"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ Enums
--- @class AiViewNoiseType
local AiViewNoiseType = {
    NONE = -1,
    IDLE = 0,
    MOVING = 1,
    MINOR = 2
}
--}}}

--{{{ AiViewNoise
--- @class AiViewNoise : Class
--- @field name string
--- @field timeExponent number
--- @field pitchFineX number
--- @field pitchFineY number
--- @field pitchFineZ number
--- @field pitchSoftX number
--- @field pitchSoftY number
--- @field pitchSoftZ number
--- @field yawFineX number
--- @field yawFineY number
--- @field yawFineZ number
--- @field yawSoftX number
--- @field yawSoftY number
--- @field yawSoftZ number
--- @field isBasedOnVelocity boolean
--- @field isRandomlyToggled boolean
--- @field toggleInterval number
--- @field toggleIntervalMin number
--- @field toggleIntervalMax number
--- @field toggleIntervalTimer Timer
--- @field togglePeriodTimer Timer
--- @field togglePeriod number
--- @field togglePeriodMin number
--- @field togglePeriodMax number
local AiViewNoise = {}

--- @param fields AiViewNoise
--- @return AiViewNoise
function AiViewNoise:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function AiViewNoise:__init()
    self.toggleIntervalTimer = Timer:new():start()
    self.togglePeriodTimer = Timer:new()
    self.toggleInterval = 0
    self.toggleIntervalMin = 1
    self.toggleIntervalMax = 16
    self.togglePeriod = 0
    self.togglePeriodMin = 0.1
    self.togglePeriodMax = 1
end

Nyx.class("AiViewNoise", AiViewNoise)
--}}}

--{{{ Graph
--- @class Graph : Class
--- @field title string
--- @field origin Vector2
--- @field color Color
--- @field isColorCoded boolean
--- @field isInverseColor boolean
--- @field height number
--- @field spacing number
--- @field maxRecords number
--- @field maxValue number
--- @field minValue number
--- @field recordInterval number
--- @field callback fun(graph: Graph): number
--- @field direction string | "left" | "right"
---
--- @field width number
--- @field currentRecord number
--- @field records number[]
--- @field recordTimer Timer
--- @field lastMaxValue number
--- @field font number
local Graph = {
    font = ISurface.createFont("Segoe UI", 14, ISurface.WEIGHT_NORMAL, ISurface.FLAG_ANTIALIAS)
}

--- @param fields Graph
--- @return Graph
function Graph:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function Graph:__init()
    self:initFields()
end

--- @return void
function Graph:initFields()
    self.currentRecord = 1
    self.records = {}
    self.recordTimer = Timer:new():startThenElapse()

    if self.color == nil then
        self.color = Color:hsla(0, 0.8, 0.6)
    end

    self.width = self.spacing * self.maxRecords
    self.origin.x = self.origin.x - self.width

    if not self.isColorCoded then
        self.isColorCoded = false
    end

    if not self.isInverseColor then
        self.isInverseColor = false
    end
end

--- @return void
function Graph:think()
    if self.recordTimer:isElapsedThenRestart(self.recordInterval) then
        self.records[self.currentRecord] = self.callback(self)
        self.records[self.currentRecord - self.maxRecords] = nil
        self.currentRecord = self.currentRecord + 1
    end

    if self.lastMaxValue ~= self.maxValue then
        self.lastMaxValue = self.maxValue
        self.records = {}
        self.currentRecord = 1
        self.recordTimer:startThenElapse()
    end

    local drawOrigin = self.origin:clone():offset(self.width)
    local textOrigin = self.origin:clone()

    local currentRecord = self.records[self.currentRecord - 1]
    --- @type Color
    local currentColor

    if currentRecord then
        currentColor = self.color:clone()

        if self.isColorCoded then
            if self.isInverseColor then
                currentColor:setHue((1 - (currentRecord / self.maxValue)) * 130)
            else
                currentColor:setHue((currentRecord / self.maxValue) * 130)
            end
        end

        drawOrigin:clone():offset(0, self.height + 12):drawSurfaceText(self.font, currentColor, "r", string.format("%i", currentRecord))
    end

    if currentColor then
        drawOrigin:clone():offset(0, self.height):drawSurfaceText(self.font, currentColor, "r", self.title)

        self.origin:clone():offset(-8, -8):drawGradient(
            Vector2:new(self.width + 16, self.height + 35),
            currentColor:clone():setAlpha(0),
            currentColor:clone():setAlpha(40),
            true
        )
    end

    if not currentRecord then
        return
    end

    --- @type Vector2
    local lastDrawOrigin
    local index = 1
    local highestRecord = self.minValue
    --- @type Color
    local highestRecordColor
    local lowestRecord = self.maxValue
    --- @type Color
    local lowestRecordColor

    for i = self.currentRecord - self.maxRecords, self.currentRecord do
        repeat
            local record = self.records[i]

            if not record then
                break
            end

            local color = self.color:clone()

            if self.isColorCoded then
                if self.isInverseColor then
                    color:setHue((1 - (record / self.maxValue)) * 130)
                else
                    color:setHue((record / self.maxValue) * 130)
                end
            end

            if record > highestRecord then
                highestRecord = record
                highestRecordColor = color:clone()
            elseif record < lowestRecord then
                lowestRecord = record
                lowestRecordColor = color:clone()
            end

            color:setAlpha(math.max(0, index * (255 / self.maxRecords)))

            local height = (self.height - (record / self.maxValue) * self.height)
            local currentDrawOrigin = drawOrigin:clone():offset(0, height)

            if lastDrawOrigin then
                lastDrawOrigin:drawLine(currentDrawOrigin, color)
            end

            lastDrawOrigin = currentDrawOrigin

            drawOrigin:offset(-self.spacing)

            index = index + 1
        until true
    end

    if highestRecordColor then
        textOrigin:clone():offset(0, self.height):drawSurfaceText(self.font, highestRecordColor, "l", string.format("%i", highestRecord))
    end

    if lowestRecordColor then
        textOrigin:clone():offset(0, self.height + 12):drawSurfaceText(self.font, lowestRecordColor, "l", string.format("%i", lowestRecord))
    end
end

Nyx.class(
    "Graph",
    Graph
)
--}}}

--{{{ Perlin
local p = {}

local function fade(t)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

local function lerp(t, a, b)
    return a + t * (b - a)
end

local function grad(hash, x, y, z)
    local h = hash % 16
    local u
    local v

    if (h < 8) then
        u = x
    else
        u = y
    end
    if (h < 4) then
        v = y
    elseif (h == 12 or h == 14) then
        v = x
    else
        v = z
    end
    local r

    if ((h % 2) == 0) then
        r = u
    else
        r = -u
    end
    if ((h % 4) == 0) then
        r = r + v
    else
        r = r - v
    end

    return r
end

local function getPerlinNoise(x, y, z)
    local X = math.floor(x % 255)
    local Y = math.floor(y % 255)
    local Z = math.floor(z % 255)
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)
    local u = fade(x)
    local v = fade(y)
    local w = fade(z)

    local A = p[X] + Y
    local AA = p[A] + Z
    local AB = p[A + 1] + Z
    local B = p[X + 1] + Y
    local BA = p[B] + Z
    local BB = p[B + 1] + Z

    return lerp(w, lerp(v, lerp(u, grad(p[AA], x, y, z),
        grad(p[BA], x - 1, y, z)),
        lerp(u, grad(p[AB], x, y - 1, z),
            grad(p[BB], x - 1, y - 1, z))),
        lerp(v, lerp(u, grad(p[AA + 1], x, y, z - 1),
            grad(p[BA + 1], x - 1, y, z - 1)),
            lerp(u, grad(p[AB + 1], x, y - 1, z - 1),
                grad(p[BB + 1], x - 1, y - 1, z - 1)))
    )
end

local permutation = {151, 160, 137, 91, 90, 15,
                     131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23,
                     190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33,
                     88, 237, 149, 56, 87, 174, 20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166,
                     77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244,
                     102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200, 196,
                     135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123,
                     5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182, 189, 28, 42,
                     223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163, 70, 221, 153, 101, 155, 167, 43, 172, 9,
                     129, 22, 39, 253, 19, 98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228,
                     251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107,
                     49, 192, 214, 31, 181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254,
                     138, 236, 205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
}

for i = 0, 255 do
    p[i] = permutation[i + 1]
    p[256 + i] = permutation[i + 1]
end
--}}}

--{{{ AiView
--- @class AiView : Class
--- @field aimPunchAngles Angle
--- @field graphs Graph[]
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
--- @field noise AiViewNoise
--- @field noises AiViewNoise[]
--- @field noiseType AiViewNoiseType
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
local AiView = {
    noiseType = AiViewNoiseType
}

--- @param fields AiView
--- @return AiView
function AiView:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiView:__init()
    self:initFields()
    self:initEvents()
end

--- @return void
function AiView:initFields()
    self.aimPunchAngles = Angle:new(0, 0)
    self.isCrosshairUsingVelocity = true
    self.lastCameraAngles = Client.getCameraAngles()
    self.lookAtAngles = Client.getCameraAngles()
    self.lookSpeed = 0
    self.lookSpeedModifier = 1.2
    self.recoilControl = 2
    self.useCooldown = Timer:new():start()
    self.velocity = Angle:new()
    self.velocityBoundary = 22
    self.velocityGainModifier = 0.65
    self.velocityResetSpeed = 90
    self.viewAngles = Client.getCameraAngles()
    self.viewPitchOffset = 0
    self.pitchFine = 0
    self.pitchSoft = 0
    self.yawFine = 0
    self.yawSoft = 0

    self.noises = {
        [AiViewNoiseType.NONE] = AiViewNoise:new({
            name = "None",
            timeExponent = 0,
            isBasedOnVelocity = false,
            isRandomlyToggled = false,

            pitchFineX = 0,
            pitchFineY = 0,
            pitchFineZ = 0,

            pitchSoftX = 0,
            pitchSoftY = 0,
            pitchSoftZ = 0,

            yawFineX = 0,
            yawFineY = 0,
            yawFineZ = 0,

            yawSoftX = 0,
            yawSoftY = 0,
            yawSoftZ = 0,
        }),
        [AiViewNoiseType.IDLE] = AiViewNoise:new({
            name = "Idle",
            timeExponent = 5,
            isBasedOnVelocity = false,
            isRandomlyToggled = true,

            pitchFineX = 0.001,
            pitchFineY = 0.002,
            pitchFineZ = 0.0,

            pitchSoftX = 0.0008,
            pitchSoftY = 0.001,
            pitchSoftZ = 0.0015,

            yawFineX = 0.008,
            yawFineY = 0.0005,
            yawFineZ = 0.001,

            yawSoftX = 0.001,
            yawSoftY = 0.0002,
            yawSoftZ = 0.001,
        }),
        [AiViewNoiseType.MOVING] = AiViewNoise:new({
            name = "Moving",
            timeExponent = 100,
            isBasedOnVelocity = true,
            isRandomlyToggled = false,

            pitchFineX = 0.006,
            pitchFineY = 0.005,
            pitchFineZ = 0.0033,

            pitchSoftX = 0.0012,
            pitchSoftY = 0.0015,
            pitchSoftZ = 0.0035,

            yawFineX = 0.006,
            yawFineY = 0.045,
            yawFineZ = 0.0133,

            yawSoftX = 0.0012,
            yawSoftY = 0.0046,
            yawSoftZ = 0.007,
        }),
        [AiViewNoiseType.MINOR] = AiViewNoise:new({
            name = "Minor",
            timeExponent = 50,
            isBasedOnVelocity = false,
            isRandomlyToggled = false,

            pitchFineX = 0.003,
            pitchFineY = 0.08,
            pitchFineZ = 0.057,

            pitchSoftX = 0.0,
            pitchSoftY = 0.0,
            pitchSoftZ = 0.0,

            yawFineX = 0.03,
            yawFineY = 0.0051,
            yawFineZ = 0.012,

            yawSoftX = 0.0,
            yawSoftY = 0.0,
            yawSoftZ = 0.0,
        }),
    }

    self:setNoiseType(AiViewNoiseType.NONE)

    self.graphs = {
        Graph:new({
            origin = Vector2:new(Client.getScreenDimensions().x - 5, 350),
            color = Color:hsla(130, 0.8, 0.6),
            isColorCoded = true,
            title = "Perlin (Pitch)",
            height = 200,
            spacing = 1,
            maxRecords = 300,
            minValue = 0,
            maxValue = 30,
            recordInterval = 0.01,
            callback = function()
                return self.pitchFine + self.pitchSoft + 10
            end,
            direction = "right"
        }),
        Graph:new({
            origin = Vector2:new(Client.getScreenDimensions().x - 5, 350 + 250),
            color = Color:hsla(130, 0.8, 0.6),
            isColorCoded = true,
            title = "Perlin (Yaw)",
            height = 200,
            spacing = 1,
            maxRecords = 300,
            minValue = 0,
            maxValue = 30,
            recordInterval = 0.01,
            callback = function()
                return self.yawFine + self.yawSoft + 10
            end,
            direction = "right"
        })
    }
end

--- @return void
function AiView:initEvents()
    Callbacks.runCommand(function()
        if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableView:get() then
            return
        end

        if not self.isEnabled then
            return
        end

        self:setViewAngles()
    end)

    Callbacks.frame(function()
        if Config.isDebugging then
            for _, graph in pairs(self.graphs) do
                graph:think()
            end
        end
    end)
end

--- @return void
function AiView:setViewAngles()
    -- Match camera angles to AI view angles.
    if self.viewAngles then
        Client.setCameraAngles(self.lookAtAngles)
    end

    -- View angles we want to look at.
    -- It's overriden by AI behaviours, look ahead of the active path, or rest.
    --- @type Angle
    local idealViewAngles = Client.getCameraAngles()
    local smoothingCutoffThreshold = 0

    if self.overrideViewAngles then
        -- AI wants to look at something particular.
        self:setIdealOverride(idealViewAngles)

        smoothingCutoffThreshold = 0.66
    elseif self.nodegraph.path then
        -- Perform generic look behaviour.
        self:setIdealLookAhead(idealViewAngles)
        -- Watch corners enemies are actually occluded by.
        self:setIdealWatchCorner(idealViewAngles)
        -- Check corners enemies can be behind. This particular logic is also more realistic looking, albeit flawed
        -- compared to watch corner.
        self:setIdealCheckCorner(idealViewAngles)

        smoothingCutoffThreshold = 3
    end

    --- @type Angle
    local targetViewAngles = idealViewAngles

    -- Makes the crosshair have noise.
    self:setTargetNoise(targetViewAngles)

    -- Apply velocity on angles. Creates the effect of "over-shooting" the target point
    -- when moving the mouse far and fast.
    self:setTargetVelocity(targetViewAngles)

    -- Makes the crosshair curve.
    self:setTargetCurve(targetViewAngles)

    if self.isCrosshairSmoothed then
        self.isCrosshairSmoothed = false
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
    self:interpolateViewAngles(targetViewAngles)
end

--- @param targetViewAngles Angle
--- @return void
function AiView:interpolateViewAngles(targetViewAngles)
    targetViewAngles:normalize()

    self.viewAngles:lerp(targetViewAngles, math.min(20, self.lookSpeed * self.lookSpeedModifier))
end

--- @param noiseType number
--- @return void
function AiView:setNoiseType(noiseType)
    self.noise = self.noises[noiseType]

    if not self.noise then
        self.noise = self.noises[AiViewNoiseType.NONE]
    end
end

--- @param targetViewAngles Angle
--- @return void
function AiView:setTargetNoise(targetViewAngles)
    -- Randomise when and for how long the noise is applied to the mouse.
    if self.noise.isRandomlyToggled then
        -- Toggle interval handles how long to wait until we start applying noise.
        if self.noise.toggleIntervalTimer:isElapsedThenStop(self.noise.toggleInterval) then
            self.noise.toggleInterval = Client.getRandomFloat(self.noise.toggleIntervalMin, self.noise.toggleIntervalMax)

            self.noise.togglePeriodTimer:start()
        end

        -- Period interval handles how long we apply the noise for.
        if self.noise.togglePeriodTimer:isStarted() then
            if self.noise.togglePeriodTimer:isElapsedThenStop(self.noise.togglePeriod) then
                self.noise.togglePeriod = Client.getRandomFloat(self.noise.togglePeriodMin, self.noise.togglePeriodMax)

                self.noise.toggleIntervalTimer:start()
            end
        else
            targetViewAngles:set(targetViewAngles.p + self.pitchFine + self.pitchSoft, targetViewAngles.y + self.yawFine + self.yawSoft)

            -- We're not applying noise right now.
            return
        end
    end

    -- Scale the noise based on velocity.
    local velocity = AiUtility.client:m_vecVelocity():getMagnitude()
    local velocityMod = 1

    -- Change between "in movement" and "standing still" noise parameters.
    if self.noise.isBasedOnVelocity then
        velocityMod = Math.getClamped(Math.getFloat(5 + velocity, 450) * 1, 0, 450)
    end

    -- How intense the noise is.
    local timeExponent = Time.getRealtime() * self.noise.timeExponent

    -- High frequency, low amplitude.
    self.pitchFine = getPerlinNoise(
        self.noise.pitchFineX * timeExponent,
        self.noise.pitchFineY * timeExponent,
        self.noise.pitchFineZ * timeExponent
    ) * 2 * velocityMod

    -- Low frequency, high amplitude.
    self.pitchSoft = getPerlinNoise(
        self.noise.pitchSoftX * timeExponent,
        self.noise.pitchSoftY * timeExponent,
        self.noise.pitchSoftZ * timeExponent
    ) * 10 * velocityMod

    -- High frequence, low amplitude.
    self.yawFine = getPerlinNoise(
        self.noise.yawFineX * timeExponent,
        self.noise.yawFineY * timeExponent,
        self.noise.yawFineZ * timeExponent
    ) * 2 * velocityMod

    -- Low frequency, high amplitude.
    self.yawSoft = getPerlinNoise(
        self.noise.yawSoftX * timeExponent,
        self.noise.yawSoftY * timeExponent,
        self.noise.yawSoftZ * timeExponent
    ) * 10 * velocityMod

    targetViewAngles:set(targetViewAngles.p + self.pitchFine + self.pitchSoft, targetViewAngles.y + self.yawFine + self.yawSoft)
end

--- @param targetViewAngles Angle
--- @return void
function AiView:setTargetVelocity(targetViewAngles)
    if not self.isCrosshairUsingVelocity then
        self.isCrosshairUsingVelocity = true

        return
    end

    local cameraAngles = Client.getCameraAngles()

    -- Velocity increase is the difference between the last time we checked the camera angles and now.
    self.velocity = self.velocity + self.lastCameraAngles:getDiff(cameraAngles) * self.velocityGainModifier
    self.lastCameraAngles = cameraAngles

    -- Clamp the velocity within boundary.
    self.velocity.p = Math.getClamped(self.velocity.p, -self.velocityBoundary, self.velocityBoundary)
    self.velocity.y = Math.getClamped(self.velocity.y, -self.velocityBoundary, self.velocityBoundary)

    -- Reset the velocity to 0,0 over time.
    self.velocity:approach(Angle:new(), self.velocityResetSpeed)

    -- Velocity sine. This should make the over-swing become non-parallel to the aim target.
    local velocitySine = Angle:new(Animate.sine(0, Math.getClamped(self.velocity:getMagnitude() * 0.5, -8, 8), 1), 0)

    targetViewAngles:setFromAngle(targetViewAngles + (self.velocity + velocitySine))
end

--- @param targetViewAngles Angle
--- @return void
function AiView:setTargetCurve(targetViewAngles)
    -- Sine wave float the angles.
    local floatPitch = Animate.sine(0, 50, 5)
    local floatYaw = Animate.sine(0, 50, 2)

    -- Get the absolute difference of the angles.
    local deltaPitch = math.abs(targetViewAngles.p - self.viewAngles.p)
    local deltaYaw = math.abs(targetViewAngles.p - self.viewAngles.p)

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
function AiView:setIdealOverride(idealViewAngles)
    idealViewAngles:setFromAngle(self.overrideViewAngles)
end

--- @param idealViewAngles Angle
--- @return void
function AiView:setIdealLookAhead(idealViewAngles)
    --- @type Node
    local lookAheadNode

    -- How far in the path to look ahead.
    local lookAheadTo = 4

    -- Select a node ahead in the path, and look closer until we find a valid node.
    while not lookAheadNode and lookAheadTo > 0 do
        lookAheadNode = self.nodegraph.path[self.nodegraph.pathCurrent + lookAheadTo]

        lookAheadTo = lookAheadTo - 1
    end

    -- A valid node was found.
    if not lookAheadNode then
        return
    end

    local lookOrigin = lookAheadNode.origin:clone()

    -- Goal nodes that were based on other nodes' origins are +18z higher than they should be, so correct this.
    if lookAheadNode.type == Node.types.GOAL then
        lookOrigin:offset(0, 0, -18)
    end

    -- We want to look roughly head height of the goal.
    lookOrigin:offset(0, 0, 46)

    -- Set look speed so we don't use the speed set by AI behaviour.
    self.lookSpeed = 2
    self.lookNote = "AiView look ahead of path"

    -- Generate our look ahead view angles.
    idealViewAngles:setFromAngle(Client.getEyeOrigin():getAngle(lookOrigin))

    -- Shake the mouse movement.
    self:setNoiseType(AiViewNoiseType.MOVING)
end

--- @param idealViewAngles Angle
--- @return void
function AiView:setIdealCheckCorner(idealViewAngles)
    local player = AiUtility.client
    local clientOrigin = player:getOrigin()
    local closestCheckNode = self.nodegraph:getClosestNodeOf(clientOrigin, Node.types.CHECK)

    -- The AI isn't near enough to a check node to use one.
    if not closestCheckNode or clientOrigin:getDistance(closestCheckNode.origin) > 200 then
        return
    end

    local isEnemyActivatingCheck = false
    local clientEyeOrigin = Client.getEyeOrigin()
    local checkOrigin = closestCheckNode.origin:clone():offset(0, 0, 46)
    local checkDirection = closestCheckNode.direction
    local trace = Trace.getLineAtAngle(checkOrigin, checkDirection, AiUtility.traceOptionsPathfinding)
    local checkNearOrigin = trace.endPosition

    -- Find an enemy matching the check node's criteria.
    for _, enemy in pairs(AiUtility.enemies) do
        if enemy:getOrigin():getDistance(checkNearOrigin) < 256 then
            isEnemyActivatingCheck = true

            break
        end
    end

    -- We should use the check node.
    if isEnemyActivatingCheck then
        local cameraAngles = Client.getCameraAngles()
        local diff = cameraAngles:getMaxDiff(closestCheckNode.direction)

        -- Prevent the AI looking when its velocity is low, or the AI is facing well away from the check node.
        if player:m_vecVelocity():getMagnitude() > 100 and diff < 135 then
            -- Find the point that the check node is looking at.
            local trace = Trace.getLineAtAngle(checkOrigin, closestCheckNode.direction, AiUtility.traceOptionsPathfinding)

            -- Set look speed so we don't use the speed set by AI behaviour.
            self.lookSpeed = 4
            self.lookNote = "AiView check corner"

            idealViewAngles:setFromAngle(clientEyeOrigin:getAngle(trace.endPosition))
        end
    end

    self:setNoiseType(AiViewNoiseType.MOVING)
end

--- @param idealViewAngles Angle
--- @return void
function AiView:setIdealWatchCorner(idealViewAngles)
    if not self.isAllowedToWatchCorners then
        self.isAllowedToWatchCorners = true

        return
    end

    -- I actually refactored something for once, instead of doing it in 4 places in slightly different ways.
    -- No, don't open AiStateEvade. Don't look in there.
    if AiUtility.clientThreatenedFromOrigin then
        idealViewAngles:setFromAngle(Client.getEyeOrigin():getAngle(AiUtility.clientThreatenedFromOrigin))

        self.lookSpeed = 5
        self.lookNote = "AiView watch corner"

        self:setNoiseType(AiViewNoiseType.MOVING)

        return
    end
end

--- @param cmd SetupCommandEvent
--- @return void
function AiView:think(cmd)
    if not self.isEnabled then
        return
    end

    if not self.viewAngles then
        return
    end

    local player = AiUtility.client
    local origin = player:getOrigin()
    local aimPunchAngles = player:m_aimPunchAngle()
    local correctedViewAngles = self.viewAngles:clone()

    if self.isRcsEnabled then
        self.aimPunchAngles = self.aimPunchAngles + (aimPunchAngles - self.aimPunchAngles) * 20 * Time.getDelta()

        correctedViewAngles = (correctedViewAngles - self.aimPunchAngles * self.recoilControl):normalize()
    end

    self.lookAtAngles = correctedViewAngles
    cmd.pitch = correctedViewAngles.p
    cmd.yaw = correctedViewAngles.y

    self.overrideViewAngles = nil
    self.isViewLocked = false

    -- Reset noise. Defaults to none at all.
    self:setNoiseType(AiViewNoiseType.NONE)

    if Config.isDebugging then
        print(self.lookNote)
    end

    self.lookNote = nil

    -- Shoot out cover
    local shootNode = self.nodegraph:getClosestNodeOf(origin, {Node.types.SHOOT, Node.types.CROUCH_SHOOT})

    if shootNode and origin:getDistance(shootNode.origin) < 40 then
        local diff = correctedViewAngles:getMaxDiff(shootNode.direction)

        if diff < 135 and self:isPlayerBlocked(shootNode) then
            self.overrideViewAngles = shootNode.direction
            self.lookSpeed = 4
            self.isViewLocked = true

            if diff < 15 then
                cmd.in_attack = 1
            end
        end
    end

    -- Use doors
    local node = self.nodegraph:getClosestNodeOf(origin, Node.types.DOOR)

    if node and origin:getDistance(node.origin) < 128 then
        local diff = correctedViewAngles:getMaxDiff(node.direction)

        if diff < 150 and self:isPlayerBlocked(node) then
            self.overrideViewAngles = node.direction
            self.lookSpeed = 4
            self.isViewLocked = true

            if self.useCooldown:isElapsedThenRestart(0.5) and diff < 15 then
                cmd.in_use = 1
            end
        elseif AiUtility.client:m_vecVelocity():getMagnitude() < 50 then
            if self.useCooldown:isElapsedThenRestart(0.5) and diff < 15 then
                cmd.in_use = 1
            end
        end
    end
end

--- @param origin Vector3
--- @param speed number
--- @param noise number
--- @return void
function AiView:lookAtLocation(origin, speed, noise, note)
    if self.isViewLocked then
        return
    end

    self.overrideViewAngles = Client.getEyeOrigin():getAngle(origin)
    self.lookSpeed = speed
    self.lastLookAtLocationOrigin = origin

    self:setNoiseType(noise or AiViewNoiseType.NONE)

    self.lookNote = note
end

--- @param angle Angle
--- @param speed number
--- @param noise number
--- @return void
function AiView:lookInDirection(angle, speed, noise, note)
    if self.isViewLocked then
        return
    end

    self.overrideViewAngles = angle
    self.lookSpeed = speed
    self.lastLookAtLocationOrigin = nil

    self:setNoiseType(noise or AiViewNoiseType.NONE)

    self.lookNote = note
end

--- @param node Node
--- @return boolean
function AiView:isPlayerBlocked(node)
    local playerOrigin = AiUtility.client:getOrigin()
    local collisionOrigin = playerOrigin + node.direction:getForward() * 25
    local collisionBounds = collisionOrigin:getBounds(Vector3.align.CENTER, 32, 32, 64)

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():offset(0, 0, 36):isInBounds(collisionBounds) then
            return false
        end
    end

    local nodeOrigin = node.origin:clone():offset(0, 0, 40)
    local offset = nodeOrigin + node.direction:getForward() * 48
    local trace = Trace.getLineToPosition(nodeOrigin, offset, AiUtility.traceOptionsPathfinding)

    return trace.isIntersectingGeometry
end

return Nyx.class("AiView", AiView)
--}}}
