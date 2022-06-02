--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateDeveloper
--- @class AiStateDeveloper : AiStateBase
--- @field origin Vector3
--- @field angles Angle
--- @field timerA Timer
--- @field timerB Timer
local AiStateDeveloper = {
    name = "Developer"
}

--- @param fields AiStateDeveloper
--- @return AiStateDeveloper
function AiStateDeveloper:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDeveloper:__init()
    self.origin = Vector3:new()
    self.angles = Angle:new()
    self.timerA = Timer:new():startThenElapse()
    self.timerB = Timer:new():startThenElapse()
end

--- @return void
function AiStateDeveloper:assess()
    return AiPriority.IGNORE
end

--- @return void
function AiStateDeveloper:activate()
    -- Kirsty.
    if LocalPlayer:getSteamId64() == "76561198816968549" then
        Pathfinder.moveToNode(Nodegraph.getById(155))
    end

    -- Bropp.
    if LocalPlayer:getSteamId64() == "76561198373386496" then
        Pathfinder.moveToNode(Nodegraph.getById(270))
    end

    -- Retard community banned.
    if LocalPlayer:getSteamId64() == "76561198117895205" then
        Pathfinder.moveToNode(Nodegraph.getById(172))
    end
end

--- @return void
function AiStateDeveloper:reset() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDeveloper:think(cmd)
    self.activity = "Testing"

    if self.timerA:isElapsedThenRestart(2) then
        self:move()
    end

    if self.timerA:isElapsed(0.1) then
        View.lookAtLocation(self.origin, 5, View.noise.none)
    end
end

--- @return void
function AiStateDeveloper:move()
    Pathfinder.moveToNode(Nodegraph.getRandom(Node.traverseGeneric), {
        task = "Developer test"
    })

    self.angles = self.angles:offset(2, 15)
    self.timerA:restart()
end

return Nyx.class("AiStateDeveloper", AiStateDeveloper, AiStateBase)
--}}}
