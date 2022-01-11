--- Nyx.to Domnion
---
--- AI service for CS:GO. Play competitive matchmaking with intuitive bots.
---
--- author Steyer Caans Herzog, Nyx.to <kessie@nyx.to>
--- domain https://nyx.to/dominion
---
--- language LuaJIT
--- version v1.6.0
--- license Proprietary
---
--- dependencies
---     gamesense/nyx
---     gamesense/csgo_weapons

--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
local Table = require "gamesense/Nyx/v1/Api/Table"
--}}}

--{{{ Modules
local AiController = require "gamesense/Nyx/v1/Dominion/Ai/AiController"

local AiStateCheck = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateCheck"
local AiStateDefend = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDefend"
local AiStateDefuse = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDefuse"
local AiStateDeveloper = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDeveloper"
local AiStateDrop = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateDrop"
local AiStateEngage = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEngage"
local AiStateEvacuate = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEvacuate"
local AiStateEvade = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateEvade"
local AiStateFlashbang = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateFlashbang"
local AiStateGraffiti = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateGraffiti"
local AiStateHeGrenade = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateHeGrenade"
local AiStateMolotov = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateMolotov"
local AiStatePatrol = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePatrol"
local AiStatePickupBomb = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePickupBomb"
local AiStatePickupItems = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePickupItems"
local AiStatePlant = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePlant"
local AiStatePush = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStatePush"
local AiStateRush = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateRush"
local AiStateSmoke = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateSmoke"
local AiStateSweep = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateSweep"

local AiSentenceReplyCheater = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyCheater"
local AiSentenceReplyCommend = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyCommend"
local AiSentenceReplyInsult = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyInsult"
local AiSentenceReplyRacism = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyRacism"
local AiSentenceReplyRank = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceReplyRank"
local AiSentenceSayAce = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceSayAce"
local AiSentenceSayGg = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceSayGg"
local AiSentenceSayKills = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Sentence/AiSentenceSayKills"

local AiChatCommandAfk = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandAfk"
local AiChatCommandBacktrack = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBacktrack"
local AiChatCommandBomb = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBomb"
local AiChatCommandBuy = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBuy"
local AiChatCommandDisconnect = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandDisconnect"
local AiChatCommandDrop = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandDrop"
local AiChatCommandEco = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandEco"
local AiChatCommandEnabled = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandEnabled"
local AiChatCommandForce = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandForce"
local AiChatCommandGo = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandGo"
local AiChatCommandKnow = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandKnow"
local AiChatCommandAssist = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandAssist"
local AiChatCommandReload = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandReload"
local AiChatCommandSkill = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSkill"
local AiChatCommandSkillRng = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSkillRng"
local AiChatCommandScramble = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandScramble"
local AiChatCommandSilence = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandSilence"
local AiChatCommandStop = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandStop"
local AiChatCommandVote = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandVote"

local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Pathfinding/Nodegraph"
local NodegraphEditor = require "gamesense/Nyx/v1/Dominion/Pathfinding/NodegraphEditor"
local Performance = require "gamesense/Nyx/v1/Dominion/Utility/Performance"
--}}}

local nodegraph = Nodegraph:new()

NodegraphEditor:new({
    nodegraph = nodegraph
})

AiController:new({
    nodegraph = nodegraph,
    states = {
        AiStateCheck,
        AiStateDefend,
        AiStateDefuse,
        AiStateDeveloper,
        AiStateDrop,
        AiStateEngage,
        AiStateEvacuate,
        AiStateEvade,
        AiStateFlashbang,
        AiStateGraffiti,
        AiStateHeGrenade,
        AiStateMolotov,
        AiStatePatrol,
        AiStatePickupBomb,
        AiStatePickupItems,
        AiStatePlant,
        AiStatePush,
        AiStateRush,
        AiStateSmoke,
        AiStateSweep,
    },
    commands = {
        AiChatCommandAfk,
        AiChatCommandAssist,
        AiChatCommandBacktrack,
        AiChatCommandBomb,
        AiChatCommandBuy,
        AiChatCommandDisconnect,
        AiChatCommandDrop,
        AiChatCommandEco,
        AiChatCommandEnabled,
        AiChatCommandForce,
        AiChatCommandGo,
        AiChatCommandKnow,
        AiChatCommandReload,
        AiChatCommandScramble,
        AiChatCommandSilence,
        AiChatCommandSkill,
        AiChatCommandSkillRng,
        AiChatCommandStop,
        AiChatCommandVote,
    },
    sentences = {
        AiSentenceReplyCheater,
        AiSentenceReplyCommend,
        AiSentenceReplyInsult,
        AiSentenceReplyRacism,
        AiSentenceReplyRank,
        AiSentenceSayAce,
        AiSentenceSayGg,
        AiSentenceSayKills,
    }
})

-- Prevent loading configuration on master accounts.
if not Table.contains(Config.administrators, Panorama.MyPersonaAPI.GetXuid()) then
    config.load("Nyx-v1-Dominion")

    Performance.enable()

    local materials = {
        "vgui_white",
        "vgui/hud/800corner1",
        "vgui/hud/800corner2",
        "vgui/hud/800corner3",
        "vgui/hud/800corner4"
    }

    client.set_event_callback("paint", function()
        local r, g, b, a = 75, 75, 75, 175

        for i=1, #materials do
            local mat = materials[i]

            materialsystem.find_material(mat):alpha_modulate(a)
            materialsystem.find_material(mat):color_modulate(r, g, b)
        end
    end)


    Client.fireAfter(5, function()
        if Config.joinServer then
            Client.cmd("connect 108.61.237.59:27015; password 2940")
        end
    end)
else
    if Config.debug then
        local Debug = require "gamesense/Nyx/v1/Api/Debug"
        local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

        Debug:new({
            VectorsAngles.Vector3
        })
    end
end
