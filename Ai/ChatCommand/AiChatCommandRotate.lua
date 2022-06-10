--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
--}}}

--{{{ AiChatCommandRotate
--- @class AiChatCommandRotate : AiChatCommandBase
local AiChatCommandRotate = {
    cmd = "rot",
    requiredArgs = 1,
    isAdminOnly = false
}

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandRotate:invoke(ai, sender, args)
    if AiUtility.gamemode == "hostage" then
        return self.GAMEMODE_IS_NOT_DEMOLITION
    end

    if ai.reaper.isActive then
        return self.REAPER_IS_ACTIVE
    end

    if AiUtility.plantedBomb then
        return self.BOMB_IS_PLANTED
    end

    local site = args[1]

    if site ~= "a" and site ~= "b" then
        return
    end

    site = site:upper()

    local node = Nodegraph.getBombsite(site)

    ai.states.engage.tellRotateTimer:restart()

    -- We're already near the site. It would be pointless to activate the rotation.
    if LocalPlayer:getOrigin():getDistance(node.origin) < 1000 then
        return "the client is already near the bombsite"
    end

    ai.states.rotate:rotate(site)
    ai.states.defend.defendingSite = site
end

return Nyx.class("AiChatCommandRotate", AiChatCommandRotate, AiChatCommandBase)
--}}}
