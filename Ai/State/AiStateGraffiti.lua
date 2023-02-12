--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateGraffiti
--- @class AiStateGraffiti : AiStateBase
--- @field graffitiDelayTimer Timer
--- @field isEnabled boolean
--- @field killCount number
--- @field lastKillCutoff number
--- @field lastKillTimer Timer
local AiStateGraffiti = {
    name = "Graffiti",
    delayedMouseMin = 0,
    delayedMouseMax = 0
}

--- @param fields AiStateGraffiti
--- @return AiStateGraffiti
function AiStateGraffiti:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateGraffiti:__init()
    self.isEnabled = true
    self.killCount = 0
    self.lastKillTimer = Timer:new()
    self.lastKillCutoff = 8
    self.graffitiDelayTimer = Timer:new()

    Callbacks.playerDeath(function(e)
        if not e.attacker:isLocalPlayer() or e.victim:isTeammate() then
            return
        end

        if e.victim:isLocalPlayer() then
            self.killCount = 0
        end

        self.lastKillTimer:start()

        self.killCount = self.killCount + 1
    end)

    Callbacks.roundStart(function()
        self.killCount = 0
        self.isEnabled = true
    end)
end

--- @return void
function AiStateGraffiti:assess()
    if not self.isEnabled then
        return AiPriority.IGNORE
    end

    if self.lastKillTimer:isElapsedThenStop(self.lastKillCutoff) then
        self.killCount = 0
    end

    if AiUtility.isClientThreatenedMinor then
        return AiPriority.IGNORE
    end

    if LocalPlayer.getGraffitiCooldown() > 0 then
        return AiPriority.IGNORE
    end

    -- Kill count is reset after lastKillTimer expires.
    -- Bots should spray when they get a 3K or better within the cutoff time.
    if self.killCount < 3 then
        return AiPriority.IGNORE
    end

    return AiPriority.GRAFFITI
end

--- @return void
function AiStateGraffiti:think()
    self.activity = "Spraying graffiti"

    local newCameraAngles = LocalPlayer.getCameraAngles():set(80)

    VirtualMouse.lookAlongAngle(newCameraAngles, 6, VirtualMouse.noise.minor, "Graffiti look at floor")

    if LocalPlayer.getCameraAngles().p > 75 then
        self.isEnabled = false

        LocalPlayer.sprayGraffiti()
    end
end

return Nyx.class("AiStateGraffiti", AiStateGraffiti, AiStateBase)
--}}}
