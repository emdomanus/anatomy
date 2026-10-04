--!strict
local SourceTypes =
	require(script.Parent.Parent.Parent.Parent.ports.anatomySource.shared.anatomySource)
local SocketTypes =
	require(script.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)
local TaggedTypes = require(
	script.Parent.Parent.Parent.Parent.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local MountTypes =
	require(script.Parent.Parent.Parent.Parent.components.socketMount.shared.socketMount)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)
export type AnatomySource<SocketT, TagT> = SourceTypes.AnatomySource<SocketT, TagT>
type Socket<SocketT> = SocketTypes.AnatomySocket<SocketT>
type Element<TagT> = TaggedTypes.AnatomyTaggedElement<TagT>
export type TaggedSelection<SocketT, TagT> = {
	current: Element<TagT>?,
	callbacks: { [SourceTypes.TaggedChangedCallback<TagT>]: true },
	disconnects: { [AnatomySource<SocketT, TagT>]: () -> () },
}
export type AnatomyHostOptions<SocketT, TagT> = {
	read socketNameGuard: AnatomyTypes.NameGuard<SocketT>,
	read tagGuard: AnatomyTypes.NameGuard<TagT>,
}
export type Registration<SocketT, TagT> = {
	priority: number,
	ordinal: number,
	socketsByName: { [SocketT]: Socket<SocketT> },
	taggedElements: { [Element<TagT>]: true },
	disconnectSocketChanged: (() -> ())?,
	disconnectTaggedAdded: (() -> ())?,
	disconnectTaggedRemoved: (() -> ())?,
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
	_taggedElementCounts: { [Element<TagT>]: number },
	_socketChangedCallbacks: { [(SocketT, Socket<SocketT>?) -> ()]: true },
	_taggedAddedCallbacks: { [SourceTypes.TaggedCallback<TagT>]: true },
	_taggedRemovedCallbacks: { [SourceTypes.TaggedCallback<TagT>]: true },
	_socketCallbacksByName: { [SocketT]: { [(Socket<SocketT>?) -> ()]: true } },
	_taggedSelections: { [string]: TaggedSelection<SocketT, TagT> },
	_socketMounts: { [MountTypes.SocketMount]: true },
	_nextOrdinal: number,
	_destroyed: boolean,
	_refreshTopTagged: (self: AnatomyHostImpl<SocketT, TagT>, prefix: string) -> (),
	_refreshSocket: (self: AnatomyHostImpl<SocketT, TagT>, name: SocketT) -> (),
}
return {}
