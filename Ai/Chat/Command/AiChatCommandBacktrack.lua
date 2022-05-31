--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommandBase = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommandBase"
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
--- @return void
function AiChatCommandBacktrack:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local state = args[1]

    if state == "high" then
        for _, tab in pairs(self.tabs) do
            self.refWeaponTab:set(tab)

            self.refAccuracyBoost:set("High")
            self.refAccuracyBoostRange:set(64)
        end
    elseif state == "low" then
        for _, tab in pairs(self.tabs) do
            self.refWeaponTab:set(tab)

            self.refAccuracyBoost:set("Low")
            self.refAccuracyBoostRange:set(16)
        end
    elseif state == "off" then
        for _, tab in pairs(self.tabs) do
            self.refWeaponTab:set(tab)

            self.refAccuracyBoost:set("Off")
            self.refAccuracyBoostRange:set(1)
        end
    end
end

return Nyx.class("AiChatCommandBacktrack", AiChatCommandBacktrack, AiChatCommandBase)
--}}}
