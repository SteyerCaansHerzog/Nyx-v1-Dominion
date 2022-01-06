--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Client = require "gamesense/Nyx/v1/Api/Client"
local Menu = require "gamesense/Nyx/v1/Api/Menu"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Panorama = require "gamesense/Nyx/v1/Api/Panorama"
--}}}

--{{{ DominionMenu
--- @class DominionMenu : Class
--- @field group Menu
--- @field master MenuItem
--- @field enableHud MenuItem
--- @field limitFps MenuItem
--- @field autoAcceptMatches MenuItem
--- @field useChatCommands MenuItem
--- @field performanceMode MenuItem
---
--- @field enableNodegraph MenuItem
--- @field enableMovement MenuItem
--- @field visualiseNodegraph MenuItem
--- @field visualiseDirectPathing MenuItem
---
--- @field enableEditor MenuItem
--- @field maxNodeConnections MenuItem
--- @field nodeHeight MenuItem
--- @field nodeType MenuItem
---
--- @field enableAi MenuItem
--- @field enableView MenuItem
--- @field visualisePathfinding MenuItem
--- @field enableAutoBuy MenuItem
--- @field enableAimbot MenuItem
--- @field aimSkillLevel MenuItem
--- @field visualiseAimbot MenuItem
---
--- @field standaloneQuickStop MenuItem
local DominionMenu = {}

--- @return DominionMenu
function DominionMenu:new()
    return Nyx.new(self)
end

--- @return void
function DominionMenu:__init()
    self.standaloneQuickStopRef = Menu.reference("misc", "movement", "standalone quick stop")

    local menu = Menu:new("config", "presets")

    self.group = menu
    self.master = menu:checkbox("Nyx Dominion")

    self.enableHud = menu:checkbox("> Disable CS:GO HUD"):setParent(self.master):addCallback(function(item)
        local value = item:get() and 1 or 0

        cvar.cl_draw_only_deathnotices:set_int(value)
    end)

    self.limitFps = menu:checkbox("> Limit FPS"):setParent(self.master):addCallback(function(item)
        local fps = item:get() and 64 or 0

        cvar.fps_max:set_int(fps)
    end)

    self.autoAcceptMatches = menu:checkbox("> Auto-accept Matches"):setParent(self.master)

    local function loop()
        if self.autoAcceptMatches:get() then
            Panorama.LobbyAPI.SetLocalPlayerReady('accept')
        end

        client.delay_call(Client.getRandomFloat(5, 10), loop)
    end

    loop()

    self.useChatCommands = menu:checkbox("> Use Chat Commands"):set(true):setParent(self.master)

    Callbacks.shutdown(function()
        cvar.fps_max:set_int(0)
        cvar.cl_draw_only_deathnotices:set_int(0)
    end)
end

return Nyx.class("DominionMenu", DominionMenu):new()
--}}}
