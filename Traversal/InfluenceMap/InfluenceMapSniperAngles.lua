--{{{ Dependencies
local LocalPlayer = require "gamesense/Nyx/v1/Api/LocalPlayer"
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
local Table = require "gamesense/Nyx/v1/Api/Table"
local Timer = require "gamesense/Nyx/v1/Api/Timer"
local Trace = require "gamesense/Nyx/v1/Api/Trace"
local VectorsAngles = require "gamesense/Nyx/v1/Api/VectorsAngles"

local Angle, Vector2, Vector3 = VectorsAngles.Angle, VectorsAngles.Vector2, VectorsAngles.Vector3
--}}}

--{{{ Modules
local AiUtility = require "gamesense/Nyx/v1/Dominion/Ai/AiUtility"
local InfluenceMapBase = require "gamesense/Nyx/v1/Dominion/Traversal/InfluenceMap/InfluenceMapBase"
--}}}

--{{{ Definitions
--- @class InfluenceMapSniperAnglesEntry
--- @field player Player
--- @field nodes number[]
--- @field timer Timer
--}}}

--{{{ InfluenceMapSniperAngles
--- @class InfluenceMapSniperAngles : InfluenceMapBase
--- @field entries InfluenceMapSniperAnglesEntry[]
local InfluenceMapSniperAngles = {}

--- @param fields InfluenceMapSniperAngles
--- @return InfluenceMapSniperAngles
function InfluenceMapSniperAngles:new(fields)
	return Nyx.new(self, fields)
end

--- @return void
function InfluenceMapSniperAngles:__init()
	InfluenceMapSniperAngles.__parent.__init(self)

	self.entries = {}
end

--- @param nodes NodeTypeTraverse[]
--- @return void
function InfluenceMapSniperAngles:think(nodes)
	for _, node in pairs(nodes) do
		self.weights[node.id] = 0
	end

	for _, enemy in pairs(AiUtility.enemies) do repeat
		if self.entries[enemy.eid] then
			break
		end

		if not enemy:isHoldingBoltActionRifle() then
			break
		end

		if enemy:m_bIsScoped() ~= 1 then
			break
		end

		local eyeOrigin = enemy:getOrigin():offset(0, 0, 64)
		local trace = Trace.getLineAtAngle(eyeOrigin, enemy:getCameraAngles(), AiUtility.traceOptionsVisible)

		if eyeOrigin:getDistance(trace.endPosition) < 200 then
			break
		end

		local selectedNodes = {}

		for _, node in pairs(nodes) do
			local closestRayPoint = node.origin:getRayClosestPoint(eyeOrigin, trace.endPosition)

			if node.origin:getDistance(closestRayPoint) < 250 then
				table.insert(selectedNodes, node.id)
			end
		end

		if Table.isEmpty(selectedNodes) then
			break
		end

		self.entries[enemy.eid] = {
			player = enemy,
			nodes = selectedNodes,
			timer = Timer:new():start()
		}
	until true end

	local origin = LocalPlayer:getOrigin()

	for eid, entry in pairs(self.entries) do repeat
		if entry.timer:isElapsed(5) then
			self.entries[eid] = nil

			break
		end

		local weight = 1000

		if origin:getDistance(entry.player:getOrigin()) > 1250 then
			weight = 2500
		end

		for _, id in pairs(entry.nodes) do
			self.weights[id] = weight
		end
	until true end
end

return Nyx.class("InfluenceMapSniperAngles", InfluenceMapSniperAngles, InfluenceMapBase)
--}}}
