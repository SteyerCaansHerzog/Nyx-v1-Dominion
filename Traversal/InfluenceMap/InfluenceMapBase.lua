--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ InfluenceMapBase
--- @class InfluenceMapBase : Class
--- @field weights number[]
local InfluenceMapBase = {}

--- @param fields InfluenceMapBase
--- @return InfluenceMapBase
function InfluenceMapBase:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function InfluenceMapBase:__init()
	self.weights = {}
end

--- @param nodes NodeTypeTraverse
--- @return void
function InfluenceMapBase:think(nodes) end

return Nyx.class("InfluenceMapBase", InfluenceMapBase)
--}}}
