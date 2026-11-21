--!strict
--!optimize 2
local LuauUtils = require("../../../../../luau_packages/luauUtils")
local AnatomySourceTypes = require("../../../def/anatomy/anatomySource/public")
local AnatomyHostTypes = require("./public")

type AnatomyHostOwned = AnatomyHostTypes.AnatomyHostOwned
type AnatomySource = AnatomySourceTypes.AnatomySource
type CallbackList<Args...> = LuauUtils.CallbackList<Args...>

export type AnatomyHostImpl = AnatomyHostOwned & {
	-- The pushed sources, lowest precedence first: by priority, then by push order. The three arrays
	-- after it are parallel to it: `[i]` belongs to `_anatomySources[i]`.
	_anatomySources: { AnatomySource },
	_priorities: { number },
	-- What `onAnySocketChanged` and `onAnyTopTaggedChanged` returned when this host subscribed to
	-- the source at `push`.
	_releaseAnySocketChanged: { () -> () },
	_releaseAnyTopTaggedChanged: { () -> () },

	-- The same two tables as the capability's `socketNames` and `taggedPrefixes`, under a type this
	-- host may append through. They only grow. The two sets hold the same names, so each is listed
	-- once.
	_socketNames: { string },
	_taggedPrefixes: { string },
	_knownSocketNames: { [string]: true },
	_knownTaggedPrefixes: { [string]: true },

	-- Socket name -> `getSocket`'s two results; prefix -> `getTopTagged`'s two results.
	_winnerElementIndexes: { [string]: number },
	_winnerInstances: { [string]: AnatomySource },
	_topTaggedElementIndexes: { [string]: number },
	_topTaggedInstances: { [string]: AnatomySource },
	-- The instance last reported for a name, to this host's subscribers and to the hosts it is
	-- pushed to. It differs from the winner only between the two passes of an operation, and after
	-- a callback raised.
	_reportedWinnerInstances: { [string]: AnatomySource },
	_reportedTopTaggedInstances: { [string]: AnatomySource },

	-- The hosts this one is pushed to: each added one function at its `push`. Created by the first.
	_anySocketChangedList: CallbackList<string>?,
	_anyTopTaggedChangedList: CallbackList<string>?,
	-- Per name, created by that name's first subscriber and kept until `deconstruct`.
	_socketChangedLists: { [string]: CallbackList<number?, AnatomySource?> },
	_topTaggedChangedLists: { [string]: CallbackList<number?, AnatomySource?> },
	-- Per socket name: one entry per `onSocketAmongOthersChanged` subscriber, fired for every name
	-- an operation visits, changed or not.
	_socketAmongOthersLists: { [string]: CallbackList<> },

	-- The two functions this host gives every source it pushes, created once in `new`.
	_handleSourceSocketChanged: (socketName: string) -> (),
	_handleSourceTopTaggedChanged: (prefix: string) -> (),

	_deconstructed: boolean,
}

return {}
