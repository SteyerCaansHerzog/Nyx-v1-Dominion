--{{{ Dependencies
local Callbacks = require "gamesense/Nyx/v1/Api/Callbacks"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local AiChatCommand = require "gamesense/Nyx/v1/Dominion/Ai/Chat/Command/AiChatCommand"
--}}}

--{{{ AiChatCommandClantag
--- @class AiChatCommandClantag : AiChatCommand
--- @field clantag string
local AiChatCommandClantag = {
    cmd = "tag",
    requiredArgs = 0,
    isAdminOnly = true
}

--- @return void
function AiChatCommandClantag:__init()
    Callbacks.levelInit(function()
    	self:setClantag(self.clantag)
    end)
end

--- @param ai AiController
--- @param sender Player
--- @param args string[]
--- @return void
function AiChatCommandClantag:invoke(ai, sender, args)
    if not self:isValid(ai, sender, args) then
        return
    end

    local clantag = args[1]

    self:setClantag(clantag)

    self.clantag = clantag
end

--- @param clantag string
--- @return void
function AiChatCommandClantag:setClantag(clantag)
    if clantag then
        client.set_clan_tag(clantag)
    else
        client.set_clan_tag()
    end
end

return Nyx.class("AiChatCommandClantag", AiChatCommandClantag, AiChatCommand)
--}}}
