--{{{ Debug
--- @class DominionDebug
local Debug = {
	isDisplayingNodeLookAngles = false,
	isDisplayingNodeConnections = false,
	isDisplayingConnectionCollisions = false,
	isDisplayingGapCollisions = false,
	isLoggingLookState = false,
	isLoggingStatePriorities = true,
	isFilteringConsole = true,
	isLoggingPathfinderMoveOntoNextNode = false,
	highlightStates = {}
}

return Debug
--}}}
