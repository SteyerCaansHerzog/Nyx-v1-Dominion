--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
--}}}

--{{{ AiChatCommandRotate
--- @class AiChatCommandRotate : AiChatCommand
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
    if not self:isValid(ai, sender, args) then
        return
    end

    if ai.reaper.isActive then
        return
    end

    if AiUtility.plantedBomb then
        return
    end

    local site = args[1]

    if site ~= "a" and site ~= "b" then
        return
    end

    local node = ai.nodegraph:getSiteNode(site)

    -- We're already near the site. It would be pointless to activate the rotation.
    if AiUtility.client:getOrigin():getDistance(node.origin) < 1000 then
        return
    end

    ai.states.rotate:rotate(site)
    ai.states.defend.defendingSite = site
end

return Nyx.class("AiChatCommandRotate", AiChatCommandRotate, AiChatCommand)
--}}}
