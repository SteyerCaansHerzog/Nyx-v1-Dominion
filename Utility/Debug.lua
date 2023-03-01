--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local DebugValues = require "gamesense/Nyx/v1/Dominion/Utility/DebugValues"
local DebugValuesDefault = require "gamesense/Nyx/v1/Dominion/Utility/DebugValuesDefault"
--}}}

--{{{ Debug
--- @class DominionDebug : Class
--- @field highlightStates string[]
--- @field isDisplayingConnectionCollisions boolean
--- @field isDisplayingGapCollisions boolean
--- @field isDisplayingNodeConnections boolean
--- @field isDisplayingNodeLookAngles boolean
--- @field isFilteringConsole boolean
--- @field isLoggingLookState boolean
--- @field isLoggingPathfinderMoveOntoNextNode boolean
--- @field isLoggingStatePriorities boolean
--- @field isRenderingThreatDetection boolean
--- @field isRenderingVirtualMouse boolean
local Debug = {}

--- @return void
function Debug:__setup()
	for k, v in pairs(DebugValuesDefault) do
		Debug[k] = v
	end

	for k, v in pairs(DebugValues) do
		Debug[k] = v
	end
end

return Nyx.class("Debug", Debug)
--}}}
