--{{{ Dependencies
local Nyx = require "gamesense/Nyx/v1/Api/Nyx"
--}}}

--{{{ Modules
local Config = require "gamesense/Nyx/v1/Dominion/Utility/Config"
--}}}

--{{{ Definitions
--- @type Localization
local English = {
	aiDitherLocked = "AI state '%s' is locked due to dithering.", -- state name
	aiNoAssessMethod = "AI state '%s' does not have an ':assess()' method.", -- state name
	aiNoPriority = "AI state '%s' does not return a priority.", -- state name
	aiNotInGame = "Not in-game. Waiting to join a server before initialising AI states.",
	aiReady = "AI Controller is ready.",
	aiStateChanged = "Changed AI state to '%s' [%i].", -- state name
	aiStateGamemodesRequired = "The following gamemodes are required: %s", -- gamemode names
	aiStateLoaded = "AI state '%s' successfully loaded.", -- state name
	aiStateNodesRequired =  "The following nodes are required in the map: %s", -- node names
	aiStateNotLoaded = "AI state '%s' not loaded. %s.", -- state name, reason
	aiStateReactivating = "Re-activating AI state '%s' [%i].", -- state name
	aiUtilityNewRound = "Beginning round #%i.", -- round number
	benchmark = "Benchmark '%s' finished. Time: %.4fs (%.1f ticks).", -- benchmark name
	buyGearPurchased = "Purchased [%i] '%s'.", -- index, item
	chatCommandExecutedArgs = "Executed chat command '/%s' from '%s' with '%s'.", -- command name, invoker, arguments
	chatCommandExecutedNoArgs = "Executed chat command '/%s' from '%s'.", -- command name, invoker
	chatCommandIgnored = "Ignoring chat command '/%s' from '%s': %s.", -- command name, invoke, reason
	chatCommandRejected = "Rejected chat command '/%s' from '%s': %s.", -- command name, invoker, reason
	cmdRejectionAlreadyNearBombsite = "the client is already near the bombsite",
	cmdRejectionArgsMissing = "requires %i arguments, but only %i were given",
	cmdRejectionBombIsPlanted = "the bomb is currently planted",
	cmdRejectionClientIsDead = "the client is not currently alive",
	cmdRejectionCommandIsDeprecated = "the chat command is deprecated",
	cmdRejectionFreezetime = "the round has not started yet",
	cmdRejectionGamemodeIsNotDemolition = "the gamemode is not demolition",
	cmdRejectionGamemodeIsNotHostage = "the gamemode is not hostage",
	cmdRejectionLiveClientRequired = "this command is only available for live clients",
	cmdRejectionLuaError = "the evaluated statement threw an error",
	cmdRejectionNoBomb = "the client does not have the bomb",
	cmdRejectionNoEnemiesAlive = "no enemies are alive",
	cmdRejectionNotAdmin = "the invoker is not an administrator",
	cmdRejectionNotAskingUs = "the invoker was not asking us",
	cmdRejectionNoValidArguments = "no valid arguments were given",
	cmdRejectionNoValidSpawnOrBombsite = "no valid bombsite or spawn name",
	cmdRejectionOnlyCounterTerrorist = "the command only applies to counter-terrorists",
	cmdRejectionOnlyTerrorist = "the command only applies to terrorists",
	cmdRejectionReaperIsActive = "Reaper is currently active",
	cmdRejectionSelfInvoked = "it cannot be self-invoked",
	cmdRejectionSenderIsDead = "the invoker is not currently alive",
	cmdRejectionSenderIsNotTeammate = "the invoker is not a teammate",
	cmdRejectionSenderIsOutOfRange = "the invoker is too far away",
	cmdSkillSet = "Set AI skill level to level %i.", -- skill level
	cmdToggleAiOff = "The AI has been disabled. To re-enable the AI, use the '/ai on' chat command, or check 'Enable AI' in the menu.",
	editorBeginIntegrityTest = "Beginning Nodegraph integrity test.",
	editorObjectiveNodeRequired = "An objective node (CT/T spawn or A/B site) is required to run an integrity test.",
	editorReady = "Nodegraph Editor is ready.",
	language = "English",
	logAlert =      "[ALERT]    ", -- Keep the number of spaces aligned
	logError =      "[ISSUE]    ", -- Keep the number of spaces aligned
	logInfo =       "[INFO]     ", -- Keep the number of spaces aligned
	logInternal =   "[INTERNAL] ", -- Keep the number of spaces aligned
	logOk =         "[OK]       ", -- Keep the number of spaces aligned
	logWarning =    "[WARNING]  ", -- Keep the number of spaces aligned
	manageEconomyEco = "Saving this round.",
	manageEconomyEcoRush = "Eco rushing this round.",
	manageEconomyForceBuy = "Full/force buying this round.",
	manageEconomyFullBuy = "Full buying this round.",
	nodegraphLoaded = "Loaded nodegraph from '%s'.",
	nodegraphMissingFile = "Cannot load graph from '%s'. File does not exist.", -- filename
	nodegraphReady = "Nodegraph is ready.",
	nodegraphSaved = "Saved graph to '%s'.", -- filename
	pathfinderFailed = "Pathfind task '%s' failed: %s.", -- task name, reason
	pathfinderFailedGuessGoal = "Pathfind task '%s' failed: %s. Presumed closest target node: [%i] %s (%s).", -- task name, reason, goal name
	pathfinderFailedKnownGoal = "Pathfind task '%s' failed: %s. Target node: [%i] %s.", -- task name, reason, goal name
	pathfinderMovementDisabled = "Pathfinder movement is not enabled. Consider enabling movement.",
	pathfinderNewTask = "New pathfind task: %s.", -- task name
	pathfinderNoOrigin = "Pathfind task '%s' provided no node to move to.", -- task name
	pathfinderNoOrigin = "Pathfind task '%s' provided no origin to move to.", -- task name
	pathfinderObstructed = "Pathfinder is obstructed. Retrying current path.",
	pathfinderReady = "Pathfinder is ready.",
	reaperAccountRestarted = "A Reaper account has been restarted.",
	reaperIsEnabled = "Reaper Mode is enabled for this client.",
	reaperIsNotEnabled = "Reaper Mode has not been enabled for this client.",
	reaperMissingManifest = "The file 'Resource/Data/ReaperManifest.json' does not exist. Please ensure the directory exists to create this file.",
	reaperNewAccount = "New Reaper account detected.",
	splashBuild = "Current build: ",
	splashCopyright = "Copyright Nyx.to ©%i-%i, all rights reserved.",
	splashDevelopedBy = "Developed and maintained by ",
	splashLanguage = "Current language: ",
	splashLicense = "%02d/%02d/%i. Your license to this software: ",
	splashLicenseNeverExpires = "does not expire",
	splashMotto = "Competitive CS:GO AI built for official servers.",
	viewFreezePrevention = "Client freeze prevention (View.setIdealLookAhead).",
	viewNewState = "New mouse control state: '%s'.", -- mouse state
}

--- @type Localization
local Versaikr = {
	aiDitherLocked = "AI haaþruppet '%s' an klossand for śœfenerre",
	aiNoAssessMethod = "AI haaþruppet '%s' harkim funkśrnen ':assess()'",
	aiNoPriority = "AI haaþruppet '%s' bussaidim vissygr-numen",
	aiNotInGame = "Seber æ vin pa serven. Den varte va buköde serven assor væ zeme AI haaþrupper",
	aiReady = "Den AI an radan",
	aiStateChanged = "Goþantagt haaþruppet til '%s' [%i]",
	aiStateGamemodesRequired = "Domte senirstorser an vaśtaasand: %s",
	aiStateLoaded = "AI haaþruppet '%s' an upplardand",
	aiStateNodesRequired =  "Domte gnaster an vaśtaasand neu kamaaŋet: %s",
	aiStateNotLoaded = "AI haaþruppet '%s' an vin upplardand. %s",
	aiStateReactivating = "Aktivade ehhen AI haaþruppet '%s' [%i]",
	aiUtilityNewRound = "Ćære venauoke rond #%i",
	benchmark = "Vereiklanset '%s' an fœkommarand. Bereit: %.4fs (%.1f tiker)",
	buyGearPurchased = "Śoppagt [%i] '%s'",
	chatCommandExecutedArgs = "",
	chatCommandExecutedNoArgs = "",
	chatCommandIgnored = "",
	chatCommandRejected = "",
	cmdRejectionAlreadyNearBombsite = "",
	cmdRejectionArgsMissing = "",
	cmdRejectionBombIsPlanted = "",
	cmdRejectionClientIsDead = "",
	cmdRejectionCommandIsDeprecated = "",
	cmdRejectionFreezetime = "",
	cmdRejectionGamemodeIsNotDemolition = "",
	cmdRejectionGamemodeIsNotHostage = "",
	cmdRejectionLiveClientRequired = "",
	cmdRejectionLuaError = "",
	cmdRejectionNoBomb = "",
	cmdRejectionNoEnemiesAlive = "",
	cmdRejectionNotAdmin = "",
	cmdRejectionNotAskingUs = "",
	cmdRejectionNoValidArguments = "",
	cmdRejectionNoValidSpawnOrBombsite = "",
	cmdRejectionOnlyCounterTerrorist = "",
	cmdRejectionOnlyTerrorist = "",
	cmdRejectionReaperIsActive = "",
	cmdRejectionSelfInvoked = "",
	cmdRejectionSenderIsDead = "",
	cmdRejectionSenderIsNotTeammate = "",
	cmdRejectionSenderIsOutOfRange = "",
	cmdSkillSet = "",
	cmdToggleAiOff = "",
	editorBeginIntegrityTest = "",
	editorObjectiveNodeRequired = "",
	editorReady = "Gnastemarkon an radan",
	language = "Den Versaikr",
	logAlert =      "[ATANT]     ",
	logError =      "[GENUUG]    ",
	logInfo =       "[NOOÞ]      ",
	logInternal =   "[NADAŊ]     ",
	logOk =         "[RAND]      ",
	logWarning =    "[VAANERAN]  ",
	manageEconomyEco = "",
	manageEconomyEcoRush = "",
	manageEconomyForceBuy = "",
	manageEconomyFullBuy = "",
	nodegraphLoaded = "",
	nodegraphMissingFile = "",
	nodegraphReady = "",
	nodegraphSaved = "",
	pathfinderFailed = "",
	pathfinderFailedGuessGoal = "",
	pathfinderFailedKnownGoal = "",
	pathfinderMovementDisabled = "",
	pathfinderNewTask = "",
	pathfinderNoOrigin = "",
	pathfinderNoOrigin = "",
	pathfinderObstructed = "",
	pathfinderReady = "Maavegon an radan",
	reaperAccountRestarted = "",
	reaperIsEnabled = "",
	reaperIsNotEnabled = "",
	reaperMissingManifest = "",
	reaperNewAccount = "",
	splashBuild = "Domte Versonr: ",
	splashCopyright = "Kopyprotektr ©%i-%i. Al protekterader an forssanćand",
	splashDevelopedBy = "Markand ohh gannsigerrand plau ",
	splashLanguage = "Fersæmr: ",
	splashLicense = "%02d/%02d/%i. Sebet graþaŋr na domte softvar: ",
	splashLicenseNeverExpires = "nær ekomplette",
	splashMotto = "Kompetitiv CS:GO AI markim na pa śafkarre-servyr",
	viewFreezePrevention = "",
	viewNewState = "",
}

--- @type Localization
local Russian = {}

--- @type Localization
local German = {}

local Languages = {
	English = English,
	Versaikr = Versaikr,
	Russian = Russian,
	German = German
}
--}}}

--{{{ Localization
--- @class Localization : Class
--- @field aiDitherLocked string
--- @field aiNoAssessMethod string
--- @field aiNoPriority string
--- @field aiNotInGame string
--- @field aiReady string
--- @field aiStateChanged string
--- @field aiStateGamemodesRequired string
--- @field aiStateLoaded string
--- @field aiStateNodesRequired string
--- @field aiStateNotLoaded string
--- @field aiStateReactivating string
--- @field aiUtilityNewRound string
--- @field benchmark string
--- @field buyGearPurchased string
--- @field chatCommandExecutedArgs string
--- @field chatCommandExecutedNoArgs string
--- @field chatCommandIgnored string
--- @field chatCommandRejected string
--- @field cmdRejectionAlreadyNearBombsite string
--- @field cmdRejectionArgsMissing string
--- @field cmdRejectionBombIsPlanted string
--- @field cmdRejectionClientIsDead string
--- @field cmdRejectionCommandIsDeprecated string
--- @field cmdRejectionFreezetime string
--- @field cmdRejectionGamemodeIsNotDemolition string
--- @field cmdRejectionGamemodeIsNotHostage string
--- @field cmdRejectionLiveClientRequired string
--- @field cmdRejectionLuaError string
--- @field cmdRejectionNoBomb string
--- @field cmdRejectionNoEnemiesAlive string
--- @field cmdRejectionNotAdmin string
--- @field cmdRejectionNotAskingUs string
--- @field cmdRejectionNoValidArguments string
--- @field cmdRejectionNoValidSpawnOrBombsite string
--- @field cmdRejectionOnlyCounterTerrorist string
--- @field cmdRejectionOnlyTerrorist string
--- @field cmdRejectionReaperIsActive string
--- @field cmdRejectionSelfInvoked string
--- @field cmdRejectionSenderIsDead string
--- @field cmdRejectionSenderIsNotTeammate string
--- @field cmdRejectionSenderIsOutOfRange string
--- @field cmdSkillSet string
--- @field cmdToggleAiOff string
--- @field editorBeginIntegrityTest string
--- @field editorObjectiveNodeRequired string
--- @field editorReady string
--- @field language string
--- @field logAlert string
--- @field logError string
--- @field logInfo string
--- @field logInternal string
--- @field logOk string
--- @field logWarning string
--- @field manageEconomyEco string
--- @field manageEconomyEcoRush string
--- @field manageEconomyForceBuy string
--- @field manageEconomyFullBuy string
--- @field nodegraphLoaded string
--- @field nodegraphMissingFile string
--- @field nodegraphReady string
--- @field nodegraphSaved string
--- @field pathfinderFailed string
--- @field pathfinderFailedGuessGoal string
--- @field pathfinderFailedKnownGoal string
--- @field pathfinderMovementDisabled string
--- @field pathfinderNewTask string
--- @field pathfinderNoOrigin string
--- @field pathfinderNoOrigin string
--- @field pathfinderObstructed string
--- @field pathfinderReady string
--- @field reaperAccountRestarted string
--- @field reaperIsEnabled string
--- @field reaperIsNotEnabled string
--- @field reaperMissingManifest string
--- @field reaperNewAccount string
--- @field splashBuild string
--- @field splashCopyright string
--- @field splashDevelopedBy string
--- @field splashLanguage string
--- @field splashLicense string
--- @field splashLicenseNeverExpires string
--- @field splashMotto string
--- @field viewFreezePrevention string
--- @field viewNewState string
local Localization = {}

--- @param language string
--- @return Localization
function Localization:new(language)
	local localization = Languages[language]

	if not localization then
		localization = Languages.English
	end

	return Nyx.new(self, localization)
end

return Nyx.class("Localization", Localization):new(Config.language)
--}}}
