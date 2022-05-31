--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Server = require "gamesense/Nyx/v1/Api/Server"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Time = require "gamesense/Nyx/v1/Api/Time"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local WebSockets = require "gamesense/Nyx/v1/Api/WebSockets"
--}}}

--{{{ Modules
local AiVoice = require "gamesense/Nyx/v1/Dominion/Ai/AiVoice"
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"

local Allocate = require "gamesense/Nyx/v1/Dominion/Client/Message/Allocate"
local ApplyCooldown = require "gamesense/Nyx/v1/Dominion/Client/Message/ApplyCooldown"
local CancelMatch = require "gamesense/Nyx/v1/Dominion/Client/Message/CancelMatch"
local Deallocate = require "gamesense/Nyx/v1/Dominion/Client/Message/Deallocate"
local EndMatch = require "gamesense/Nyx/v1/Dominion/Client/Message/EndMatch"
local KeepAlive = require "gamesense/Nyx/v1/Dominion/Client/Message/KeepAlive"
local LogonRequest = require "gamesense/Nyx/v1/Dominion/Client/Message/LogonRequest"
local LogonSuccess = require "gamesense/Nyx/v1/Dominion/Client/Message/LogonSuccess"
local ReloadClient = require "gamesense/Nyx/v1/Dominion/Client/Message/ReloadClient"
local StartMatch = require "gamesense/Nyx/v1/Dominion/Client/Message/StartMatch"
local SyncLobby = require "gamesense/Nyx/v1/Dominion/Client/Message/SyncLobby"
local UpdateMatch = require "gamesense/Nyx/v1/Dominion/Client/Message/UpdateMatch"
local SkipMatch = require "gamesense/Nyx/v1/Dominion/Client/Message/SkipMatch"

--- @type ServerCrasher
local ServerCrasher

if Config.isLiveClient and not Config.isAdministrator(Panorama.MyPersonaAPI.GetXuid()) then
    ServerCrasher = require "gamesense/Nyx/v1/Api/ServerCrasher"
end
--}}}

--{{{ CooldownType
local CooldownType = {
    GRIEFING = "GRIEFING",
    SKIPPED_MATCH = "SKIPPED_MATCH"
}
--}}}

--{{{ DominionClient
--- @class DominionClient : Class
--- @field url string
--- @field logonToken string
--- @field maps boolean[]
---
--- @field server WebSockets
--- @field allocation Allocate
--- @field isInLobby boolean
--- @field allocationTimer number
--- @field allocationExpiry number
--- @field lastLobbyErrorTimer Timer
--- @field griefHurtAmount number
--- @field griefHurtThreshold number
local DominionClient = {
    url = "ws://localhost:8080",
    logonToken = "9f2651dc-bafb-43d0-a5e0-6d0b0757e4db",
    maps = {
        mg_de_ancient = true,
        mg_de_basalt = true,
        mg_de_cache = true,
        mg_de_dust2 = true,
        mg_de_inferno = true,
        mg_de_mirage = true,
        mg_de_mirage = true,
        mg_de_overpass = true,
        mg_de_train = true,
        mg_de_vertigo = true,
    }
}

--- @return DominionClient
function DominionClient:new()
    return Nyx.new(self)
end

--- @return void
function DominionClient:__init()
    self.allocationTimer = Timer:new()
    self.allocationExpiry = 3 * 60
    self.lastLobbyErrorTimer = Timer:new():start()
    self.griefHurtAmount = 0
    self.griefHurtThreshold = 200

    self.server = WebSockets:new({
        ip = self.url,
        token = self.logonToken,
        callbacks = {
            open = function()
                self:initWs()
            end
        },
        isDebugging = false
    })

    Callbacks.frameGlobal(function()
        if not self.server then
            return
        end

        if not self.allocation then
            return
        end

        self.isInLobby = Panorama.LobbyAPI.IsPartyMember(Panorama.MyPersonaAPI.GetXuid())

        if self.isInLobby then
            self.allocationTimer:stop()
        end

        if not self.isInLobby and self.allocationTimer:isElapsedThenStop(self.allocationExpiry) then
            self.server:transmit(CancelMatch:new({
                reason = "bot was not invited to the lobby in time"
            }))
        end

        self:checkLobby()
    end)

    Callbacks.levelInit(function()
        if not self.server then
            return
        end

        if not self.allocation then
            return
        end

        self.server:transmit(StartMatch)
    end)

    Callbacks.netUpdateEnd(function()
        if not self.server then
            return
        end

        self:checkIsValveDs()
    end)

    Callbacks.roundEnd(function()
        if not self.server then
            return
        end

        if not self.allocation then
            return
        end

        Client.onNextTick(function()
            local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()

            self.server:transmit(UpdateMatch:new({
                roundsPlayed = roundsPlayed
            }))
        end)
    end)

    Callbacks.csWinPanelMatch(function()
        if not self.server then
            return
        end

        if not self.allocation then
            return
        end

        if self.allocation and Server.isIngame() then
            Client.fireAfter(Client.getRandomFloat(8, 16), function()
                Client.execute("disconnect")

                if self.isInLobby then
                    Panorama.LobbyAPI.CloseSession()

                    self.isInLobby = false
                end
            end)
        end

        Client.onNextTick(function()
            local roundsPlayed = Entity.getGameRules():m_totalRoundsPlayed()
            local scoreData = Table.fromPanorama(Panorama.GameStateAPI.GetScoreDataJSO())
            local tWins = scoreData.teamdata.TERRORIST.score
            local ctWins = scoreData.teamdata.CT.score
            local player = Player.getClient()
            local isWinner

            if player:isCounterTerrorist() then
                isWinner = ctWins > tWins
            else
                isWinner = tWins > ctWins
            end

            self.server:transmit(EndMatch:new({
                roundsPlayed = roundsPlayed,
                isWinner = isWinner
            }))

            -- Anti-griefing.
            if self.griefHurtAmount > self.griefHurtThreshold then
                self.server:transmit(ApplyCooldown:new({
                    reason = CooldownType.GRIEFING,
                    expiresAt = DominionClient.getTimePlusDays(7),
                    isPermanent = false
                }))
            end
        end)
    end)

    Callbacks.levelInit(function()
    	self.griefHurtAmount = 0
    end)

    Callbacks.playerHurt(function(e)
        if e.victim:isClient() and e.attacker:isTeammate() then
            self.griefHurtAmount = self.griefHurtAmount + e.dmg_health
        end

        if e.attacker:isClient() and e.weapon == "inferno" and e.victim:isTeammate() then
            self.griefHurtAmount = self.griefHurtAmount + e.dmg_health
        end
    end)
end

--- @param days number
--- @return number
function DominionClient.getTimePlusDays(days)
    return Time.getUnixTimestamp() + (days * 86400)
end

--- @param hours number
--- @return number
function DominionClient.getTimePlusHours(hours)
    return Time.getUnixTimestamp() + (hours * 3600)
end

--- @return void
function DominionClient:checkIsValveDs()
    local gameRules = Entity.getGameRules()

    if not self.allocation then
        return
    end

    if gameRules:m_bIsValveDS() == 0 then
        Client.execute("disconnect")

        self.server:transmit(CancelMatch:new({
            reason = "attempted to play on local or community server"
        }))
    end
end

--- @return void
function DominionClient:checkLobby()
    if not self.lastLobbyErrorTimer:isElapsedThenRestart(2) then
        return
    end

    self:checkLobbyInvite()

    if not Panorama.LobbyAPI.IsSessionActive() then
        return
    end

    if Panorama.LobbyAPI.GetMatchmakingStatusString() ~= "#SFUI_QMM_State_find_searching" then
        return
    end

    self:checkAllBotsInLobby()
    self:checkValidLobbySettings()
end

--- @return void
function DominionClient:checkLobbyInvite()
    for i = 1, Panorama.PartyBrowserAPI.GetInvitesCount() do
        local lobbyId = Panorama.PartyBrowserAPI.GetInviteXuidByIndex(i - 1)

        if Panorama.PartyBrowserAPI.GetPartyMemberXuid(lobbyId, 0) == self.allocation.steamid then
            Panorama.PartyBrowserAPI.ActionJoinParty(lobbyId)

            break
        end
    end
end

--- @return void
function DominionClient:checkAllBotsInLobby()
    local botsRequired = #self.allocation.botSteamids
    local botsFound = 0

    for i = 0, Panorama.PartyListAPI.GetCount() - 1 do
        local xuid = Panorama.PartyListAPI.GetXuidByIndex(i)

        for _, botXuid in pairs(self.allocation.botSteamids) do
            if xuid == botXuid then
                botsFound = botsFound + 1

                break
            end
        end
    end

    if botsFound ~= botsRequired then
        self:stopQueue("Please invite all bots before starting the queue")
    end
end

--- @return void
function DominionClient:checkValidMapSelection()
    local settings = Panorama.LobbyAPI.GetSessionSettings()
    local queuedMapsStr = settings.game.mapgroupname

    if not queuedMapsStr then
        return
    end

    local queuedMaps = Table.getExplodedString(queuedMapsStr, ",")
    local invalidMaps = {}

    for _, map in pairs(queuedMaps) do
        if map == "mg_lobby_mapveto" then
            self:stopQueue("Premier is not supported at this time")

            return
        end

        if not self.maps[map] then
            table.insert(invalidMaps, map)
        end
    end

    if #invalidMaps == 0 then
        return
    end

    self:stopQueue(string.format(
        "Please remove these maps: %s",
        table.concat(invalidMaps, ", ")
    ))

    return
end

--- @return void
function DominionClient:checkValidLobbySettings()
    local settings = Panorama.LobbyAPI.GetSessionSettings()
    local error

    if settings.options.server ~= "official" then
        error = "Only official Valve servers are supported"

        self.server:transmit(CancelMatch:new({
            reason = "attempted to play on local server"
        }))
    elseif settings.game.mode ~= "competitive" then
        error = "Only competitive matchmaking is supported"
    end

    if error then
        self:stopQueue(error)
    else
        self:checkValidMapSelection()
    end
end

--- @return void
function DominionClient:stopQueue(error)
    Panorama.PartyListAPI.SessionCommand(
        'Game::Chat',
        string.format(
            'run all xuid %s chat %s',
            Panorama.MyPersonaAPI.GetXuid(),
            string.format(
                "[Nyx.to Dominion] %s.",
                error
            ):gsub(' ', ' ')
        )
    )

    Panorama.LobbyAPI.StopMatchmaking()
end

--- @return void
function DominionClient:initWs()
    self.server:onReconnect(function()
        self:logon()
    end)

    self:logon()
end

--- @return void
function DominionClient:logon()
    self.server:onReceive(LogonSuccess, function(logon)
        self.server.token = logon.token

        self:keepAlive()
    end)

    self.server.token = self.logonToken

    self.server:transmit(LogonRequest:new({
        steamid = Panorama.MyPersonaAPI.GetXuid(),
        username = Panorama.MyPersonaAPI.GetName(),
        friendCode = Panorama.MyPersonaAPI.GetFriendCode(),
        rank = Panorama.MyPersonaAPI.GetCompetitiveRank()
    }))

    self.server:onReceive(Allocate, function(allocation)
        self.allocation = allocation

        if allocation.voicePacks then
            local idx
            local steamid = Panorama.MyPersonaAPI.GetXuid()

            for i = 1, #allocation.botSteamids do
                if allocation.botSteamids[i] == steamid then
                    idx = i

                    break
                end
            end

            if idx then
                MenuGroup.voicePack:set(self.allocation.voicePacks[idx])
            end
        end

        self.allocationTimer:start()
    end)

    self.server:onReceive(Deallocate, function()
        self.allocation = nil

        MenuGroup.voicePack:set(0)
    end)

    self.server:onReceive(ReloadClient, function()
    	Client.reloadApi()
    end)

    self.server:onReceive(SkipMatch, function()
        if not ServerCrasher then
            return
        end

        Client.fireAfter(1, function()
            if self.allocation and Server.isIngame() then
                ServerCrasher.start()
            end
        end)
    end)
end

--- @return void
function DominionClient:keepAlive()
    if not self.server:transmit(KeepAlive) then
        return
    end

    if self.allocation then
        self.allocation.isInLobby = Panorama.LobbyAPI.IsSessionActive()
        self.allocation.isInGame = Server.isConnected()
        self.allocation.isInQueue = Panorama.LobbyAPI.GetMatchmakingStatusString() == "#SFUI_QMM_State_find_searching"

        self.server:transmit(SyncLobby:new({
            allocation = self.allocation:__serialize()
        }))
    end

    Client.fireAfter(1, function()
        self:keepAlive()
    end)
end

--- @return void
function DominionClient:skipMatch()
    if not ServerCrasher then
        return
    end

    Client.fireAfter(1, function()
        if self.allocation and Server.isIngame() then
            ServerCrasher.start()

            Client.fireAfter(30, function()
                self.server:transmit(ApplyCooldown:new({
                    reason = CooldownType.SKIPPED_MATCH,
                    isPermanent = false,
                    expiresAt = DominionClient.getTimePlusHours(2)
                }))
            end)
        end
    end)
end

return Nyx.class("DominionClient", DominionClient)
--}}}
