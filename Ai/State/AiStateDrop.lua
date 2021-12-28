--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Framework"
local Player = require "gamesense/Nyx/v1/Api/Player"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local AiState = require "gamesense/Nyx/v1/Dominion/Ai/State/AiState"
--}}}

--{{{ AiStateDrop
--- @class AiStateDrop : AiState
--- @field droppingGearTimer Timer
--- @field isDroppingGear boolean
--- @field requestingPlayer Player
--- @field requestableGear fun(): void
local AiStateDrop = {
    name = "Drop",
    isDelayedWhenActivated = false,
    requestableGear = {
        bomb = Client.equipBomb,
        gun = Client.equipWeapon
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

    self.requestableGear[requestedGear]()
end

--- @return number
function AiStateDrop:assess()
    return self.isDroppingGear and AiState.priority.DROP or AiState.priority.IGNORE
end

--- @param ai AiOptions
--- @return void
function AiStateDrop:think(ai)
    ai.controller.canLookAwayFromFlash = false
    ai.controller.canUseGear = false

    local hitbox = self.requestingPlayer:getHitboxPosition(Player.hitbox.HEAD)

    ai.view:lookAt(hitbox, 8)

    if Client.getCameraAngles():getMaxDiff(Client.getEyeOrigin():getAngle(hitbox)) < 8 then
        self.droppingGearTimer:startIfPaused()

        if self.droppingGearTimer:isElapsedThenStop(0.1) then
            Client.dropGear()

            self.isDroppingGear = false

            Client.fireAfter(Client.getRandomFloat(1, 2), function()
                local player = Player.getClient()

                if player:hasWeapons(AiUtility.mainWeapons) then
                    return
                end

                if player:m_iAccount() >= 3200 then
                    Client.cmd("buy m4a4; buy ak47; buy m4a1_silencer")
                else
                    Client.cmd("buy deagle")
                end
            end)
        end
    end
end

return Nyx.class("AiStateDrop", AiStateDrop, AiState)
--}}}
