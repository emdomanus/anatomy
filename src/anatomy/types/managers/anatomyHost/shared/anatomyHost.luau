--!strict
local SourceTypes =
	require(script.Parent.Parent.Parent.Parent.ports.anatomySource.shared.anatomySource)
local SocketTypes =
	require(script.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)
local TaggedTypes = require(
	script.Parent.Parent.Parent.Parent.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local WatcherTypes =
	require(script.Parent.Parent.Parent.Parent.components.socketWatcher.shared.socketWatcher)
local MountTypes =
	require(script.Parent.Parent.Parent.Parent.components.socketMount.shared.socketMount)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)
export type AnatomySource<SocketT, TagT> = SourceTypes.AnatomySource<SocketT, TagT>
type Socket<SocketT> = SocketTypes.AnatomySocket<SocketT>
type Element<TagT> = TaggedTypes.AnatomyTaggedElement<TagT>
export type AnatomyHostOptions<SocketT, TagT> = {
	read socketNameGuard: AnatomyTypes.NameGuard<SocketT>,
	read tagGuard: AnatomyTypes.NameGuard<TagT>,
}
export type Registration<SocketT, TagT> = {
	priority: number,
	ordinal: number,
	sockets: { [SocketT]: Socket<SocketT> },
	tags: { [Element<TagT>]: true },
	disconnectSockets: (() -> ())?,
	disconnectAdded: (() -> ())?,
	disconnectRemoved: (() -> ())?,
	active: boolean,
}
export type AnatomyHost<SocketT, TagT> = AnatomySource<SocketT, TagT> & {
	read push: (
		self: AnatomyHost<SocketT, TagT>,
		source: AnatomySource<SocketT, TagT>,
		priority: number?
	) -> (),
	read remove: (
		self: AnatomyHost<SocketT, TagT>,
		source: AnatomySource<SocketT, TagT>
	) -> boolean,
	read setPriority: (
		self: AnatomyHost<SocketT, TagT>,
		source: AnatomySource<SocketT, TagT>,
		priority: number
	) -> (),
	read clear: (self: AnatomyHost<SocketT, TagT>) -> (),
	read watchSocket: (
		self: AnatomyHost<SocketT, TagT>,
		name: SocketT
	) -> WatcherTypes.SocketWatcher<SocketT>,
	read mount: (
		self: AnatomyHost<SocketT, TagT>,
		from: Attachment?,
		to: Attachment?,
		options: MountTypes.SocketMountOptions?
	) -> MountTypes.SocketMount,
	read deconstruct: (self: AnatomyHost<SocketT, TagT>) -> (),
}
export type AnatomyHostImpl<SocketT, TagT> = AnatomyHost<SocketT, TagT> & {
	_socketNameGuard: AnatomyTypes.NameGuard<SocketT>,
	_tagGuard: AnatomyTypes.NameGuard<TagT>,
	_registrations: { [AnatomySource<SocketT, TagT>]: Registration<SocketT, TagT> },
	_sources: { AnatomySource<SocketT, TagT> },
	_resolvedSockets: { [SocketT]: Socket<SocketT> },
	_tagCounts: { [Element<TagT>]: number },
	_socketCallbacks: { [(SocketT, Socket<SocketT>?) -> ()]: true },
	_addedCallbacks: { [SourceTypes.TaggedCallback<TagT>]: true },
	_removedCallbacks: { [SourceTypes.TaggedCallback<TagT>]: true },
	_watchers: { [WatcherTypes.SocketWatcher<SocketT>]: true },
	_mounts: { [MountTypes.SocketMount]: true },
	_nextOrdinal: number,
	_destroyed: boolean,
	_refreshSocket: (self: AnatomyHostImpl<SocketT, TagT>, name: SocketT) -> (),
}
return {}
