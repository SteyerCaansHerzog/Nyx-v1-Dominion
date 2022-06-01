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
--- @field objectiveName string
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

    Callbacks.roundStart(function()
    	self:reset()
    end)
end

--- @return void
function AiStateCheck:assess()
    return self.isChecking and AiPriority.CHECK_SPAWN or AiPriority.IGNORE
end

--- @param spawn string
--- @return void
function AiStateCheck:activate(spawn)
    self.node = self:getSpawn(spawn)

    if not self.node then
        return
    end

    local objectiveName = Node.typesName[self.node.type]

    self.objectiveName = objectiveName
    self.isChecking = true

    Pathfinder.moveToNode(self.node, {
        task = string.format("Check %s spawn", spawn),
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
function AiStateCheck:deactivate()
    self:reset()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateCheck:think(cmd)
    self.activity = string.format("Going to check %s", self.objectiveName)

    local distance = LocalPlayer:getOrigin():getDistance(self.node.origin)

    if distance < 350 then
        self.activity = string.format("Checking %s", self.objectiveName)
    end

    if distance < self.abortDistance then
        self.isChecking = false
    end

    Pathfinder.ifIdleThenRetryLastRequest()
end

--- @param spawn string
--- @return Node
function AiStateCheck:getSpawn(spawn)
    if not spawn then
        return self.node
    end

    if spawn == "CT" then
        return Nodegraph.getOne(Node.objectiveCtSpawn)
    elseif spawn == "T" then
        return Nodegraph.getOne(Node.objectiveTSpawn)
    end
end

return Nyx.class("AiStateCheck", AiStateCheck, AiStateBase)
--}}}
