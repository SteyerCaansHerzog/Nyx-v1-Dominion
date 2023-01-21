--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
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
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateRotate
--- @class AiStateRotate : AiStateBase
--- @field isActive boolean
--- @field site string
--- @field node Node
--- @field bounds Vector3[]
local AiStateRotate = {
    name = "Rotate",
    requiredNodes = {
        Node.objectiveBombsiteA,
        Node.objectiveBombsiteB
    },
    requiredGamemodes = {
        AiUtility.gamemodes.DEMOLITION,
        AiUtility.gamemodes.WINGMAN,
    }
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

    Callbacks.bombBeginPlant(function(e)
        if not LocalPlayer:isCounterTerrorist() then
            return
        end

        Client.fireAfterRandom(0, 1, function()
            self:invoke(AiUtility.getBombsiteFromIdx(e.site))
        end)
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
    if not self.node or not self.site then
        return
    end

    self.ai.routines.walk:block()

    self.activity = string.format("Rotating to %s", self.site:upper())

    Pathfinder.canRandomlyJump()

    if LocalPlayer:getOrigin():isInBounds(self.bounds) then
        self:reset()
    end
end

--- @param site string
--- @return void
function AiStateRotate:invoke(site)
    self.isActive = true
    self.site = site
    self.node = Nodegraph.getBombsite(site)
    self.bounds = self.node.origin:getBounds(Vector3.align.CENTER, 800, 800, 128)

    Pathfinder.blockRoute(self.node)

    self:queueForReactivation()
end

--- @return void
function AiStateRotate:move()
    Pathfinder.moveToNode(self.node, {
        task = string.format("Rotate to bombsite %s", self.site)
    })
end

return Nyx.class("AiStateRotate", AiStateRotate, AiStateBase)
--}}}
