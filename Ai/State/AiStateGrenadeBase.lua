--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local GrenadePrediction = require "gamesense/Nyx/v1/Api/GrenadePrediction"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local VirtualMouse = require "gamesense/Nyx/v1/Dominion/VirtualMouse/VirtualMouse"
--}}}

--{{{ AiStateGrenadeBase
--- @class AiStateGrenadeBase : AiStateBase
--- @field cooldown number
--- @field equipFunction fun(): nil
--- @field isCheckingEnemiesRequired boolean
--- @field nodeDefendCt string
--- @field nodeDefendT string
--- @field nodeExecuteT string
--- @field nodeRetakeCt string
--- @field priorityLineup number
--- @field priorityThrow number
--- @field rangeThreshold number
--- @field weapons string[]
--- @field isDamaging boolean
--- @field isInferno boolean
--- @field isSmoke boolean
---
--- @field cooldownTimer Timer
--- @field inBehaviorTimer Timer
--- @field isInThrow boolean
--- @field node NodeTypeGrenade
--- @field isAtDestination boolean
--- @field threatCooldownTimer Timer
--- @field throwTime number
--- @field startThrowTimer Timer
--- @field usedNodes Timer[]
--- @field throwHoldTimer Timer
--- @field isThrown boolean
--- @field selectedLineup boolean
local AiStateGrenadeBase = {
    name = "GrenadeBase",
    delayedMouseMin = 0,
    delayedMouseMax = 0.15,
    usedNodes = {},
    rangeThreshold = 2000
}

--- @param fields AiStateGrenadeBase
--- @return AiStateGrenadeBase
function AiStateGrenadeBase:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateGrenadeBase:__init()
    self.inBehaviorTimer = Timer:new()
    self.startThrowTimer = Timer:new()
    self.throwTime = 0.2
    self.threatCooldownTimer = Timer:new():startThenElapse()
    self.cooldownTimer = Timer:new():startThenElapse()
    self.throwHoldTimer = Timer:new()

    Callbacks.roundStart(function()
        self:reset()
    end)

    Callbacks.runCommand(function()
    	self:watchForOccupiedNodes()
    end)

    Callbacks.grenadeThrown(function(e)
        if e.player:isLocalPlayer() then
            self.isInThrow = false
            self.node = nil

            self.cooldownTimer:start()
        end
    end)
end

--- @return void
function AiStateGrenadeBase:assess()
    -- They suck at throwing nade lineups during retakes. We're just going to ban it as a quick fix.
    if AiUtility.plantedBomb then
        return AiPriority.IGNORE
    end

    -- Stick to the selected lineup and not select another one prematurely.
    if self.selectedLineup and self.selectedLineup ~= self.__classid then
        return AiPriority.IGNORE
    end

    -- Hold a throw. Used for making run line-ups work correctly.
    if self.throwHoldTimer:isNotElapsed(0.5) then
        return self.priorityThrow
    end

    -- Do not waste time with nades when bomb is close to detonation.
    if AiUtility.plantedBomb and AiUtility.bombDetonationTime <= 18 and LocalPlayer:isCounterTerrorist() then
        return AiPriority.IGNORE
    end

    -- No need to use grenades.
    if AiUtility.isRoundOver or AiUtility.enemiesAlive == 0 then
        return AiPriority.IGNORE
    end

    -- Ignore before round starts. Otherwise we can trip the cooldown.
    if AiUtility.gameRules:m_bFreezePeriod() == 1 then
        return AiPriority.IGNORE
    end

    -- Do not throw smokes etc. when the round has just begun.
    if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE and AiUtility.timeData.roundtime_elapsed <= 15 then
        return AiPriority.IGNORE
    end

    -- We're on a cooldown from using the current type of grenade.
    if not self.cooldownTimer:isElapsed(self.cooldown) then
        return AiPriority.IGNORE
    end

    -- We don't have the type of grenade in question.
    if not LocalPlayer:hasWeapons(self.weapons) then
        return AiPriority.IGNORE
    end

    -- We're threatened by an enemy.
    if AiUtility.isClientThreatenedMajor then
        self.threatCooldownTimer:restart()

        return AiPriority.IGNORE
    end

    -- Prevent dithering with enemy presence.
    if not self.threatCooldownTimer:isElapsed(3) then
        return AiPriority.IGNORE
    end

    -- Enemy is interacting with hostages.
    if AiUtility.isHostageCarriedByEnemy or AiUtility.isHostageBeingPickedUpByEnemy then
        return AiPriority.IGNORE
    end

    -- Enemy is interacting with the bomb.
    if AiUtility.isBombBeingDefusedByEnemy or AiUtility.isBombBeingPlantedByEnemy then
        return AiPriority.IGNORE
    end

    -- We already have a line-up.
    -- Only exit here if we're in throw, because we need to ensure teammates don't occupy our line-up
    -- after we've picked it.
    if self.node then
        if AiStateGrenadeBase.usedNodes[self.node.id] and not AiStateGrenadeBase.usedNodes[self.node.id]:isElapsed(15) then
            self:reset()

            return AiPriority.IGNORE
        end

        -- We're about to throw a grenade.
        if self.isInThrow then
            return self.priorityThrow
        end

        return self.priorityLineup
    end

    -- Find all possible line-ups.
    local nodes = self:getNodes()

    -- No nodes on the map.
    if not nodes then
        return AiPriority.IGNORE
    end

    -- Find the best line-up for the type of grenade we want to use.
    local node = self:getBestLineup(nodes)

    -- Something went wrong when finding a line-up. Possibly all nodes are unavailable.
    if not node then
        return AiPriority.IGNORE
    end

    self.node = node

    -- We've got a line-up to use.
    return self.priorityLineup
end

--- @param nodes NodeTypeGrenade[]
--- @return NodeTypeGrenade
function AiStateGrenadeBase:getBestLineup(nodes)
    -- Should we check if enemies could be affected by the line-up?
    local isCheckingEnemies = true

    if LocalPlayer:isTerrorist() and (AiUtility.timeData.roundtime_elapsed < 20) and not self.isCheckingEnemiesRequired then
        isCheckingEnemies = false
    end

    local clientOrigin = LocalPlayer:getOrigin()
    local clientCenter = clientOrigin:offset(0, 0, 48)

    --- @type NodeTypeGrenade
    local closestNode
    local closestDistance = math.huge

    -- Find a suitable grenade line-up to use.
    for _, node in pairs(nodes) do repeat
        local distance = clientOrigin:getDistance(node.origin)

        if distance > 600 or distance >= closestDistance then
            break
        end

        local usedNodeTimer = AiStateGrenadeBase.usedNodes[node.id]

        -- A teammate has already used this node.
        if usedNodeTimer and not usedNodeTimer:isElapsed(15) then
            break
        end

        local bounds = node.origin:getBounds(Vector3.align.BOTTOM, 500, 500, 64)

        if not clientCenter:isInBounds(bounds) then
            break
        end

        local isValidGrenadeNode = true

        -- We care if enemies could be affected by this line-up.
        if isCheckingEnemies then
            isValidGrenadeNode = self:isEnemyThreatenedByNode(node)
        end

        -- This line-up is no use to us.
        if not isValidGrenadeNode then
            break
        end

        closestDistance = distance
        closestNode = node
    until true end

    return closestNode
end

--- @param node NodeTypeGrenade
--- @return boolean
function AiStateGrenadeBase:isEnemyThreatenedByNode(node)
    for _, enemy in pairs(AiUtility.enemies) do repeat
        local enemyOrigin = enemy:getOrigin()
        local enemyDistance = node.origin:getDistance(enemyOrigin)
        local range = (node.isRun or node.isJump) and self.rangeThreshold or self.rangeThreshold * 0.65

        -- Enemy is too far away.
        if enemyDistance > range then
            break
        end

        local fov = node.direction:clone():set(0, nil):getFov(node.origin, enemyOrigin)

        -- Enemy is not within an acceptable field of view.
        if fov > 65 then
            break
        end

        return true
    until true end

    return false
end

--- @return void
function AiStateGrenadeBase:watchForOccupiedNodes()
    -- Find all possible line-ups.
    local nodes = self:getNodes()

    if not nodes then
        return
    end

    local clientOrigin = LocalPlayer:getOrigin()

    for _, node in pairs(nodes) do repeat
        local distance = clientOrigin:getDistance(node.origin)

        if distance > 2000 then
            break
        end

        if not AiStateGrenadeBase.usedNodes[node.id] then
            AiStateGrenadeBase.usedNodes[node.id] = Timer:new():startThenElapse()
        end

        local isOccupied = false

        for _, teammate in pairs(AiUtility.teammates) do
            if teammate:getOrigin():getDistance2(node.origin) < 40 and teammate:isHoldingWeapons(self.weapons) then
                isOccupied = true

                break
            end
        end

        if isOccupied then
           AiStateGrenadeBase.usedNodes[node.id]:restart()
        end
    until true end
end

--- @return void
function AiStateGrenadeBase:activate()
    if not self:isAllowedToThrow() then
        AiStateGrenadeBase.usedNodes[self.node.id]:restart()

        return
    end

    local bounds = self.node.origin:getBounds(Vector3.align.BOTTOM, 500, 500, 64)

    -- The AI can cling onto lineups since we select the node in assess, but may not run the think afterwards.
    -- This just checks if we're within the bounds when we try to run this state. If not we probably don't want to run this at all.
    if not LocalPlayer:getOrigin():offset(0, 0, 48):isInBounds(bounds) then
        AiStateGrenadeBase.usedNodes[self.node.id]:restart()

        return
    end

    self.isAtDestination = false
    self.selectedLineup = self.__classid

   Pathfinder.moveToNode(self.node, {
       task = string.format("Throw %s [%i]", self.name:lower(), self.node.id),
       onReachedGoal = function()
           self.isAtDestination = true
           self.startThrowTimer:start()
       end,
       goalReachedRadius = 5,
       isCounterStrafingOnGoal = true,
       isPathfindingToNearestNodeIfNoConnections = false,
       isPathfindingToNearestNodeOnFailure = false,
   })
end

--- @return void
function AiStateGrenadeBase:reset()
    self.isInThrow = false
    self.node = nil
    self.isAtDestination = false
    self.isThrown = false
    self.selectedLineup = nil

    self.startThrowTimer:stop()
    self.throwHoldTimer:stop()
    self.inBehaviorTimer:stop()
end

--- @return void
function AiStateGrenadeBase:deactivate()
    self:reset()
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateGrenadeBase:think(cmd)
    -- Don't know why we are running with a nil node.
    if not self.node then
        self:deactivate()

        return
    end

    -- Force AI to abort if majorly threatened, even when about to throw.
    if AiUtility.isClientThreatenedMajor then
        self:reset()

        return
    end

    if self.throwHoldTimer:isNotElapsedThenStop(0.4) then
        if self.node.isRun then
            Pathfinder.moveAtAngle(self.node.direction)
        end
    end

    local clientOrigin = LocalPlayer:getOrigin()
    local distance = clientOrigin:getDistance(self.node.origin)
    local distance2 = clientOrigin:getDistance2(self.node.origin)

    if distance2 < 60 then
        if not self:isAllowedToThrow() then
            AiStateGrenadeBase.usedNodes[self.node.id]:restart()

            return
        end

        self.inBehaviorTimer:ifPausedThenStart()
    end

    -- We haven't thrown the grenade within this time.
    -- We're probably stuck. Abort the throw.
    if self.inBehaviorTimer:isElapsedThenStop(5) then
        self.cooldownTimer:start()

        self:deactivate()

        return
    end

    self.activity = string.format("Going to throw %s", self.name)
    self.isInThrow = false

    self.ai.states.evade:block()

    VirtualMouse.blockBuildup()

    if distance < 150 then
        VirtualMouse.lookAlongAngle(self.node.direction, 15, VirtualMouse.noise.none, "Grenade look at line-up")
    end

    if distance < 250 then
        self.activity = string.format("About to throw %s", self.name)

        self.ai.routines.manageGear:block()
        self.ai.routines.lookAwayFromFlashbangs:block()

        -- Try not to break obstacles with our HE grenade or molotov.
        if Pathfinder.isObstructedByObstacle then
            LocalPlayer.equipAvailableWeapon()
        else
            self.equipFunction()
        end
    end

    if distance < 200 then
        VirtualMouse.isCrosshairUsingVelocity = false
        VirtualMouse.isCrosshairSmoothed = true

        Pathfinder.blockTeammateAvoidance()
        Pathfinder.counterStrafe()

        local delta = self.node.direction:getMaxDiff(LocalPlayer.getCameraAngles())

        if delta < 15 then
            self.isInThrow = true
        end

        if delta < 1.5
            and self.startThrowTimer:isElapsed(self.throwTime)
            and LocalPlayer:isHoldingWeapons(self.weapons)
            and LocalPlayer:isAbleToAttack()
            and ((not self.startThrowTimer:isStarted() and distance2 < 5) or self.startThrowTimer:isStarted())
        then
            self.activity = string.format("Throwing %s", self.name)

            local isThrowable = true
            local isOnGround = LocalPlayer:getFlag(Player.flags.FL_ONGROUND)
            local velocity = LocalPlayer:m_vecVelocity()
            local speed = velocity:getMagnitude()

            if self.node.isRun then
                if speed < 160 then
                    isThrowable = false
                end

                Pathfinder.moveAtAngle(self.node.direction)
            end

            if self.node.isJump then
                if isOnGround then
                    isThrowable = false
                end

                if self.node.isRun then
                    if speed > 180 then
                        cmd.in_jump = true
                    end
                else
                    cmd.in_jump = true
                end
            end

            if isThrowable and not self.isThrown then
                self.throwHoldTimer:ifPausedThenStart()

                cmd.in_attack = true
                self.isThrown = true
            end
        end
    end
end

function AiStateGrenadeBase:isAllowedToThrow()
    local predictor = GrenadePrediction.create()

    predictor:setupArbitrary(
        LocalPlayer.eid,
        self.weapons[1], -- this will assume an incendiary is a molotov as per the implementation for molotovs.
        self.node.origin:clone():offset(0, 0, 64),
        self.node.direction
    )

    local prediction = predictor:predict()

    if prediction then
        local predictionEndPosition = Vector3:new(prediction.end_pos.x, prediction.end_pos.y, prediction.end_pos.z)

        if self.isDamaging then
            -- We're most likely going to annoy our teammates if we throw this lineup right now.
            -- See: https://en.wikipedia.org/wiki/Griefer
            for _, teammate in pairs(AiUtility.teammates) do
                local teammatePredictedOrigin = teammate:getOrigin() + teammate:m_vecVelocity() * 0.4

                if teammatePredictedOrigin:getDistance(predictionEndPosition) < 300 then
                    self.usedNodes[self.node.id]:restart()

                    return false
                end
            end
        end

        -- Do not throw molotovs onto smokes, or resmoke a smoked spot.
        if self.isInferno or self.isSmoke then
            for _, smoke in Entity.find("CSmokeGrenadeProjectile") do
                if predictionEndPosition:getDistance(smoke:m_vecOrigin()) < 350 then
                    self.usedNodes[self.node.id]:restart()

                    return false
                end
            end
        end
    end

    return true
end

--- @return NodeTypeGrenade[]
function AiStateGrenadeBase:getNodes()
    if AiUtility.mapInfo.gamemode == AiUtility.gamemodes.HOSTAGE then
        if LocalPlayer:isCounterTerrorist() then
            return Nodegraph.get(self.nodeRetakeCt)
        elseif LocalPlayer:isTerrorist() then
            return Nodegraph.get(self.nodeDefendT)
        end
    end

    if LocalPlayer:isCounterTerrorist() then
        if AiUtility.plantedBomb then
            return Nodegraph.get(self.nodeRetakeCt)
        end

        return Nodegraph.get(self.nodeDefendCt)
    elseif LocalPlayer:isTerrorist() then
        local isSiteTaken = false

        if AiUtility.plantedBomb then
            isSiteTaken = true
        elseif AiUtility.bombCarrier then
            local bombCarrierOrigin = AiUtility.bombCarrier:m_vecOrigin()

            if bombCarrierOrigin then
                if bombCarrierOrigin:getDistance(Nodegraph.getBombsite("A").origin) < 750 then
                    isSiteTaken = true
                elseif bombCarrierOrigin:getDistance(Nodegraph.getBombsite("B").origin) < 750 then
                    isSiteTaken = true
                end
            end
        end

        return isSiteTaken and Nodegraph.get(self.nodeDefendT) or Nodegraph.get(self.nodeExecuteT)
    end
end

return Nyx.class("AiStateGrenadeBase", AiStateGrenadeBase, AiStateBase)
--}}}
