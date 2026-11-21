--!strict
--!optimize 2
local AnatomySourceTypes = require("../../../def/anatomy/anatomySource/public")

type AnatomySource = AnatomySourceTypes.AnatomySource

-- What a consumer of one composed anatomy holds: the capability, and three subscriptions by name.
-- Every result is an element index with the instance that supplied it, or nil, nil.
export type AnatomyHost = AnatomySource & {
	-- Calls `callback` with `getSocket(socketName)`'s two results each time they differ from what
	-- this host last reported for that name. With `initially`, also calls it once with the current
	-- results before returning. Returns the function that unsubscribes.
	read onSocketChanged: (
		self: AnatomyHost,
		socketName: string,
		callback: (elementIndex: number?, anatomyInstance: AnatomySource?) -> (),
		initially: boolean?
	) -> () -> (),
	-- The same for `getTopTagged(prefix)`.
	read onTopTaggedChanged: (
		self: AnatomyHost,
		prefix: string,
		callback: (elementIndex: number?, anatomyInstance: AnatomySource?) -> (),
		initially: boolean?
	) -> () -> (),
	-- The same as `onSocketChanged`, for the socket as the highest-precedence source of this host
	-- other than `excluded` supplies it. `excluded` is compared with the sources pushed directly to
	-- this host; a source that is not pushed to it excludes nothing, and that is not an error.
	-- This is what a consumer follows when the thing it attaches may supply the socket itself.
	read onSocketAmongOthersChanged: (
		self: AnatomyHost,
		socketName: string,
		excluded: AnatomySource,
		callback: (elementIndex: number?, anatomyInstance: AnatomySource?) -> (),
		initially: boolean?
	) -> () -> (),
}

-- What the owner of the host holds: `anatomyHost.new` returns it.
export type AnatomyHostOwned = AnatomyHost & {
	-- Adds the source above every pushed source of the same or a lower priority. Raises, before
	-- anything changes, when the source is already pushed to this host, or when
	-- `anatomySource:containsSource(self)` is true: the source is this host or contains it.
	read push: (self: AnatomyHostOwned, anatomySource: AnatomySource, priority: number) -> (),
	-- Does nothing when the source is not pushed to this host.
	read remove: (self: AnatomyHostOwned, anatomySource: AnatomySource) -> (),
	-- Moves the source as if removed and pushed at `priority`, in one step with one set of
	-- reports. Raises when the source is not pushed to this host. An unchanged priority does
	-- nothing.
	read setPriority: (
		self: AnatomyHostOwned,
		anatomySource: AnatomySource,
		priority: number
	) -> (),
	-- Removes every source, so every subscriber and every host this one is pushed to is told nil,
	-- then drops every subscriber. Afterwards the queries return nil and append nothing, `push` and
	-- the subscriptions raise, and a release obtained earlier still works. A second call does
	-- nothing.
	read deconstruct: (self: AnatomyHostOwned) -> (),
}

return {}
