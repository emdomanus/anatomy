--!strict
--!optimize 2
-- What a host composes. Two objects implement it, the anatomyInstance and the anatomyHost, so it has
-- no single implementer to belong to and is a def leaf.
--
-- A socket and a tagged element are each an element index with "the instance": the AnatomySource
-- that `anatomyInstance.new` built and whose template holds that index. It is never a host. A def
-- leaf cannot name AnatomyInstance, which is declared above it, so these signatures say
-- AnatomySource.
export type AnatomySource = {
	-- `getSocket` returns nil for every name not listed, and `getTopTagged` for every prefix not
	-- listed. An instance lists exactly what its template has. A host lists every name a source of
	-- it has supplied since it was built, so a listed name can currently have no supplier.
	read socketNames: { read [number]: string },
	read taggedPrefixes: { read [number]: string },

	-- The element index of the socket and the instance that supplies it, or nil, nil.
	read getSocket: (self: AnatomySource, socketName: string) -> (number?, AnatomySource?),
	-- The element index of the top element under `prefix` and the instance it belongs to, or nil,
	-- nil. An instance's top element is its last one under the prefix in element-index order.
	read getTopTagged: (self: AnatomySource, prefix: string) -> (number?, AnatomySource?),
	-- Appends every element under `prefix`: its element index to `intoElementIndexes` and its
	-- instance, at the same position, to `intoAnatomyInstances`. Lowest precedence first, each
	-- instance's elements in element-index order; the last pair is what `getTopTagged` returns.
	read getTagged: (
		self: AnatomySource,
		prefix: string,
		intoElementIndexes: { number },
		intoAnatomyInstances: { AnatomySource }
	) -> (),

	-- Calls `callback(socketName)` each time `getSocket(socketName)` starts returning something
	-- else, and `callback(prefix)` likewise for `getTopTagged`. Returns the function that
	-- unsubscribes. An instance never changes: it keeps nothing and returns a function that does
	-- nothing.
	read onAnySocketChanged: (
		self: AnatomySource,
		callback: (socketName: string) -> ()
	) -> () -> (),
	read onAnyTopTaggedChanged: (
		self: AnatomySource,
		callback: (prefix: string) -> ()
	) -> () -> (),

	-- True when `anatomySource` is this source, or is reachable from it through pushed sources.
	-- An instance has no sources, so it answers `anatomySource == self`.
	read containsSource: (self: AnatomySource, anatomySource: AnatomySource) -> boolean,
}

return {}
