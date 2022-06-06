--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/ChatCommand/AiChatCommandBase"
local MenuGroup = require "gamesense/Nyx/v1/Dominion/Utility/MenuGroup"
--}}}

--{{{ AiChatCommandBacktrack
--- @class AiChatCommandBacktrack : AiChatCommandBase
--- @field tabs string[]
--- @field refWeaponTab MenuItem
--- @field refAccuracyBoost MenuItem
--- @field refAccuracyBoostRange MenuItem
local AiChatCommandBacktrack = {
    cmd = "bt",
    requiredArgs = 1,
    isAdminOnly = false,
    isValidIfSelfInvoked = true,
    tabs = {
        "PISTOL",
        "SMG",
        "RIFLE",
        "SHOTGUN",
        "MACHINE GUN",
        "SNIPER"
    },
    refWeaponTab = MenuGroup.group.reference("legit", "weapon type", "weapon type"),
    refAccuracyBoost = MenuGroup.group.reference("legit", "other", "accuracy boost"),
    refAccuracyBoostRange = MenuGroup.group.reference("legit", "other", "accuracy boost range")
}

--- @param ai AiController
--- @param sender PlayerChatEvent
--- @param args string[]
--- @return string
function AiChatCommandBacktrack:invoke(ai, sender, args)
    local state = args[1]

    if state == "high" then
        for _, tab in pairs(self.tabs) do
            self.refWeaponTab:set(tab)

            self.refAccuracyBoost:set("High")
            self.refAccuracyBoostRange:set(64)
        end

        return
    elseif state == "low" then
        for _, tab in pairs(self.tabs) do
            self.refWeaponTab:set(tab)

            self.refAccuracyBoost:set("Low")
            self.refAccuracyBoostRange:set(16)
        end

        return
    elseif state == "off" then
        for _, tab in pairs(self.tabs) do
            self.refWeaponTab:set(tab)

            self.refAccuracyBoost:set("Off")
            self.refAccuracyBoostRange:set(1)
        end

        return
    end

    return self.NO_VALID_ARGUMENTS
end

return Nyx.class("AiChatCommandBacktrack", AiChatCommandBacktrack, AiChatCommandBase)
--}}}
