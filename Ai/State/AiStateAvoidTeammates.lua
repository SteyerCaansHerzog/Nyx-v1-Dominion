--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
--}}}

--{{{ AiStateAvoidTeammates
--- @class AiStateAvoidTeammates : AiStateBase
--- @field timer Timer
local AiStateAvoidTeammates = {
    name = "Avoid Teammates",
    isLockable = false
}

--- @param fields AiStateAvoidTeammates
--- @return AiStateAvoidTeammates
function AiStateAvoidTeammates:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateAvoidTeammates:__init()
    self.timer = Timer:new()
end

--- @return void
function AiStateAvoidTeammates:assess()
    if AiUtility.gameRules:m_bFreezePeriod() == 1 then
        return AiPriority.IGNORE
    end

    if Pathfinder.isObstructedByTeammate and LocalPlayer:m_vecVelocity():getMagnitude() < 50 then
        self.timer:ifPausedThenStart()
    else
        self.timer:stop()
    end

    self.timer:isElapsedThenStop(3)

    if self.timer:isElapsed(2) then
        return AiPriority.AVOID_TEAMMATES
    end

    return AiPriority.IGNORE
end

--- @return void
function AiStateAvoidTeammates:activate()
    self:move()
end

--- @return void
function AiStateAvoidTeammates:deactivate() end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateAvoidTeammates:think(cmd)
    self.activity = "Avoiding teammates"

    if Pathfinder.isIdle() then
        self:move()
    end
end

--- @return void
function AiStateAvoidTeammates:move()
    Pathfinder.moveToNode(self:getCoverNode(4096, AiUtility.closestTeammate, 90), {
        task = "Get away from teammate",
        isAllowedToTraverseInactives = true,
        isPathfindingFromNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeIfNoConnections = true,
        isPathfindingToNearestNodeOnFailure = true,
    })
end

return Nyx.class("AiStateAvoidTeammates", AiStateAvoidTeammates, AiStateBase)
--}}}
