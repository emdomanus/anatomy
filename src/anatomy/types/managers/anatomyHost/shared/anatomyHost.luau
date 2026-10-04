--!strict
--!optimize 2

local AnatomySourceTypes =
	require(script.Parent.Parent.Parent.Parent.ports.components.anatomySource.shared.anatomySource)
local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes = require(
	script.Parent.Parent.Parent.Parent.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local SocketMountTypes =
	require(script.Parent.Parent.Parent.Parent.components.socketMount.shared.socketMount)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)
type AnatomySource<SocketT, TagT> = AnatomySourceTypes.AnatomySource<SocketT, TagT>
type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
type NameGuard<TName> = AnatomyTypes.NameGuard<TName>
type TaggedCallback<TagT> = AnatomySourceTypes.TaggedCallback<TagT>
type TaggedChangedCallback<TagT> = AnatomySourceTypes.TaggedChangedCallback<TagT>
type SocketMount = SocketMountTypes.SocketMount
type SocketMountOptions = SocketMountTypes.SocketMountOptions

export type AnatomyHostTaggedSelection<SocketT, TagT> = {
	current: AnatomyTaggedElement<TagT>?,
	callbacks: { [TaggedChangedCallback<TagT>]: true },
	disconnects: { [AnatomySource<SocketT, TagT>]: () -> () },
}
export type AnatomyHostOptions<SocketT, TagT> = {
	read socketNameGuard: NameGuard<SocketT>,
	read tagGuard: NameGuard<TagT>,
}
export type AnatomyHostRegistration<SocketT, TagT> = {
	priority: number,
	ordinal: number,
	socketsByName: { [SocketT]: AnatomySocket<SocketT> },
	taggedElements: { [AnatomyTaggedElement<TagT>]: true },
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
		options: SocketMountOptions?
	) -> SocketMount,
	read deconstruct: (self: AnatomyHost<SocketT, TagT>) -> (),
}
export type AnatomyHostImpl<SocketT, TagT> = AnatomyHost<SocketT, TagT> & {
	_socketNameGuard: NameGuard<SocketT>,
	_tagGuard: NameGuard<TagT>,
	_registrations: { [AnatomySource<SocketT, TagT>]: AnatomyHostRegistration<SocketT, TagT> },
	_sources: { AnatomySource<SocketT, TagT> },
	_resolvedSockets: { [SocketT]: AnatomySocket<SocketT> },
	_taggedElementCounts: { [AnatomyTaggedElement<TagT>]: number },
	_socketChangedCallbacks: { [(SocketT, AnatomySocket<SocketT>?) -> ()]: true },
	_taggedAddedCallbacks: { [TaggedCallback<TagT>]: true },
	_taggedRemovedCallbacks: { [TaggedCallback<TagT>]: true },
	_socketCallbacksByName: { [SocketT]: { [(AnatomySocket<SocketT>?) -> ()]: true } },
	_taggedSelections: { [string]: AnatomyHostTaggedSelection<SocketT, TagT> },
	_socketMounts: { [SocketMount]: true },
	_nextOrdinal: number,
	_destroyed: boolean,
	_refreshTopTagged: (self: AnatomyHostImpl<SocketT, TagT>, prefix: string) -> (),
	_refreshSocket: (self: AnatomyHostImpl<SocketT, TagT>, name: SocketT) -> (),
}
return {}
