--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiStateCheck
--- @class AiStateCheck : AiStateBase
--- @field node Node
--- @field isChecking boolean
--- @field abortDistance number
--- @field spawn string
local AiStateCheck = {
    name = "Check"
}

--- @param fields AiStateCheck
--- @return AiStateCheck
function AiStateCheck:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateCheck:__init()
    self.abortDistance = Math.getRandomInt(64, 256)

    Callbacks.roundPrestart(function()
    	self:reset()
    end)
end

--- @return void
function AiStateCheck:assess()
    return self.isChecking and AiPriority.CHECK_SPAWN or AiPriority.IGNORE
end

--- @return void
function AiStateCheck:activate()
    Pathfinder.moveToNode(self.node, {
        task = string.format("Check %s spawn", self.spawn),
        goalReachedRadius = 200,
        onReachedGoal = function()
        	self:reset()
        end
    })
end

--- @return void
function AiStateCheck:reset()
    self.isChecking = false
end

--- @return void
function AiStateCheck:deactivate() end

--- @param spawn string
--- @return void
function AiStateCheck:invoke(spawn)
    self.isChecking = true

    self:setActivityNode(spawn)
    self:queueForReactivation()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateCheck:think(cmd)
    local distance = LocalPlayer:getOrigin():getDistance(self.node.origin)

    if distance < 400 then
        self.activity = string.format("Checking %s", self.spawn)
    else
        self.activity = string.format("Going to check %s", self.spawn)
    end

    Pathfinder.canRandomlyJump()

    if distance < self.abortDistance then
        self.isChecking = false
    end
end

--- @param spawn string
--- @return Node
function AiStateCheck:setActivityNode(spawn)
    self.spawn = spawn
    self.node = Nodegraph.getSpawn(spawn)
end

return Nyx.class("AiStateCheck", AiStateCheck, AiStateBase)
--}}}
