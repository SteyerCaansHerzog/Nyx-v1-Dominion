--{{{ Debug
--- @type DominionDebug
local DebugValuesDefault = {
	-- List of state names to highlight when rendering state priorities.
	highlightStates = {},

	-- Display collisions between nodes indicating if they can connect with each other.
	isDisplayingConnectionCollisions = false,

	-- Display gap-detection collisions between the player and nearby nodes.
	isDisplayingGapCollisions = false,

	-- Display a list of node IDs for each connection a node has with other nodes.
	isDisplayingNodeConnections = false,

	-- Display the lookFromOrigin and lookAtOrigin for all directional nodes.
	isDisplayingNodeLookAngles = false,

	-- Filter out console input that is not from Gamesense.
	isFilteringConsole = false,

	-- Log all changes of the Virtual Mouse look state.
	isLoggingLookState = false,

	-- Log every time the AI completes a traversal of a node in a path.
	isLoggingPathfinderMoveOntoNextNode = false,

	-- Log all transitions between states.
	isLoggingStatePriorities = true,

	-- Render the AiThreats system.
	isRenderingThreatDetection = false,

	-- Render the VirtualMouse system.
	isRenderingVirtualMouse = false,
}

return DebugValuesDefault
--}}}
