--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
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
    return self.isChecking and AiState.priority.CHECK_SPAWN or AiStateCheck.priority.IGNORE
end

--- @param ai AiOptions
--- @param spawn string
--- @return void
function AiStateCheck:activate(ai, spawn)
    self.node = self:getSpawn(ai, spawn)

    local spawn = self.node

    if not spawn then
        return
    end

    self.isChecking = true

    local objectiveName = Node.typesName[spawn.type]

    self.objectiveName = objectiveName

    ai.nodegraph:pathfind(spawn.origin, {
        objective = Node.types.GOAL,
        retry = false,
        ignore = Client.getEid(),
        task = string.format("Checking %s", objectiveName),
        onComplete = function()
            ai.nodegraph:log("Checked %s", objectiveName)

            self.isChecking = false
        end
    })
end

--- @return void
function AiStateCheck:reset()
    self.isChecking = false
end

--- @param ai AiOptions
--- @return void
function AiStateCheck:think(ai)
    self.activity = string.format("Going to check %s", self.objectiveName)

    local distance = AiUtility.client:getOrigin():getDistance(self.node.origin)

    if distance < 350 then
        self.activity = string.format("Checking %s", self.objectiveName)
    end

    if distance < self.abortDistance then
        self.isChecking = false
    end
end

--- @param ai AiOptions
--- @param spawn string
--- @return Node
function AiStateCheck:getSpawn(ai, spawn)
    if not spawn then
        return self.node
    end

    if spawn == "ct" then
        return ai.nodegraph.ctSpawn
    elseif spawn == "t" then
        return ai.nodegraph.tSpawn
    end
end

return Nyx.class("AiStateCheck", AiStateCheck, AiState)
--}}}
