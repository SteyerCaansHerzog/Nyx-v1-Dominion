--{{{ Dependencies
local Client = require "gamesense/Nyx/v1/Api/Client"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
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
function AiStateDrop:activate(ai)
    ai.voice.pack:speakGifting()
end

--- @param ai AiOptions
--- @return void
function AiStateDrop:think(ai)
    ai.controller.canLookAwayFromFlash = false
    ai.controller.canUseGear = false

    local hitbox = self.requestingPlayer:getOrigin():offset(0, 0, 64)

    ai.view:lookAtLocation(hitbox, 8)

    local fov = Client.getCameraAngles():getFov(Client.getEyeOrigin(), hitbox)

    if fov < 4 then
        self.droppingGearTimer:ifPausedThenStart()

        if self.droppingGearTimer:isElapsedThenStop(0.33) then
            Client.dropGear()

            self.isDroppingGear = false

            Client.fireAfter(Client.getRandomFloat(2, 2.5), function()
                local player = AiUtility.client

                if not player:hasWeapons(AiUtility.mainWeapons) then
                    if player:m_iAccount() >= 3200 then
                        Client.cmd("buy m4a4; buy ak47; buy m4a1_silencer")
                    else
                        Client.cmd("buy deagle")
                    end
                end
            end)
        end
    end
end

return Nyx.class("AiStateDrop", AiStateDrop, AiState)
--}}}
