--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateCheck
--- @class AiStateCheck : AiState
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
    self.abortDistance = Client.getRandomInt(64, 256)

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

    self.ai.nodegraph:pathfind(self.node.origin, {
        objective = Node.types.GOAL,
        task = string.format("Checking %s", objectiveName),
        onComplete = function()
            self.ai.nodegraph:log("Checked %s", objectiveName)

            self.isChecking = false
        end
    })
end

--- @return void
function AiStateCheck:reset()
    self.isChecking = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateCheck:think(cmd)
    self.activity = string.format("Going to check %s", self.objectiveName)

    local distance = AiUtility.client:getOrigin():getDistance(self.node.origin)

    if distance < 350 then
        self.activity = string.format("Checking %s", self.objectiveName)
    end

    if distance < self.abortDistance then
        self.isChecking = false
    end
end

--- @param spawn string
--- @return Node
function AiStateCheck:getSpawn(spawn)
    if not spawn then
        return self.node
    end

    if spawn == "ct" then
        return self.ai.nodegraph.objectiveCtSpawn
    elseif spawn == "t" then
        return self.ai.nodegraph.objectiveTSpawn
    end
end

return Nyx.class("AiStateCheck", AiStateCheck, AiState)
--}}}
