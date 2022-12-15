--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local DrawDebug = require "gamesense/Nyx/v1/Api/DrawDebug"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local ColorList = require "gamesense/Nyx/v1/Dominion/Utility/ColorList"
local Debug = require "gamesense/Nyx/v1/Dominion/Utility/Debug"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local PlanarTestList = require "gamesense/Nyx/v1/Dominion/Traversal/PlanarTestList"
--}}}

--{{{ Definitions
--- @class NodeTypeBaseConnectionOptions
--- @field isCollisionInfoSaved boolean
--- @field isInversingConnections boolean
--- @field isRestrictingConnections boolean
--- @field isTestingForGaps boolean
--- @field isUsingHumanCollisionTest boolean
--- @field isUsingLineCollisionTest boolean
--- @field maxConnections number

--- @class NodeTypeBaseConnectionCollision
--- @field origin Vector3
--- @field bounds Vector3[]
--- @field isClose boolean
--- @field isIntersectingGeometry boolean
--- @field isOutOfReach boolean

--- @class NodeTypeBaseGapCollision
--- @field origin Vector3
--- @field bounds Vector3[]
--- @field isIntersectingGeometry boolean
--}}}

--{{{ NodeTypeBase
--- @class NodeTypeBase : Class
--- @field bombsite string
--- @field collisionHullGap Vector3[]
--- @field collisionHullHumanDucking Vector3[]
--- @field collisionHullHumanStanding Vector3[]
--- @field collisionHullNode Vector3[]
--- @field collisionHullNodeSpawn Vector3[]
--- @field collisionHullNodeSmall Vector3[]
--- @field colorPrimary Color
--- @field colorSecondary Color
--- @field connectionCollisions NodeTypeBaseConnectionCollision[]
--- @field connections NodeTypeBase[]
--- @field customizerItems MenuItem[]
--- @field customizers string[]
--- @field description string[]
--- @field direction Angle
--- @field drawDistance number
--- @field gapCollisions NodeTypeBaseGapCollision[]
--- @field id number
--- @field iRenderBottomLines number
--- @field iRenderTopLines number
--- @field isActive boolean
--- @field isCollisionTestWeak boolean
--- @field isConnectable boolean
--- @field isDirectional boolean
--- @field isDragMovable boolean
--- @field isDuck boolean
--- @field isGoal boolean
--- @field isHiddenFromEditor boolean
--- @field isJump boolean
--- @field isLinkedToBombsite boolean
--- @field isNameHidden boolean
--- @field isOccludedByInferno boolean
--- @field isOccludedBySmoke boolean
--- @field isPathable boolean
--- @field isPlanar boolean
--- @field isRecorder boolean
--- @field isTransient boolean
--- @field isTraversal boolean
--- @field lookAtOrigin Vector3
--- @field lookDistanceThreshold number
--- @field lookFromOrigin Vector3
--- @field lookZOffset number
--- @field name string
--- @field origin Vector3
--- @field pathOffset number
--- @field pathOrigin Vector3
--- @field renderAlpha number
--- @field renderAlphaFov number
--- @field renderColorFovPrimary Color
--- @field renderColorFovPrimaryMuted Color
--- @field renderColorFovSecondary Color
--- @field renderColorPrimary Color
--- @field renderColorSecondary Color
--- @field traversalCost number
--- @field type string
--- @field userdata table<string, any>
--- @field zDeltaGoalThreshold number
--- @field zDeltaThreshold number
local NodeTypeBase = {
    name = "Unnamed Node Type",
    description = {"No description given."},
    customizerItems = {},
    drawDistance = 1024,
    isActive = true,
    isConnectable = false,
    isDirectional = false,
    isDragMovable = true,
    isLinkedToBombsite = false,
    lookDistanceThreshold = 200,
    lookZOffset = 46,
    traversalCost = 0,
    zDeltaGoalThreshold = 64,
    zDeltaThreshold = 64,
}

--- @param fields NodeTypeBase
--- @return NodeTypeBase
function NodeTypeBase:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function NodeTypeBase:__setup()
    if self.colorPrimary and not self.colorSecondary then
        self.colorSecondary = self.colorPrimary:clone()
    end

    NodeTypeBase.collisionHullHumanStanding = Vector3:newBounds(Vector3.align.UP, 15, 15, 32)
    NodeTypeBase.collisionHullHumanDucking = Vector3:newBounds(Vector3.align.UP, 15, 15, 23)
    NodeTypeBase.collisionHullNode = Vector3:newBounds(Vector3.align.CENTER, 15, 15, 6)
    NodeTypeBase.collisionHullNodeSmall = Vector3:newBounds(Vector3.align.CENTER, 6)
    NodeTypeBase.collisionHullNodeSpawn = Vector3:newBounds(Vector3.align.CENTER, 15, 15, 18)
    NodeTypeBase.collisionHullGap = Vector3:newBounds(Vector3.align.BOTTOM, 15, 15, 32)
end

--- @return void
function NodeTypeBase:__init()
    self.connections = {}
    self.connectionCollisions = {}
    self.gapCollisions = {}
    self.pathOrigin = self.origin
    self.iRenderTopLines = 0
    self.iRenderBottomLines = 0
    self.pathOffset = 0
end

--- @param node NodeTypeBase
function NodeTypeBase:is(node)
    return Nyx.isInstanceOf(self, node)
end

--- @param nodes NodeTypeBase[]
--- @return boolean
function NodeTypeBase:isAny(nodes)
    for _, node in pairs(nodes) do
        if Nyx.isInstanceOf(self, node) then
            return true
        end
    end

    return false
end

--- @param node NodeTypeBase
--- @return boolean
function NodeTypeBase:isOf(node)
    return self.type == node.type
end

--- @return void
function NodeTypeBase:serialize() end

--- @param nodegraph Nodegraph
--- @param userdata NodeTypeBase
--- @return void
function NodeTypeBase:deserialize(nodegraph, userdata) end

--- Renders the node.
---
--- @param nodegraph Nodegraph
--- @param isRenderingMetaData boolean
--- @return void
function NodeTypeBase:render(nodegraph, isRenderingMetaData)
    local cameraOrigin = LocalPlayer.getCameraOrigin()
    local origin = LocalPlayer:getOrigin()
    local cameraAngles = LocalPlayer.getCameraAngles()
    local alphaModDistance = Math.getClamped(Math.getInversedFloat(origin:getDistance(self.origin), Math.getClamped(NodeTypeBase.drawDistance / 2, 0, 1000)), 0, 1) * 255
    local alphaModFoV = Math.getClamped(Math.getInversedFloat(cameraAngles:getFov(cameraOrigin, self.origin), 30), 0.1, 1) * 255

    local err = self:getError(nodegraph)

    if err then
        self.renderAlpha = 255
    else
        self.renderAlpha = Math.getClamped(Math.getInversedFloat(origin:getDistance(self.origin), NodeTypeBase.drawDistance), 0, 1) * 255
    end

    self.renderAlphaFov = math.min(alphaModDistance, alphaModFoV)
    self.renderColorPrimary = self.colorPrimary:clone():setAlpha(self.renderAlpha)
    self.renderColorSecondary = self.colorSecondary:clone():setAlpha(self.renderAlpha)
    self.renderColorFovPrimary = self.renderColorPrimary:clone():setAlpha(self.renderAlphaFov)
    self.renderColorFovPrimaryMuted = self.renderColorPrimary:clone():setAlpha(self.renderAlphaFov * 0.4)
    self.renderColorFovSecondary = self.renderColorSecondary:clone():setAlpha(self.renderAlphaFov)

    self.iRenderTopLines = 0
    self.iRenderBottomLines = 0

    if not self:isRenderable() then
        return
    end

    local innerRadius = 25
    local outerRadius = 45
    local outerThickness = 10

    if not self.isActive then
        innerRadius = 0
        outerRadius = 25
        outerThickness = 10

        self.origin:drawScaledCircleOutline(75, 40, ColorList.ERROR:clone():setAlpha(100))
    elseif self.isOccludedByInferno then
        innerRadius = 0
        outerRadius = 25
        outerThickness = 10

        self.origin:drawScaledCircleOutline(75, 40, ColorList.WARNING:clone():setAlpha(100))
    elseif self.isOccludedBySmoke then
        innerRadius = 0
        outerRadius = 25
        outerThickness = 10

        self.origin:drawScaledCircleOutline(75, 40, ColorList.FONT_MUTED:clone():setAlpha(100))
    end

    self.origin:drawScaledCircle(innerRadius, self.renderColorPrimary)
    self.origin:drawScaledCircleOutline(outerRadius, outerThickness, self.renderColorSecondary)

    if not isRenderingMetaData then
        return
    end

    if err then
        local errColor = ColorList.WARNING:clone():setAlpha(self.renderColorPrimary.a)

        self:renderTopText(errColor, err)
    end

    if not Table.isEmpty(self.connections) and self.isTraversal then
        for _, connection in pairs(self.connections) do
            local color

            if connection.isPathable then
                color = Color:hsla(235, 0.16, 0.66, math.min(self.renderAlpha, 55))
            end

            self.origin:drawLine(connection.origin, color, 0.25)
        end
    end

    if self.isDirectional and self.direction then
        local forward = self.direction:getForward() * 10
        local offset = self.origin + forward

        self.origin:drawLine(offset, self.renderColorPrimary, 1)

        offset:drawScaledCircle(10, self.renderColorPrimary)
    end

    if self.id then
        local title

        if self.isNameHidden then
            title = self.id
        else
            title = string.format("%i %s", self.id, self.name)
        end

        self:renderTopText(self.renderColorFovPrimary, title)
    end

    if self.customizers then
        for _, field in pairs(self.customizers) do
            self:renderBottomText(self.renderColorFovPrimary, "%s %s", field, self[field])
        end
    end

    if Debug.isDisplayingNodeConnections then
        for _, node in pairs(self.connections) do
            self:renderTopText(self.renderColorFovPrimaryMuted, node.id)
        end
    end

    if Debug.isDisplayingNodeLookAngles and self.lookAtOrigin then
        local color
        local distance = self.lookFromOrigin:getDistance(self.lookAtOrigin)

        if distance < self.lookDistanceThreshold then
            color = ColorList.ERROR

            self.lookAtOrigin:drawScaledCircleOutline(50, 15, color)
        else
            color = self.renderColorSecondary

        end

        self.lookFromOrigin:drawScaledCircle(30, color)
        self.lookFromOrigin:drawLine(self.lookAtOrigin, color)
    end
end

--- Use this check to prevent rendering nodes when it is not needed. This will help with performance.
---
--- @return boolean
function NodeTypeBase:isRenderable()
    return self.renderAlpha >= 1
end

--- Render text above the node.
---
--- @param color Color
--- @vararg string
--- @return void
function NodeTypeBase:renderTopText(color, ...)
    local drawPos = self.origin:clone():offset(0, 0, 16):getVector2()

    if not drawPos then
        return
    end

    drawPos:offset(0, -(18 * self.iRenderTopLines))
    drawPos:drawSurfaceText(Font.SMALL, color, "c", string.format(...))

    self.iRenderTopLines = self.iRenderTopLines + 1
end

--- Render text below the node.
---
--- @param color Color
--- @vararg string
--- @return void
function NodeTypeBase:renderBottomText(color, ...)
    local drawPos = self.origin:clone():offset(0, 0, -10):getVector2()

    if not drawPos then
        return
    end

    drawPos:offset(0, (18 * self.iRenderBottomLines))
    drawPos:drawSurfaceText(Font.SMALL, color, "c", string.format(...))

    self.iRenderBottomLines = self.iRenderBottomLines + 1
end

--- @return Vector3
function NodeTypeBase:setLookAtOrigin()
    local lookFromOrigin = self.origin:clone():offset(0, 0, self.lookZOffset)
    local lookDirectionTrace = Trace.getLineAtAngle(lookFromOrigin, self.direction, AiUtility.traceOptionsAttacking, "NodeTypeBase.setLookAtOrigin<FindLookAngle>")

    self.lookAtOrigin = lookDirectionTrace.endPosition
    self.lookFromOrigin = lookFromOrigin
end

--- Returns a string describing a problem with the node that will inhibit the AI in gameplay.
---
--- The error described must be fixed by the graph creator.
---
--- @param nodegraph Nodegraph
--- @return string|nil
function NodeTypeBase:getError(nodegraph)
    if not Table.isEmpty(nodegraph.nodes) and self.isConnectable and Table.isEmpty(self.connections) then
        return "No connections"
    end

    if Table.getCount(self.connections) > 16 then
        return "Too many connections"
    end

    return nil
end

--- Create custom menu items associated with setting this node up.
---
--- The items will be shown when this node type is selected.
---
--- @param menu MenuGroup
--- @return void
function NodeTypeBase:setupCustomizers(menu)
    self.customizers = {}

    if self.isLinkedToBombsite then
        self:addCustomizer("bombsite", function()
            return menu.group:addDropdown("    > Bombsite", {"A", "B"})
        end)
    end
end

--- @param field string
--- @param item fun(): MenuItem
--- @return void
function NodeTypeBase:addCustomizer(field, item)
    if not NodeTypeBase.customizerItems[field] then
        NodeTypeBase.customizerItems[field] = item
    end

    table.insert(self.customizers, field)
end

--- Sets visibility on menu items.
---
--- @param bool boolean
--- @return void
function NodeTypeBase:setCustomizersVisibility(bool)
    if Table.isEmpty(self.customizers) then
        return
    end

    for _, customizer in pairs(self.customizers) do
        NodeTypeBase.customizerItems[customizer]:setVisibility(bool)
    end
end

--- Executed to set custom fields on this node.
---
--- @return void
function NodeTypeBase:executeCustomizers()
    if Table.isEmpty(self.customizers) then
        return
    end

    for _, customizer in pairs(self.customizers) do
        self[customizer] = NodeTypeBase.customizerItems[customizer]:get()
    end
end

--- @param node NodeTypeBase
--- @return void
function NodeTypeBase:setConnection(node)
    self.connections[node.id] = node
    node.connections[self.id] = self
end

--- Set up all connections for the node.
---
--- @param nodegraph Nodegraph
--- @param options NodeTypeBaseConnectionOptions
--- @return void
function NodeTypeBase:setConnections(nodegraph, options)
    if not self.isConnectable then
        return
    end

    options = options or {}

    Table.setMissing(options, {
        maxConnections = 3,
        isInversingConnections = true
    })

    local iConnections = 0

    self.connections = {}

    --- @type Vector3[]
    local hullBounds
    local hullOffset = 0

    if options.isUsingHumanCollisionTest then
        if LocalPlayer:getFlag(LocalPlayer.flags.FL_DUCKING) then
            hullBounds = NodeTypeBase.collisionHullHumanDucking
        else
            hullBounds = NodeTypeBase.collisionHullHumanStanding
        end

        hullOffset = -10
    else
        hullBounds = NodeTypeBase.collisionHullNode
    end

    local fallBounds = NodeTypeBase.collisionHullGap
    local selfCollisionOrigin = self.origin:clone():offset(0, 0, hullOffset)

    for _, node in Table.sortedPairs(nodegraph.pathableNodes, function(a, b)
        return self.origin:getDistance(a.origin) < self.origin:getDistance(b.origin)
    end) do repeat
        if iConnections == options.maxConnections then
            return
        end

        if node.id == self.id then
            break
        end

        if not node.isConnectable then
            break
        end

        local distance = self.origin:getDistance(node.origin)

        if distance > 250 then
            break
        end

        local zDelta = node.origin.z - self.origin.z

        if node.isJump and zDelta > node.zDeltaThreshold then
            break
        end

        if options.isRestrictingConnections then
            local height = math.abs(zDelta)

            if height > 100 then
                if options.isCollisionInfoSaved then
                    self.connectionCollisions[node.id] = {
                        origin = node.origin,
                        bounds = self.collisionHullHumanStanding,
                        isOutOfReach = true
                    }
                end

                break
            end
        end

        local isCollisionOk = true

        if options.isUsingLineCollisionTest then
            local trace = Trace.getLineToPosition(self.origin, node.origin, AiUtility.traceOptionsPathfinding, "NodeTypeBase.setConnections<FindConnections>")

            isCollisionOk = not trace.isIntersectingGeometry
        elseif node.isCollisionTestWeak and options.isUsingHumanCollisionTest then
            local distance2 = self.origin:getDistance2(node.origin)

            if distance < 150 and distance2 > 50 then
                local collisionTrace = Trace.getHullToPosition(self.origin, node.origin, self.collisionHullNodeSmall, AiUtility.traceOptionsPathfinding, "NodeTypeBase.setConnections<FindConnections>")

                if options.isCollisionInfoSaved then
                    self.connectionCollisions[node.id] = {
                        origin = node.origin,
                        bounds = self.collisionHullHumanStanding,
                        isIntersectingGeometry = collisionTrace.isIntersectingGeometry
                    }
                end

                isCollisionOk = not collisionTrace.isIntersectingGeometry
            else
                if distance > 35 then
                    isCollisionOk = false
                else
                    if options.isCollisionInfoSaved then
                        self.connectionCollisions[node.id] = {
                            origin = node.origin,
                            bounds = hullBounds,
                            isClose = true
                        }
                    end
                end
            end
        else
            if distance > 35 then
                local targetCollisionOrigin = node.origin:clone():offset(0, 0, hullOffset)
                local collisionTrace = Trace.getHullToPosition(selfCollisionOrigin, targetCollisionOrigin, hullBounds, AiUtility.traceOptionsPathfinding, "NodeTypeBase.setConnections<FindConnections>")

                if options.isCollisionInfoSaved then
                    self.connectionCollisions[node.id] = {
                        origin = node.origin,
                        bounds = hullBounds,
                        isIntersectingGeometry = collisionTrace.isIntersectingGeometry
                    }
                end

                isCollisionOk = not collisionTrace.isIntersectingGeometry
            else
                if options.isCollisionInfoSaved then
                    self.connectionCollisions[node.id] = {
                        origin = node.origin,
                        bounds = hullBounds,
                        isClose = true
                    }
                end
            end
        end

        if not isCollisionOk then
            break
        end

        if options.isTestingForGaps then
            local isGap = false
            local steps = 1

            if distance > 300 then
                steps = 3
            elseif distance > 150 then
                steps = 2
            elseif distance < 50 then
                steps = 0
            end

            local maxSteps = steps + 1

            for i = 1, steps do
                local fraction = i / maxSteps
                local testOrigin = self.origin:getLerp(node.origin, fraction):offset(0, 0, 0)
                local fallTrace = Trace.getHullToPosition(testOrigin, testOrigin:clone():offset(0, 0, -48), fallBounds, AiUtility.traceOptionsPathfinding, "NodeTypeBase.setConnections<FindConnections>")

                if options.isCollisionInfoSaved then
                    self.gapCollisions[node.id] = {
                        origin = node.origin,
                        bounds = fallBounds,
                        isIntersectingGeometry = fallTrace.isIntersectingGeometry
                    }
                end

                if not fallTrace.isIntersectingGeometry then
                    isGap = true

                    break
                end
            end

            if isGap then
                break
            end
        end

        if node.isTraversal then
            iConnections = iConnections + 1
        end

        self.connections[node.id] = node

        if options.isInversingConnections then
            node.connections[self.id] = self
        end
    until true end
end

--- Unset all connections for the node.
---
--- @return void
function NodeTypeBase:unsetConnections()
    for _, connection in pairs(self.connections) do
        connection.connections[self.id] = nil
    end

    self.connections = {}
end

--- @return boolean
function NodeTypeBase:isConnectionless()
    return next(self.connections) == nil
end

--- @return void
function NodeTypeBase:activate()
    self.isActive = true
end

--- @return void
function NodeTypeBase:deactivate()
    self.isActive = false
end

--- Executed immediately before adding the node to the graph.
---
--- @param nodegraph Nodegraph
--- @return void
function NodeTypeBase:onCreatePre(nodegraph)
    if self.isDirectional then
        self.direction = LocalPlayer.getCameraAngles()
    end
end

--- Executed immediately before after adding the node to the graph.
---
--- @param nodegraph Nodegraph
--- @return void
function NodeTypeBase:onCreatePost(nodegraph)
    for _, connection in pairs(self.connections) do
        connection.connections[self.id] = self
    end
end

--- Executed on all nodes in sequence when the graph is loaded or modified.
---
--- If you have bugs relating to associations with other nodes, try using this method instead of onCreate.
---
--- @param nodegraph Nodegraph
--- @return void
function NodeTypeBase:onSetup(nodegraph)
    if self.isPlanar then
        -- We need to test from a higher position, to account for stairs or short ledges.
        local origin = self.origin:clone():offset(0, 0, 18)
        -- Default planar test offset.
        local offset = 5

        -- Determine the maximum offset we can use for planar nodes' path offsets.
        -- This will make planar offsets become small in tight spaces, and larger in open areas.
        -- The intent is for the AI to take randomised paths. These validation functions
        -- give us the maximum possible offset the AI could perform.
        for _, item in pairs(PlanarTestList) do
            if not item.validation(origin) then
                break
            end

            offset = item.offset
        end

        self.pathOffset = offset
    end

    -- Set look-at data for directional nodes. Hints the AI with crosshair placement information.
    if self.isDirectional then
        self:setLookAtOrigin()
    end
end

--- Executed when the node is removed from the graph.
---
--- @param nodegraph Nodegraph
--- @return void
function NodeTypeBase:onRemove(nodegraph)
    for _, connection in pairs(self.connections) do
        connection.connections[self.id] = nil
    end
end

--- Executed once per tick and allows the node to perform its own gameplay logic.
---
--- @param nodegraph Nodegraph
--- @return void
function NodeTypeBase:onThink(nodegraph) end

--- Executed when pathfinding selects this node.
---
--- @param nodegraph Nodegraph
--- @return void
function NodeTypeBase:onIsInPath(nodegraph) end

--- Executed when this node is the current node in the AI's path.
---
--- @param nodegraph Nodegraph
--- @param path PathfinderPath
--- @return void
function NodeTypeBase:onIsNext(nodegraph, path)
    -- Don't make the first node in a path offset.
    -- Also don't make the last offset.
    -- If the AI keeps remaking the path, it's likely to zig-zag on the spot.
    if self.isPlanar and path.idx > 1 and path.idx ~= path.finalIdx then
        local nextNode = path.nodes[path.idx + 1]

        -- Never offset the path if the next node is a jump or duck,
        -- or the AI may not line them up properly.
        if nextNode and (nextNode.isJump or nextNode.isDuck) then
            return
        end

        -- Generate a realistic offset based on the distance.
        -- Close nodes in the path shouldn't want to make the AI strafe really hard.
        local distance = LocalPlayer:getOrigin():getDistance(self.origin)
        local pct = Math.getClampedFloat(distance, 150, 0, 150)
        local pathOffset = self.pathOffset * pct

        -- Generate the world position we would like the AI to walk to.
        local idealPathOrigin = self.origin + Vector3:new(
            Math.getRandomFloat(-pathOffset, pathOffset),
            Math.getRandomFloat(-pathOffset, pathOffset),
            0
        )

        -- Generate the world position that the AI can physically walk to.
        local trace = Trace.getHullToPosition(
            self.origin,
            idealPathOrigin,
            Vector3:newBounds(Vector3.align.UP, 32, 32, 16),
            AiUtility.traceOptionsPathfinding,
            "NodeTypeBase.onIsNext<FindPlanarOffset>"
        )

        -- Randomly offset the path origin so that the AI moves along a path in a slightly random fashion.
        self.pathOrigin = trace.endPosition
    else
        self.pathOrigin = self.origin
    end
end

--- Executed when this node is the passed during a path traversal.
--- @param nodegraph Nodegraph
--- @return void
function NodeTypeBase:onIsPassed(nodegraph) end

return Nyx.class("NodeTypeBase", NodeTypeBase)
--}}}
