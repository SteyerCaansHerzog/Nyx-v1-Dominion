--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
--}}}
--{{{ AiStateGraffiti
--- @class AiStateGraffiti : AiState
--- @field killCount number
--- @field lastKillTimer Timer
--- @field lastKillCutoff number
local AiStateGraffiti = {
    name = "Graffiti"
}

--- @param fields AiStateGraffiti
--- @return AiStateGraffiti
function AiStateGraffiti:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateGraffiti:__init()
    self.killCount = 0
    self.lastKillTimer = Timer:new()
    self.lastKillCutoff = 6

    Callbacks.playerDeath(function(e)
        if not e.attacker:isClient() or e.victim:isTeammate() then
            return
        end

        if e.victim:isClient() then
            self.killCount = 0
        end

        self.lastKillTimer:restart()

        self.killCount = self.killCount + 1
    end)

    Callbacks.roundStart(function()
        self.killCount = 0
    end)
end

--- @return void
function AiStateGraffiti:assess()
    if self.lastKillTimer:isElapsedThenStop(self.lastKillCutoff) then
        self.killCount = 0
    end

    if Client.getGraffitiCooldown() > 0 then
        return AiState.priority.IGNORE
    end

    -- Kill count is reset after lastKillTimer expires.
    -- Bots should spray when they get a 3K or better within the cutoff time.
    if self.killCount < 3 then
        return AiState.priority.IGNORE
    end

    return AiState.priority.GRAFFITI
end

--- @param ai AiOptions
--- @return void
function AiStateGraffiti:think(ai)
    local newCameraAngles = Client.getCameraAngles()

    newCameraAngles.p = 80

    ai.view:look(newCameraAngles, 6)

    if Client.getCameraAngles().p > 75 then
        self.killCount = 0

        Client.sprayGraffiti()
    end
end

return Nyx.class("AiStateGraffiti", AiStateGraffiti, AiState)
--}}}
