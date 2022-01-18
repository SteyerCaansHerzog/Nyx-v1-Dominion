--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateCheck
--- @class AiStateCheck : AiState
--- @field node Node
--- @field isChecking boolean
local AiStateCheck = {
    name = "Check"
}

--- @param fields AiStateCheck
--- @return AiStateCheck
function AiStateCheck:new(fields)
    return Nyx.new(self, fields)
end

--- @return nil
function AiStateCheck:__init()
    Callbacks.roundStart(function()
    	self:reset()
    end)
end

--- @return nil
function AiStateCheck:assess()
    return self.isChecking and AiState.priority.CHECK or AiStateCheck.priority.IGNORE
end

--- @param ai AiOptions
--- @param spawn string
--- @return nil
function AiStateCheck:activate(ai, spawn)
    self.node = self:getSpawn(ai, spawn)

    local spawn = self.node

    if not spawn then
        return
    end

    self.isChecking = true

    local objectiveName = Node.typesName[spawn.type]

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

--- @return nil
function AiStateCheck:reset()
    self.isChecking = false
end

--- @param ai AiOptions
--- @return nil
function AiStateCheck:think(ai) end

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
