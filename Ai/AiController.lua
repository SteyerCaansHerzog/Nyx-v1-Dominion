--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Color = require "gamesense/Nyx/v1/Api/Color"
local CsgoWeapons = require "gamesense/csgo_weapons"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local ISurface = require "gamesense/Nyx/v1/Api/ISurface"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"
local Weapons = require "gamesense/Nyx/v1/Api/Weapons"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiChat = require "gamesense/Nyx/v1/Dominion/Ai/AiChat"
local AiRadio = require "gamesense/Nyx/v1/Dominion/Ai/AiRadio"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
local AiStateEngage = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEngage"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiView = require "gamesense/Nyx/v1/Dominion/Ai/AiView"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local AiVoice = require "gamesense/Nyx/v1/Dominion/Ai/AiVoice"
local Font = require "gamesense/Nyx/v1/Dominion/Utility/Font"
local Menu = require "gamesense/Nyx/v1/Dominion/Utility/Menu"
local Node = require "gamesense/Nyx/v1/Dominion/Pathfinding/Node"
--}}}

--{{{ AiController
--- @class AiController : Class
--- @field activeFlashbang Entity
--- @field antiBlockLookAngles Vector3
--- @field antiAfkEnabled boolean
--- @field antiAfkLookAngles Angle
--- @field antiAfkMoveYaw number
--- @field antiAfkTimer Timer
--- @field antiBlockDuration number
--- @field antiFlyTimer Timer
--- @field antiFlyValues number
--- @field autoClosePopupsTimer Timer
--- @field canAntiBlock boolean
--- @field canBuyThisRound boolean
--- @field canInspectWeapon boolean
--- @field canInspectWeaponTime number
--- @field canInspectWeaponTimer Timer
--- @field canLookAround boolean
--- @field canLookAwayFromFlash boolean
--- @field canUnscope boolean
--- @field canUseKnife boolean
--- @field chat AiChat
--- @field commands AiChatCommand[]
--- @field config Config
--- @field currentState AiState
--- @field deactivatedNodes table<number, Node[]>
--- @field deactivatedNodesByBlock table<number, Node[]>
--- @field flashbangVisibleTimer Timer
--- @field font number
--- @field freezetimeTimer Timer
--- @field isFreezetime boolean
--- @field isQuickStopping boolean
--- @field isWalking boolean
--- @field lastPriority number
--- @field lookAroundAngles Angle
--- @field lookAroundTimer Timer
--- @field nodegraph Nodegraph
--- @field radio AiRadio
--- @field reloadDelay number
--- @field sentences AiSentence[]
--- @field states AiState[]
--- @field unblockDirection string
--- @field unblockNodesTimer Timer
--- @field unblockTimer Timer
--- @field unscopeTime number
--- @field unscopeTimer Timer
--- @field view AiView
--- @field voice AiVoice
local AiController = {
    ADMINS = {
        [1142718934] = true
    }
}

--- @param fields AiController
--- @return AiController
function AiController:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiController:__init()
    self:initFields()
    self:initEvents()
end

--- @return void
function AiController:initFields()
    self.view = AiView:new({
        nodegraph = self.nodegraph
    })

    self.antiAfkEnabled = false
    self.antiAfkLookAngles = Angle:new()
    self.antiAfkMoveYaw = 0
    self.antiAfkTimer = Timer:new():start()
    self.antiBlockDuration = Client.getRandomFloat(1, 2)
    self.antiFlyTimer = Timer:new():start()
    self.antiFlyValues = {}
    self.autoClosePopupsTimer = Timer:new():startThenElapse()
    self.canBuyThisRound = true
    self.canInspectWeapon = true
    self.canInspectWeaponTime = Client.getRandomFloat(50, 90)
    self.canInspectWeaponTimer = Timer:new():start()
    self.config = Config
    self.deactivatedNodes = {}
    self.deactivatedNodesByBlock = {}
    self.flashbangVisibleTimer = Timer:new()
    self.freezetimeTimer = Timer:new()
    self.isFreezetime = true
    self.lookAroundTimer = Timer:new():start()
    self.reloadDelay = Client.getRandomFloat(2, 2.9)
    self.unblockDirection = "Left"
    self.unblockNodesTimer = Timer:new()
    self.unblockTimer = Timer:new():elapse()
    self.unscopeTime = 2
    self.unscopeTimer = Timer:new()

    Menu.enableAi = Menu.group:checkbox("> Dominion Artifical Intelligence"):setParent(Menu.master):addCallback(function(item)
        local value = item:get()

        if not value then
            self.nodegraph:clearPath("AI disabled")
        end

        self.view.enabled = value
        self.lastPriority = nil
        self.currentState = nil
    end)

    Menu.visualisePathfinding = Menu.group:checkbox("    > Visualise Pathfinding"):setParent(Menu.enableAi)
    Menu.enableView = Menu.group:checkbox("    > Enable View"):setParent(Menu.enableAi)
    Menu.enableAutoBuy = Menu.group:checkbox("    > Enable Auto-Buy"):setParent(Menu.enableAi)

    self.radio = AiRadio:new()
    self.voice = AiVoice:new()

    local states = {}

    for _, state in pairs(self.states) do
        local initialisedState = state:new()

        initialisedState.nodegraph = self.nodegraph

        states[state.name] = initialisedState
    end

    self.states = states

    local commands = {}

    for _, command in pairs(self.commands) do
        commands[command.cmd] = command
    end

    self.commands = commands

    AiChat:new({
        sentences = self.sentences
    })

    self:setClientLoaderLock()
    self:openAndEquipGraffitis()
end

--- @return void
function AiController:initEvents()
    cvar.engine_no_focus_sleep:set_int(0)

    Callbacks.playerConnectFull(function(e)
    	Client.fireAfter(10, function()
            local steamid64 = e.player:getSteam64()

            if Panorama.GameStateAPI.IsSelectedPlayerMuted(steamid64) then
                Panorama.GameStateAPI.ToggleMute(steamid64)
            end
    	end)
    end)

    Callbacks.init(function()
        Client.fireAfter(10, function()
            for _, player in Player.findAll(function()
                return true
            end) do
                local steamid64 = player:getSteam64()

                if Panorama.GameStateAPI.IsSelectedPlayerMuted(steamid64) then
                    Panorama.GameStateAPI.ToggleMute(steamid64)
                end
            end
        end)
    end)

    Callbacks.frameGlobal(function()
        for i = 1, Panorama.PartyBrowserAPI.GetInvitesCount() do
            local lobbyId = Panorama.PartyBrowserAPI.GetInviteXuidByIndex(i - 1)

            local found = false

            for i = 0, 5 do
                local xuid = Panorama.PartyBrowserAPI.GetPartyMemberXuid(lobbyId, i)

                if Table.contains(Config.administrators, xuid) then
                    Panorama.PartyBrowserAPI.ActionJoinParty(lobbyId)

                    found = true

                    break
                end
            end

            if found then
                break
            end
        end

        if Menu.autoClosePopups:get() and self.autoClosePopupsTimer:isElapsedThenRestart(2) then
            panorama.loadstring('UiToolkitAPI.CloseAllVisiblePopups()', 'CSGOMainMenu')()
            Panorama.InventoryAPI.AcknowledgeNewItems()
        end
    end)

    Callbacks.frame(function()
        if not Menu.master:get() then
            return
        end

        self:renderUi()
    end)

    Callbacks.setupCommand(function(cmd)
        self:think(cmd)
    end)

    Callbacks.roundStart(function()
        self.nodegraph:reactivateAllNodes()

        if not Menu.master:get() or not Menu.enableAi:get() then
            return
        end

        Client.cmd("showconsole")

        self.isFreezetime = true
        self.lastPriority = nil
        self.currentState = nil

        self.nodegraph:clearPath("Round restart")

        self.freezetimeTimer:start()
        self:autoBuy()

        for _, block in pairs(self.nodegraph.objectiveBlock) do
            self.deactivatedNodesByBlock[block.id] = {}

            for _, node in pairs(self.nodegraph.nodes) do
                if node.id ~= block.id and block.origin:getDistance(node.origin) < 256 then
                    node.active = false

                    table.insert(self.deactivatedNodesByBlock[block.id], node)
                end
            end
        end

        self.nodegraph:rePathfind()
    end)

    Callbacks.roundFreezeEnd(function()
        self.isFreezetime = false
        self.canBuyThisRound = true

        self.unblockNodesTimer:start()
    end)

    Callbacks.itemEquip(function(e)
        if not Menu.master:get() or not Menu.enableAi:get() or not Menu.enableAutoBuy:get() then
            return
        end

        if not e.player:isClient() then
            return
        end

        Client.fireAfter(0.1, function()
            if not self.freezetimeTimer:isElapsed(1) then
                return
            end

            Client.cmd("buy vest; buy vesthelm")
        end)
    end)

    Callbacks.bombPlanted(function()
        self.nodegraph:reactivateAllNodes()
    end)

    Callbacks.smokeGrenadeDetonate(function(e)
        if AiUtility.isBombPlanted() then
            return
        end

        self:deactivateNodes(e.entityid, e.origin, 144, true)
    end)

    Callbacks.smokeGrenadeExpired(function(e)
        self:reactivateNodes(e.entityid)
    end)

    Callbacks.infernoStartBurn(function(e)
        if AiUtility.isBombPlanted() then
            return
        end

        self:deactivateNodes(e.entityid, e.origin, 200)
    end)

    Callbacks.infernoExpire(function(e)
        self:reactivateNodes(e.entityid)
    end)

    Callbacks.flashbangDetonate(function(e)
        if self.activeFlashbang and self.activeFlashbang.eid == e.entityid then
            self.activeFlashbang = nil
        end
    end)

    Callbacks.playerChat(function(e)
        if not Menu.master:get() then
            return
        end

        self:chatCommands(e)
    end)
end

--- @return void
function AiController:openAndEquipGraffitis()
    Panorama.InventoryAPI.SetInventorySortAndFilters("inv_sort_age", false, "", "", "")

    local totalItems = Panorama.InventoryAPI.GetInventoryCount() - 1
    local openedGraffiti = {}
    local unopenedGraffiti = {}

    for i = 0, totalItems do
        local idx = Panorama.InventoryAPI.GetInventoryItemIDByIndex(i)
        local set = Panorama.InventoryAPI.GetItemDefinitionName(idx)

        if set == "spray" then
            table.insert(unopenedGraffiti, idx)
        elseif set == "spraypaint" then
            table.insert(openedGraffiti, idx)
        end
    end

    Panorama.LoadoutAPI.EquipItemInSlot("noteam", Table.getRandom(openedGraffiti), "spray0")

    for id, spray in pairs(unopenedGraffiti) do
        Client.fireAfter(id, function()
            Panorama.InventoryAPI.UseTool(spray, spray)
        end)
    end
end

--- @param limit number
--- @return void
function AiController:buyGrenades(limit)
    local nades = Table.getShuffled({
        "buy smokegrenade",
        "buy flashbang",
        "buy hegrenade",
        "buy molotov; buy incgrenade"
    })

    limit = limit or 4

    local i = 0

    for _, nade in pairs(nades) do
        if i <= limit then
            Client.fireAfter(Client.getRandomFloat(0.25, 1), function()
                Client.cmd(nade)
            end)

            i = i + 1
        end
    end
end

--- @return void
function AiController:autoBuy()
    if not Menu.enableAutoBuy:get() or not self.canBuyThisRound then
        return
    end

    local freezeTime = cvar.mp_freezetime:get_int()
    local minDelay = freezeTime * 0.5
    local maxDelay = freezeTime * 0.9

    local buyAfter = Client.getRandomFloat(minDelay, maxDelay)

    Client.fireAfter(buyAfter, function()
        if not Server.isConnected() then
            return
        end

        if not self.canBuyThisRound then
            return
        end

        local player = AiUtility.client
        local grenadeLimit = Client.getRandomInt(1, player:isCounterTerrorist() and 2 or 3)

        for _, weapon in pairs(AiUtility.mainWeapons) do
            if player:hasWeapon(weapon) then
                if player:m_iArmor() < 33 then
                    Client.cmd("buy vest; buy vesthelm")
                end

                self:buyGrenades(grenadeLimit)

                return
            end
        end

        local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
        local halftimeRounds = math.floor(cvar.mp_maxrounds:get_int() / 2)

        if roundsPlayed == 0 or roundsPlayed == halftimeRounds then
            Client.cmd("buy p250")

            if player:isCounterTerrorist() then
                if Client.getChance(3) then
                    Client.cmd("buy defuser")
                else
                    self:buyGrenades(2)
                end
            else
                self:buyGrenades(2)
            end

            return
        end

        local balance = player:m_iAccount()

        if not balance then
            return
        end

        local team = player:m_iTeamNum()
        local canBuyRifle = balance - (team == 2 and 3000 or 3050) >= 0
        local canBuyAwp = (balance - 5750 >= 0) and Client.getChance(6)
        local canBuyUtility = false

        if (roundsPlayed == 1 or roundsPlayed == halftimeRounds + 1) and not canBuyRifle then
            self:forceBuy()

            return
        end

        if Client.getChance(15) and balance > 2000 and balance < 3500 then
            Client.cmd("buy vest; buy ssg08;")

            self:buyGrenades(1)
        end

        if canBuyAwp then
            Client.cmd("buy awp")

            canBuyUtility = true
        elseif canBuyRifle then
            local isBuyingCheapRifle = balance - (team == 2 and 3700 or 4200) < 0
            local isBuyingScopedRifle = balance > 4500 and Client.getChance(3)

            if isBuyingCheapRifle then
                Client.cmd("buy famas; buy galilar")

                grenadeLimit = 2
            elseif isBuyingScopedRifle then
                Client.cmd("buy aug; buy sg556")
            else
                Client.cmd("buy m4a4; buy ak47; buy m4a1_silencer")
            end

            canBuyUtility = true
        end

        if canBuyUtility then
            if player:m_iArmor() < 33 then
                Client.cmd("buy vest; buy vesthelm")
            end

            if player:isCounterTerrorist() then
                Client.cmd("buy defuser")
            end

            self:buyGrenades(grenadeLimit)
        end
    end)
end

--- @return void
function AiController:forceBuy()
    local player = AiUtility.client

    for _, weapon in pairs(AiUtility.mainWeapons) do
        if player:hasWeapon(weapon) then
            if player:m_iArmor() < 33 then
                Client.cmd("buy vest; buy vesthelm")
            end

            return
        end
    end

    local balance = player:m_iAccount()

    if not balance then
        return
    end

    local team = player:m_iTeamNum()
    local canBuyRifle = balance - (team == 2 and 3000 or 3050) > 0

    if canBuyRifle then
        return
    end

    local pistols = {
        "tec9; fn57"
    }

    local smgs = {
        "deagle",
        "mac10; mp9",
        "mp7",
        "ump45"
    }

    Client.fireAfter(Client.getRandomFloat(1, 2), function()
        local balance = player:m_iAccount()
        local isBuyingSmg = (balance - 1500) >= 0
        local isBuyingNegev = (balance - 2500 >= 0) and Client.getChance(5)

        if isBuyingNegev then
            Client.cmd("buy negev")
        elseif isBuyingSmg then
            Client.cmd("buy %s;", Table.getRandom(smgs))
        else
            Client.cmd("buy %s;", Table.getRandom(pistols))
        end

        if player:m_iArmor() < 33 then
            Client.cmd("buy vest; buy vesthelm")
        end

        self:buyGrenades(1)
    end)
end

--- @generic T
--- @param state T|AiState
--- @return T
function AiController:getState(state)
    return self.states[state.name]
end

--- @param e PlayerChatEvent
--- @return void
function AiController:chatCommands(e)
    if not e.text:sub(1, 1) == "/" then
        return
    end

    local input = Table.explode(e.text:sub(2), " ")
    local cmd = table.remove(input, 1)
    local command = self.commands[cmd]

    if not command then
        return
    end

    command:invoke(self, e.sender, input)
end

--- @param origin Vector3
--- @param radius number
--- @param checkForEnemies boolean
--- @return void
function AiController:deactivateNodes(eid, origin, radius, checkForEnemies)
    if checkForEnemies then
        local canContinue = false

        for _, enemy in pairs(AiUtility.enemies) do
            if origin:getDistance(enemy:getOrigin()) < 750 then
                canContinue = true

                break
            end
        end

        if not canContinue then
            return
        end
    end

    origin:offset(0, 0, 18)

    --- @type Node[]
    local deactivatedNodes = {}

    --- @type Node[]
    local plantNodes = Table.merge(self.nodegraph.objectiveAPlant, self.nodegraph.objectiveBPlant)

    for _, node in pairs(self.nodegraph.nodes) do repeat
        if node.active and node.origin:getDistance(origin) <= radius then
            for _, plant in pairs(plantNodes) do
                if node.origin:getDistance(plant.origin) <= radius then
                    break
                end
            end

            local _, fraction = node.origin:getTraceLine(origin)

            if fraction == 1 then
                table.insert(deactivatedNodes, node)

                node.active = false
            end
        end
    until true end

    self.deactivatedNodes[eid] = deactivatedNodes

    self.nodegraph:rePathfind()
end

--- @return void
function AiController:setClientLoaderLock()
    writefile("lua/gamesense/Nyx/v1/Dominion/Resource/Data/ClientLoaderLock", "1")
end

--- @param eid number
--- @return void
function AiController:reactivateNodes(eid)
    if not self.deactivatedNodes[eid] then
        return
    end

    for _, node in pairs(self.deactivatedNodes[eid]) do
        node.active = true
    end

    self.deactivatedNodes[eid] = nil
end

--- @return void
function AiController:renderUi()
    if not Menu.visualisePathfinding:get() then
        return
    end

    local player = AiUtility.client
    local uiPos = Vector2:new(20, 20)
    local fontColor = Color:hsla(0, 0, 0.95)
    local spacerColor = Color:hsla(0, 0, 0.66)
    local spacerDimensions = Vector2:new(200, 1)
    local offset = 25

    local teamColors = {
        [2] = Color:hsla(35, 0.8, 0.6),
        [3] = Color:hsla(200, 0.8, 0.6)
    }

    local nameBgColor = Color:rgba(0, 0, 0, 255)
    local teamNames = {
        [2] = "T",
        [3] = "CT"
    }
    local team = teamNames[player:m_iTeamNum()]
    local name = string.format("( %s ) %s", team, player:getName())

    if not team then
        return
    end

    local screenBgColor = Color:rgba(0, 0, 0, 255)

    if not player:isAlive() then
        name = name .. " (DEAD)"
        nameBgColor = Color:rgba(255, 50, 50, 255)
        screenBgColor = Color:rgba(200, 25, 25, 255)
    end

    local screenDimensions = Client.getScreenDimensions()

    Vector2:new():drawSurfaceRectangle(screenDimensions, screenBgColor)

    self:getState(AiStateEngage):render()

    local nameWidth = ISurface.getTextSize(Font.TITLE, name)

    uiPos:clone():offset(-5):drawSurfaceRectangle(Vector2:new(nameWidth + 10, 25), nameBgColor)
    uiPos:drawSurfaceText(Font.TITLE, teamColors[player:m_iTeamNum()], "l", name)
    uiPos:offset(0, offset)


    uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
    uiPos:offset(0, 10)

    local scoreData = Table.fromPanorama(Panorama.GameStateAPI.GetScoreDataJSO())
    local tWins = scoreData.teamdata.TERRORIST.score
    local ctWins = scoreData.teamdata.CT.score
    local maxRounds = cvar.mp_maxrounds:get_int()
    local roundType = "Custom"

    if maxRounds == 30 then
        roundType = "Long"
    elseif maxRounds == 16 then
        roundType = "Short"
    end

    if player:isTerrorist() then
        uiPos:drawSurfaceText(Font.MEDIUM, fontColor, "l", string.format(
            "%s Match: ( %i : %i )",
            roundType,
            tWins,
            ctWins
        ))
    else
        uiPos:drawSurfaceText(Font.MEDIUM, fontColor, "l", string.format(
            "%s Match: ( %i : %i )",
            roundType,
            ctWins,
            tWins
        ))
    end

    uiPos:offset(0, offset)

    local fps = Client.getFpsDelayed()
    local tickErrorPct = math.max(0, (1 - (fps / (1 / globals.tickinterval())))) * 100
    local hue = Math.pct(Math.clamp(fps, 0, 70), 70) * 120
    local fpsColor = Color:hsla(hue, 0.8, 0.6)

    uiPos:drawSurfaceText(Font.MEDIUM, fpsColor, "l", string.format(
        "FPS: %i",
        fps
    ))

    uiPos:offset(0, offset)

    if not Menu.enableAi:get() then
        uiPos:drawSurfaceText(Font.TITLE, Color:hsla(0, 0.8, 0.6, 255), "l", "AI DISABLED")

        uiPos:offset(0, offset)

        return
    end

    uiPos:drawSurfaceText(Font.MEDIUM, fpsColor, "l", string.format(
        "Tick Loss: %.1f%%",
        tickErrorPct
    ))

    uiPos:offset(0, offset)

    local engage = self:getState(AiStateEngage)

    uiPos:drawSurfaceText(Font.MEDIUM, fontColor, "l", string.format(
        "Skill Level: %i",
        engage.skill
    ))

    uiPos:offset(0, offset)

    if not player:isAlive() then
        return
    end

    uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
    uiPos:offset(0, 10)

    if self.currentState then
        uiPos:drawSurfaceText(Font.MEDIUM, fontColor, "l", string.format(
            "Behaviour: %s",
            self.currentState.name
        ))

        uiPos:offset(0, offset)

        uiPos:drawSurfaceText(Font.MEDIUM, fontColor, "l", string.format(
            "Priority: %s [%i]",
            AiState.priorityMap[self.lastPriority],
            self.lastPriority
        ))

        uiPos:offset(0, offset)
    end

    if self.nodegraph.task then
        uiPos:drawSurfaceText(Font.MEDIUM, fontColor, "l", string.format(
            "Task: %s",
            self.nodegraph.task
        ))

        uiPos:offset(0, offset)
    end

    uiPos:clone():offset(-5, 5):drawSurfaceRectangle(spacerDimensions, spacerColor)
    uiPos:offset(0, 10)

    if self.nodegraph.path and self.nodegraph.pathCurrent then
        local node = self.nodegraph.path[self.nodegraph.pathCurrent]

        if node then
            uiPos:drawSurfaceText(Font.MEDIUM, Node.typesColor[node.type], "l", string.format(
                "Next node: %s [%i]",
                Node.typesName[node.type],
                node.id
            ))

            uiPos:offset(0, offset)
        end

        local goalNode = self.nodegraph.pathEnd

        if goalNode then
            uiPos:drawSurfaceText(Font.MEDIUM, fontColor, "l", string.format(
                "Distance to goal: %iu",
                player:getOrigin():getDistance(goalNode.origin)
            ))

            uiPos:offset(0, offset)
        end
    end

    local failsColor =  self.nodegraph.pathfindFails > 0 and Color:hsla(0, 0.8, 0.6) or fontColor

    uiPos:drawSurfaceText(Font.MEDIUM, failsColor, "l", string.format(
        "Pathfind fails: %i",
        self.nodegraph.pathfindFails
    ))

    uiPos:offset(0, offset)

    if self.nodegraph.closestNode then
        local node = self.nodegraph.closestNode

        uiPos:drawSurfaceText(Font.MEDIUM, Node.typesColor[node.type], "l", string.format(
            "Closest node: %s [%i]",
            Node.typesName[node.type],
            node.id
        ))

        uiPos:offset(0, offset)
    end
end

--- @param ai AiOptions
--- @return void
function AiController:activities(ai)
    local isQuickStopping = self.isQuickStopping

    self.isQuickStopping = false

    Menu.standaloneQuickStopRef:set(isQuickStopping)

    local isWalking = self.isWalking

    self.isWalking = nil

    if isWalking then
        ai.cmd.in_speed = 1
    end

    local canUseGear = self.canUseGear
    local canUseKnife = self.canUseKnife
    local canReload = self.canReload

    self.canUseGear = true
    self.canReload = true
    self.canUseKnife = true

    if not canUseGear then
        return
    end

    if canUseKnife then
        for _, dormantAt in pairs(AiUtility.dormantAt) do
            local dormantTime = Time.getRealtime() - dormantAt

            if dormantTime < 3 then
                canUseKnife = false
            end
        end
    end

    local player = AiUtility.client
    local origin = player:getOrigin()

    if player:isReloading() then
        canUseKnife = false
    end

    local closestCautionNode = ai.nodegraph:getClosestNodeOf(origin, Node.types.CAUTION)

    if closestCautionNode and origin:getDistance(closestCautionNode.origin) < 500 then
        canUseKnife = false
    end

    local bomb = AiUtility.plantedBomb

    if bomb then
        local mustDefuse = next(AiUtility.enemies) and false or true

        if mustDefuse then
            canReload = false
        end
    end

    local isHoldingKnife = player:isHoldingWeapon(Weapons.KNIFE)

    if isHoldingKnife and not canUseKnife then
        Client.equipWeapon()
    elseif not isHoldingKnife and canUseKnife then
        Client.equipKnife()
    end

    if canReload then
        local weapon = Entity:create(player:m_hActiveWeapon())
        local csgoWeapon = CsgoWeapons[weapon:m_iItemDefinitionIndex()]
        local ammo = weapon:m_iClip1()
        local maxAmmo = csgoWeapon.primary_clip_size

        local reloadRatio = 0.9

        if AiUtility.closestEnemy then
            local closestEnemyDistance = origin:getDistance(AiUtility.closestEnemy:getOrigin())

            if closestEnemyDistance > 1024 then
                reloadRatio = 0.75
            elseif closestEnemyDistance > 512 then
                reloadRatio = 0.2
            elseif closestEnemyDistance > 256 then
                reloadRatio = 0.1
            elseif closestEnemyDistance > 0 then
                reloadRatio = 0
            end
        end

        if ammo / maxAmmo < reloadRatio then
            ai.cmd.in_reload = 1
        end
    end

    local canInspectWeapon = self.canInspectWeapon

    self.canInspectWeapon = true

    if self.canInspectWeaponTimer:isElapsedThenRestart(self.canInspectWeaponTime) and canInspectWeapon then
        self.canInspectWeaponTimer:restart()
        self.canInspectWeaponTime = Client.getRandomFloat(30, 90)

        Client.cmd("+lookatweapon")

        Client.onNextTick(function()
            Client.cmd("-lookatweapon")
        end)
    end
end

--- @param ai AiOptions
--- @return void
function AiController:antiAfk(ai)
    if self.antiAfkTimer:isElapsedThenRestart(1) then
        self.antiAfkLookAngles.p = Client.getRandomFloat(-10, 10)
        self.antiAfkMoveYaw = Client.getRandomFloat(-180, 180)
    end

    ai.cmd.pitch = self.antiAfkLookAngles.p
    ai.cmd.yaw = self.antiAfkLookAngles.y
    ai.cmd.forwardmove = 125
    ai.cmd.move_yaw = self.antiAfkMoveYaw
end

--- @param ai AiOptions
--- @return void
function AiController:antiFlash(ai)
    local playerEid = Client.getEid()
    local eyeOrigin = Client.getEyeOrigin()

    if not self.canLookAwayFromFlash then
        self.canLookAwayFromFlash = true

        return
    end

    if self.activeFlashbang then
        local visibleVertices = 0

        for _, vertex in pairs(self.activeFlashbang:m_vecOrigin():getBox(16, 16, 16, Vector3.align.CENTER)) do
            local _, fraction = eyeOrigin:getTraceLine(vertex, playerEid)

            if fraction == 1 then
                visibleVertices = visibleVertices + 1
            end
        end

        if visibleVertices == 0 then
            self.activeFlashbang = nil

            return
        end

        self.flashbangVisibleTimer:ifPausedThenStart()

        if self.flashbangVisibleTimer:isElapsed(0.25) then
            ai.view:lookAtLocation(eyeOrigin:getAngle(self.activeFlashbang:m_vecOrigin()):getBackward() * Vector3.MAX_DISTANCE, 4)
        end

        return
    else
        self.flashbangVisibleTimer:stop()
    end

    local cameraAngles = Client.getCameraAngles()

    for _, flash in Entity.find({Weapons.GRENADE_PROJECTILE}) do repeat
        if flash:m_flDamage() ~= 100 then
            break
        end

        local flashOrigin = flash:m_vecOrigin()

        if cameraAngles:getFov(eyeOrigin, flashOrigin) > 35 then
            break
        end

        local _, fraction = eyeOrigin:getTraceLine(flashOrigin, playerEid)

        if fraction == 1 then
            self.activeFlashbang = flash
        end
    until true end
end

--- @param ai AiOptions
--- @return void
function AiController:antiBlock(ai)
    if not self.canAntiBlock then
        self.canAntiBlock = true

        return
    end

    local player = AiUtility.client

    if player:m_vecVelocity():getMagnitude() > 120 then
        return
    end

    local isBlocked = false
    local origin = player:getOrigin()
    local collisionOrigin = origin:clone():offset(0, 0, -32) + (Client.getCameraAngles():set(0):getForward() * 64)
    local collisionBounds = collisionOrigin:getBounds(Vector3.align.BOTTOM, 48, 48, 96)
    --- @type Player
    local blockingTeammate

    for _, teammate in pairs(AiUtility.teammates) do
        if teammate:getOrigin():offset(0, 0, 36):isInBounds(collisionBounds) then
            isBlocked = true

            blockingTeammate = teammate

            break
        end
    end

    if not isBlocked then
        self.antiBlockLookAngles = nil

        return
    end

    if not self.antiBlockLookAngles then
        self.antiBlockLookAngles = Client.getEyeOrigin():getAngle(blockingTeammate:getEyeOrigin())
    end

    self.unblockTimer:ifPausedThenStart()

    if self.unblockTimer:isElapsedThenStop(self.antiBlockDuration) then
        if not self.unblockDirection then
            self.unblockDirection = Client.getChance(2) and "Left" or "Right"
        elseif self.unblockDirection == "Left" then
            self.unblockDirection = "Right"
        else
            self.unblockDirection = "Left"
        end

        self.antiBlockDuration = Client.getRandomFloat(1, 1.25)
    end

    local directionMethod = string.format("get%s", self.unblockDirection)
    local eyeOrigin = Client.getEyeOrigin()
    local movementAngles = Angle:new(ai.cmd.pitch, ai.cmd.yaw)
    local directionOffset = eyeOrigin + movementAngles[directionMethod](movementAngles)

    ai.nodegraph.moveYaw = eyeOrigin:getAngle(directionOffset).y

    ai.view:lookInDirection(self.antiBlockLookAngles, 3)
end

--- @param cmd SetupCommandEvent
--- @return void
function AiController:antiFly(cmd)
    local playerOrigin = Client.getOrigin()

    if self.antiFlyTimer:isElapsedThenRestart(0.75) then
        self.antiFlyValues = {}
    end

    table.insert(self.antiFlyValues, playerOrigin.z)

    local lastValue = self.antiFlyValues[1]
    local isLastValueGreater = false
    local fails = 0

    for _, value in pairs(self.antiFlyValues) do repeat
        value = math.floor(value)

        if value == lastValue then
            break
        end

        if value > lastValue and not isLastValueGreater then
            isLastValueGreater = true
            lastValue = value

            fails = fails + 1
        elseif value < lastValue and isLastValueGreater then
            isLastValueGreater = false
            lastValue = value

            fails = fails + 1
        end

        lastValue = value
    until true end

    local onGround = AiUtility.client:getFlag(Player.flags.FL_ONGROUND)

    if not onGround and fails > 10 then
        cmd.in_jump = 1
    end
end

--- @return void
function AiController:unblockNodes()
    if not self.unblockNodesTimer:isElapsedThenStop(20) then
        return
    end

    for _, blockGroup in pairs(self.deactivatedNodesByBlock) do
        for _, node in pairs(blockGroup) do
            node.active = true
        end
    end
end

--- @param ai AiOptions
--- @return void
function AiController:lookAround(ai)

    if not self.canLookAround then
        return
    end

    if not self.lookAroundTimer:isElapsed(4) then
        return
    end

    local eyeOrgin = Client.getEyeOrigin()
    local playerEid = Client.getEid()
    local plane = eyeOrgin:getPlane(128)
    local farVertices = {}
    local iFarVertices = 1

    for _, vertex in pairs(plane) do
        local _, fraction = eyeOrgin:getTraceLine(vertex, playerEid)

        if fraction == 1 then
            farVertices[iFarVertices] = vertex
            iFarVertices = iFarVertices + 1
        end
    end

    if #farVertices == 0 then
        return
    end

    if self.lookAroundTimer:isElapsedThenRestart(6) then
        self.lookAroundAngles = eyeOrgin:getAngle(farVertices[Client.getRandomInt(1, #farVertices)])
    end

    ai.view:lookInDirection(self.lookAroundAngles, 6)
end

--- @return void
function AiController:unscope()
    if not self.canUnscope then
        self.canUnscope = true

        self.unscopeTimer:restart()

        return
    end

    local isScoped = AiUtility.client:m_bIsScoped() == 1

    if isScoped and not self.unscopeTimer:isStarted() then
        self.unscopeTimer:start()
    end

    if not isScoped then
        self.unscopeTimer:stop()
    end

    if isScoped and self.unscopeTimer:isElapsed(self.unscopeTime) then
        Client.unscope(true)
    end
end

--- @class AiOptions
--- @field controller AiController
--- @field nodegraph Nodegraph
--- @field view AiView
--- @field radio AiRadio
--- @field voice AiVoice
--- @field cmd SetupCommandEvent
--- @field priority number
---
--- @param cmd SetupCommandEvent
--- @return void
function AiController:think(cmd)
    -- Possible fix for bug where logic loop still executes in spite of being out of a server.
    if not globals.mapname() then
        return
    end

    if self.antiAfkEnabled then
        self:antiAfk({
            controller = self,
            nodegraph = self.nodegraph,
            view = self.view,
            cmd = cmd
        })
    end

    self:antiFly(cmd)
    self:unblockNodes()

    if not Menu.master:get() or not Menu.enableAi:get() then
        return
    end

    local gameRules = Entity.getGameRules()

    if gameRules:m_bWarmupPeriod() == 1 then
        return
    end

    local player = AiUtility.client

    if not player:isAlive() then
        return
    end

    --- @type AiState
    local currentState
    local highestPriority = -1

    for _, state in pairs(self.states) do
        local priority = state:assess(self.nodegraph)

        if priority > highestPriority then
            currentState = state
            highestPriority = priority
        end
    end

    --- @type AiOptions
    local ai = {
        controller = self,
        nodegraph = self.nodegraph,
        view = self.view,
        radio = self.radio,
        voice = self.voice,
        cmd = cmd,
        priority = highestPriority
    }

    if Menu.enableView:get() then
        self.view:think(cmd)
    end

    if currentState then
        if self.lastPriority ~= highestPriority then
            self.lastPriority = highestPriority

            local executeState = function()
                currentState.lastPriority = highestPriority

                self.nodegraph:clearPath(string.format("Switching AI state to %s", currentState.name))

                if currentState.activate then
                    currentState:activate(ai)
                end

                if currentState.reactivate then
                    currentState.reactivate = nil

                    currentState:activate(ai)
                end
            end

            if currentState.canDelayActivation then
                Client.fireAfter(Client.getRandomFloat(0, 1), executeState)
            else
                executeState()
            end
        end

        self.currentState = currentState

        currentState:think(ai)
    end

    self:activities(ai)
    self:antiBlock(ai)

    self.nodegraph:move(cmd)

    self:antiFlash(ai)
    self:unscope()
end

return Nyx.class("AiController", AiController)
--}}}
