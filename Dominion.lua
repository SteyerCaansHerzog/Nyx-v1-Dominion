--- Nyx.to Domnion
---
--- AI service for CS:GO. Play competitive matchmaking with intuitive bots.
---
--- author Steyer Caans Herzog, Nyx.to <kessie@nyx.to>
--- domain https://nyx.to/dominion
---
--- language LuaJIT
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
    nodegraph = nodegraph
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
