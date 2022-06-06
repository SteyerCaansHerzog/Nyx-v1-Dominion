--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Math = require "gamesense/Nyx/v1/Api/Math"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local UserInput = require "gamesense/Nyx/v1/Api/UserInput"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiPriority = require "gamesense/Nyx/v1/Dominion/Ai/State/AiPriority"
local AiStateBase = require "gamesense/Nyx/v1/Dominion/Ai/State/AiStateBase"
local WeaponInfo = require "gamesense/Nyx/v1/Dominion/Ai/Info/WeaponInfo"
local Node = require "gamesense/Nyx/v1/Dominion/Traversal/Node/Node"
local Nodegraph = require "gamesense/Nyx/v1/Dominion/Traversal/Nodegraph"
local Pathfinder = require "gamesense/Nyx/v1/Dominion/Traversal/Pathfinder"
local View = require "gamesense/Nyx/v1/Dominion/View/View"
--}}}

--{{{ AiStateDrop
--- @class AiStateDrop : AiStateBase
--- @field droppingGearTimer Timer
--- @field isDroppingGear boolean
--- @field requestingPlayer Player
--- @field requestableGear fun(): nil This is the equip function to equip the item to drop.
--- @field requestedGear string
local AiStateDrop = {
    name = "Drop",
    delayedMouseMin = 0.2,
    delayedMouseMax = 0.5,
    requestableGear = {
        bomb = LocalPlayer.equipBomb,
        weapon = LocalPlayer.equipPrimary
    }
}

--- @param fields AiStateDrop
--- @return AiStateDrop
function AiStateDrop:new(fields)
    return Nyx.new(self, fields)
end

--- @return void
function AiStateDrop:__init()
    self.droppingGearTimer = Timer:new()
    self.isDroppingGear = false
end

--- @param player Player
--- @param requestedGear string
--- @return void
function AiStateDrop:dropGear(player, requestedGear)
    self.requestingPlayer = player
    self.isDroppingGear = true
    self.requestedGear = requestedGear

    self.requestableGear[requestedGear]()
end

--- @return number
function AiStateDrop:assess()
    return self.isDroppingGear and AiPriority.DROP or AiPriority.IGNORE
end

--- @return void
function AiStateDrop:activate()
    Pathfinder.moveToLocation(self.requestingPlayer:getOrigin(), {
        task = "Drop gear to teammate",
        goalReachedRadius = 75,
        isAllowedToTraverseInactives = true
    })
end

--- @param cmd SetupCommandEvent
--- @return void
function AiStateDrop:think(cmd)
    self.activity = string.format("Dropping %s", self.requestedGear)

    self.ai.routines.lookAwayFromFlashbangs:block()
    self.ai.routines.manageGear:block()

    local distance = LocalPlayer:getOrigin():getDistance(self.requestingPlayer:getOrigin())
    local hitbox = self.requestingPlayer:getOrigin():offset(0, 0, 64)
    local isFreezeTime = AiUtility.gameRules:m_bFreezePeriod() == 1

    if isFreezeTime or distance < 300 then
        View.lookAtLocation(hitbox, 9.5, View.noise.minor, "Drop look at requester")
    end

    if isFreezeTime or distance < 200 then
        -- Stop approaching the player.
        Pathfinder.clearActivePathAndLastRequest()

        local fov = Client.getCameraAngles():getFov(Client.getEyeOrigin(), hitbox)

        -- We're looking close enough to the player.
        if fov < 20 then
            self.droppingGearTimer:ifPausedThenStart()

            -- We need to buy something before we can drop.
            if isFreezeTime and not LocalPlayer:hasWeapons(WeaponInfo.primaries) and LocalPlayer:m_iAccount() > 3200 then
                UserInput.execute("buy m4a4; buy ak47; buy m4a1_silencer")
            end

            -- Drop gear.
            if self.droppingGearTimer:isElapsedThenStop(0.1) then
                self.ai.voice.pack:speakGifting()

                LocalPlayer.dropGear()

                self.isDroppingGear = false

                -- We need to rebuy.
                if isFreezeTime or AiUtility.timeData.roundtime < 20 then
                    self:buyGear()
                end
            end
        end
    end
end

--- @return void
function AiStateDrop:buyGear()
    Client.fireAfterRandom(0.75, 1.25, function()
        if not LocalPlayer:hasWeapons(WeaponInfo.primaries) then
            local balance = LocalPlayer:m_iAccount()

            if not balance or (balance and balance >= 3200) then
                UserInput.execute("buy m4a4; buy ak47; buy m4a1_silencer")
            end
        end
    end)
end

return Nyx.class("AiStateDrop", AiStateDrop, AiStateBase)
--}}}
