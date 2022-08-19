--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
--}}}

--{{{ Modules
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateEvacuate
--- @class AiStateEvacuate : AiStateBase
--- @field isBombPlanted boolean
--- @field isForcedToSave boolean
--- @field node NodeSpotHide
--- @field isAtDestination boolean
--- @field isAutomaticSavingAllowed boolean
--- @field isSaving boolean
local AiStateEvacuate = {
    name = "Evacuate",
    requiredNodes = {
        Node.spotHideCt,
        Node.spotHideT,
    }
}

--- @param fields AiStateEvacuate
--- @return AiStateEvacuate
function AiStateEvacuate:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateEvacuate:__init()
    self.isForcedToSave = false
    self.isAutomaticSavingAllowed = true

    Callbacks.roundPrestart(function()
    	self:reset()
    end)
end

--- @return void
function AiStateEvacuate:assess()
    self.isSaving = false

    -- A human has told us to save this round.
    if self.isForcedToSave then
        self.isSaving = true

        return AiPriority.SAVE_ROUND
    end

    if LocalPlayer:isCounterTerrorist() then
        -- We're defusing, we shouldn't evacuate.
        -- We can only be defusing if we have time.
        if LocalPlayer:m_bIsDefusing() == 1 then
            return AiPriority.IGNORE
        end

        -- We should save.
        if self:isRoundWinProbabilityLow() then
            self.isSaving = true

            return AiPriority.SAVE_ROUND
        end

        -- We're not able to defuse the bomb due to time.
        if AiUtility.plantedBomb and not AiUtility.canDefuse then
            self.isSaving = true

            return AiPriority.SAVE_ROUND
        end
    elseif LocalPlayer:isTerrorist() then
        -- Do not leave the bombsite if the CTs are near the site and could potentially defuse.
        if AiUtility.plantedBomb then
            local bombOrigin = AiUtility.plantedBomb:m_vecOrigin()

            for _, enemy in pairs(AiUtility.enemies) do
                if enemy:getOrigin():getDistance(bombOrigin) < 1000 then
                    return AiPriority.IGNORE
                end
            end
        end

        -- We should save.
        if self:isRoundWinProbabilityLow()then
            self.isSaving = true

            return AiPriority.SAVE_ROUND
        end

        local bombTimeThreshold = LocalPlayer:m_iHealth() > 50 and 12 or 16

        -- The enemy likely cannot defuse now, and we need to leave the site.
        if AiUtility.plantedBomb and not AiUtility.isBombBeingDefusedByEnemy and AiUtility.bombDetonationTime < bombTimeThreshold then
            return AiPriority.ABANDON_BOMBSITE
        end
    end

    -- Round is effectively over.
    if AiUtility.isRoundOver and AiUtility.enemiesAlive == 0 then
        return AiPriority.ROUND_OVER
    end

    return AiPriority.IGNORE
end

--- @return boolean
function AiStateEvacuate:isRoundWinProbabilityLow()
    -- Allow the user to disable automatic saving.
    if not self.isAutomaticSavingAllowed then
        return false
    end

    -- Prevent sitting in a corner and being murdered.
    if self.isAtDestination and AiUtility.isClientThreatenedMinor then
        return false
    end

    local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
    local maxRounds = cvar.mp_maxrounds:get_int()
    local halfTime = math.ceil(maxRounds / 2)

    -- First round, last round of half, last round of game.
    if roundsPlayed == 0 or roundsPlayed == (maxRounds - 1) or roundsPlayed == (halfTime - 1) then
        return false
    end

    -- We have no valuables.
    if not LocalPlayer:hasPrimary() then
        return false
    end

    local teamDisparity = AiUtility.teammatesAlive - AiUtility.enemiesAlive
    local isBombPlanted = AiUtility.isBombPlanted()

    if LocalPlayer:isCounterTerrorist() then
        -- 5v1 scenario.
        if teamDisparity <= -4 then
            return true
        end

        -- Bomb is down. This makes our odds really bad.
        if isBombPlanted then
            -- 5v2 scenario.
            if teamDisparity <= -3 then
                return true
            end

            -- We're last, there's 2+ enemies, and we're low.
            if AiUtility.isLastAlive and AiUtility.enemiesAlive >= 2 and LocalPlayer:m_iHealth() <= 33 then
                return true
            end
        end
    elseif LocalPlayer:isTerrorist() then
        -- We haven't planted. This makes our odds really bad.
        if not isBombPlanted then
            -- 5v1 scenario.
            if teamDisparity <= -4 then
                return true
            end

            -- We're last, there's 2+ enemies, and we're low.
            if AiUtility.isLastAlive and AiUtility.enemiesAlive >= 3 and LocalPlayer:m_iHealth() <= 33 then
                return true
            end
        end
    end

    return false
end

--- @return void
function AiStateEvacuate:activate()
    local node = self:getHideNode()

    if not node then
        return
    end

    self.isBombPlanted = AiUtility.isBombPlanted()
    self.node = node
    self.isAtDestination = false

    Pathfinder.moveToNode(node, {
        task = "Evacuate to hiding spot",
        onReachedGoal = function()
        	self.isAtDestination = true
        end
    })
end

--- @return void
function AiStateEvacuate:reset()
    self.isForcedToSave = false
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateEvacuate:think(cmd)
    if not self.node then
        self:activate()

        return
    end

    if not self.isBombPlanted and AiUtility.isBombPlanted() then
        self:activate()
    end

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():getDistance(self.node.origin) < 40 then
            self:activate()
        end
    end

    self.activity = "Going to hide"

    local findSpotVisibleTrace = Trace.getLineToPosition(LocalPlayer:getEyeOrigin(), self.node.origin, AiUtility.traceOptionsAttacking, "AiStateEvacuate.think<FindSpotVisible>")
    local distance = LocalPlayer:getOrigin():getDistance(self.node.origin)

    Pathfinder.canRandomlyJump()

    if distance < 32 then
        Pathfinder.duck()
    end

    if not findSpotVisibleTrace.isIntersectingGeometry and distance < 200 then
        self.activity = "Hiding"

        self.ai.routines.manageGear:block()

        LocalPlayer.equipAvailableWeapon()

        local lookOrigin = self.node.origin:clone():offset(0, 0, 46)
        local findLookAngleTrace = Trace.getLineAtAngle(lookOrigin, self.node.direction, AiUtility.traceOptionsPathfinding, "AiStateEvacuate.think<FindLookAngle>")

       View.lookAtLocation(findLookAngleTrace.endPosition, 4, View.noise.none, "Evacuate look at angle")
    end

    if not self.isAtDestination and Pathfinder.isIdle() then
        Pathfinder.retryLastRequest()
    end
end

--- @return NodeSpotHide
function AiStateEvacuate:getHideNode()
    --- @type NodeSpotHide[]
    local nodes = {}
    local clientOrigin = LocalPlayer:getOrigin()
    local bombOrigin = AiUtility.plantedBomb and AiUtility.plantedBomb:m_vecOrigin()
    local nodeClass

    if LocalPlayer:isTerrorist() then
        nodeClass = Nodegraph.get(Node.spotHideT)
    elseif LocalPlayer:isCounterTerrorist() then
        nodeClass = Nodegraph.get(Node.spotHideCt)
    end

    for _, node in pairs(nodeClass) do repeat
        if clientOrigin:getDistance(node.origin) < 1000 then
            break
        end

        if bombOrigin and bombOrigin:getDistance(node.origin) < 2000 then
            break
        end

        table.insert(nodes, node)
    until true end

    return Table.getRandom(nodes)
end

return Nyx.class("AiStateEvacuate", AiStateEvacuate, AiStateBase)
--}}}
