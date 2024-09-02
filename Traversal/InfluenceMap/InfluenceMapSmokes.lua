--{{{ Dependencies
local Entity = require "gamesense/Nyx/v1/Api/Entity"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local InfluenceMapBase = require "gamesense/Nyx/v1/Dominion/Traversal/InfluenceMap/InfluenceMapBase"
--}}}

--{{{ InfluenceMapSmokes
--- @class InfluenceMapSmokes : InfluenceMapBase
local InfluenceMapSmokes = {}

--- @param fields InfluenceMapSmokes
--- @return InfluenceMapSmokes
function InfluenceMapSmokes:new(fields)
	return Nyx.new(self, fields)
end

--- @param nodes NodeTypeTraverse[]
--- @return void
function InfluenceMapSmokes:think(nodes)
	local now = globals.tickcount()

	for _, node in pairs(nodes) do
		self.weights[node.id] = 0
	end

	for _, smoke in Entity.find("CSmokeGrenadeProjectile") do repeat
		local tickBegin = smoke:m_nSmokeEffectTickBegin()

		if tickBegin == 0 or now - tickBegin >= 1150 then
			break
		end

		local smokeOrigin = smoke:m_vecOrigin()
		local smokeMaxBounds = smokeOrigin:getBounds(Vector3.align.UP, 175, 175, 72)

		for _, node in pairs(nodes) do
			if node.origin:isInBounds(smokeMaxBounds) then
				self.weights[node.id] = 750
			end
		end
	until true end
end

return Nyx.class("InfluenceMapSmokes", InfluenceMapSmokes, InfluenceMapBase)
--}}}
