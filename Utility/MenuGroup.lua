--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Menu = require "gamesense/Nyx/v1/Api/Menu"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ DominionMenu
--- @class MenuGroup: Class
--- @field group Menu
--- @field master MenuItem
--- @field disableHud MenuItem
--- @field limitFps MenuItem
--- @field autoAcceptMatches MenuItem
--- @field autoClosePopups MenuItem
--- @field useChatCommands MenuItem
--- @field performanceMode MenuItem
---
--- @field enablePathfinder MenuItem
--- @field visualisePath MenuItem
--- @field enableMovement MenuItem
---
--- @field enableEditor MenuItem
--- @field drawDistance MenuItem
--- @field maxNodeConnections MenuItem
--- @field nodeHeight MenuItem
--- @field nodeType MenuItem
--- @field visibleGroups MenuItem
--- @field selectedNode MenuItem
---
--- @field enableAi MenuItem
--- @field enableAutoBuy MenuItem
--- @field enableAimbot MenuItem
--- @field aimSkillLevel MenuItem
--- @field visualiseAimbot MenuItem
---
--- @field enableMicrophone MenuItem
--- @field voicePack MenuItem
---
--- @field restoreReaperManifest MenuItem
---
--- @field standaloneQuickStopRef MenuItem
--- @field dormantRef MenuItem
--- @field autoKnifeRef MenuItem
local MenuGroup = {}

--- @return MenuGroup
function MenuGroup:new()
    return Nyx.new(self)
end

--- @return void
function MenuGroup.__setup()
    MenuGroup.dormantRef = Menu.reference("visuals", "player esp", "dormant")
    MenuGroup.standaloneQuickStopRef = Menu.reference("misc", "movement", "standalone quick stop")
    MenuGroup.autoKnifeRef = Menu.reference("misc", "miscellaneous", "knifebot")

    local menu = Menu:new("config", "presets")

    MenuGroup.group = menu
    MenuGroup.master = menu:addCheckbox("Nyx Dominion")

    MenuGroup.disableHud = menu:addCheckbox("> Disable CS:GO HUD"):setParent(MenuGroup.master):addCallback(function(item)
        local value = item:get() and 1 or 0

        cvar.cl_draw_only_deathnotices:set_int(value)
    end)

    MenuGroup.limitFps = menu:addCheckbox("> Limit FPS"):setParent(MenuGroup.master):addCallback(function(item)
        local fps = item:get() and 64 or 0

        cvar.fps_max:set_int(fps)
    end)

    MenuGroup.autoAcceptMatches = menu:addCheckbox("> Auto-accept Matches"):setParent(MenuGroup.master)
    MenuGroup.autoClosePopups = menu:addCheckbox("> Auto-close Popups"):setParent(MenuGroup.master)
    MenuGroup.useChatCommands = menu:addCheckbox("> Use Chat Commands"):set(true):setParent(MenuGroup.master)

    MenuGroup.group:addLabel("----------------------------------------"):setParent(MenuGroup.master)

    Callbacks.shutdown(function()
        cvar.fps_max:set_int(0)
        cvar.cl_draw_only_deathnotices:set_int(0)
    end)
end

return Nyx.class("MenuGroup", MenuGroup)
--}}}
