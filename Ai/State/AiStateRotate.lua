--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateRotate
--- @class AiStateRotate : AiState
--- @field isActive boolean
--- @field site string
--- @field node Node
--- @field bounds Vector3[]
local AiStateRotate = {
    name = "Rotate"
}

--- @param fields AiStateRotate
--- @return AiStateRotate
function AiStateRotate:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateRotate:__init()
    Callbacks.roundStart(function()
    	self:reset()
    end)
end

--- @return void
function AiStateRotate:assess()
    return self.isActive and AiPriority.ROTATE or AiPriority.IGNORE
end

--- @return void
function AiStateRotate:activate()
    self:move()
end

--- @return void
function AiStateRotate:reset()
    self.isActive = false
    self.site = nil
    self.node = nil
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateRotate:think(cmd)
    self.activity = string.format("Rotating to %s", self.site:upper())

    if self.ai.nodegraph:isIdle() then
        self:move()
    end

    if LocalPlayer:getOrigin():isInBounds(self.bounds) then
        self:reset()
    end
end

--- @param site string
--- @return void
function AiStateRotate:rotate(site)
    self.isActive = true
    self.site = site
    self.node = self.ai.nodegraph:getSiteNode(site)
    self.bounds = self.node.origin:getBounds(Vector3.align.CENTER, 800, 800, 128)
end

--- @return void
function AiStateRotate:move()
    self.ai.nodegraph:pathfind(self.node.origin, {
        objective = Node.types.GOAL,
        task = string.format("Rotating to %s", self.site:upper())
    })
end

return Nyx.class("AiStateRotate", AiStateRotate, AiState)
--}}}
