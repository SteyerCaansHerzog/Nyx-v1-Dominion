--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiStateDeveloper
--- @class AiStateDeveloper : AiState
local AiStateDeveloper = {
    name = "Developer"
}

--- @param fields AiStateDeveloper
--- @return AiStateDeveloper
function AiStateDeveloper:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDeveloper:__init() end

--- @return void
function AiStateDeveloper:assess()
    return AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateDeveloper:activate(ai) end

--- @return void
function AiStateDeveloper:reset() end

--- @param ai AiOptions
--- @return void
function AiStateDeveloper:think(ai) end

return Nyx.class("AiStateDeveloper", AiStateDeveloper, AiState)
--}}}
