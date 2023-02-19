--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
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
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
local Logger = require "gamesense/Nyx/v1/Dominion/Utility/Logger"
--}}}

--{{{ Vars
--}}}

--{{{ AiStateDeveloper
--- @class AiStateDeveloper : AiStateBase
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
    return AiPriority.IGNORE
end

--- @return void
function AiStateDeveloper:activate()
    Pathfinder.moveToNode(Nodegraph.getById(764))
end

--- @return void
function AiStateDeveloper:reset() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDeveloper:think(cmd)
    self.activity = "Under maintenance"
end

--- @return void
function AiStateDeveloper:move() end

return Nyx.class("AiStateDeveloper", AiStateDeveloper, AiStateBase)
--}}}
