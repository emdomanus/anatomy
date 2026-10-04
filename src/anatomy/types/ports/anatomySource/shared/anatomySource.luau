--!strict
local SocketTypes =
	require(script.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)
local TaggedTypes = require(
	script.Parent.Parent.Parent.Parent.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local SubscriptionTypes =
	require(script.Parent.Parent.Parent.managers.anatomyHost.shared.socketSubscription)
export type TaggedCallback<TagT> = (TaggedTypes.AnatomyTaggedElement<TagT>) -> ()
export type TaggedChangedCallback<TagT> = (TaggedTypes.AnatomyTaggedElement<TagT>?) -> ()
export type AnatomySource<SocketT, TagT> = SubscriptionTypes.SocketSubscription<SocketT> & {
	read getSocket: (
		self: AnatomySource<SocketT, TagT>,
		name: SocketT
	) -> SocketTypes.AnatomySocket<SocketT>?,
	read getTagged: (
		self: AnatomySource<SocketT, TagT>,
		prefix: string
	) -> { TaggedTypes.AnatomyTaggedElement<TagT> },
	read getTopTagged: (
		self: AnatomySource<SocketT, TagT>,
		prefix: string
	) -> TaggedTypes.AnatomyTaggedElement<TagT>?,
	read bindTopTaggedChanged: (
		self: AnatomySource<SocketT, TagT>,
		prefix: string,
		callback: TaggedChangedCallback<TagT>,
		runInitially: boolean?
	) -> () -> (),
	read bindToSocket: (
		self: AnatomySource<SocketT, TagT>,
		name: SocketT,
		callback: SubscriptionTypes.SocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
	read bindTaggedAdded: (
		self: AnatomySource<SocketT, TagT>,
		callback: TaggedCallback<TagT>,
		runInitially: boolean?
	) -> () -> (),
	read bindTaggedRemoved: (
		self: AnatomySource<SocketT, TagT>,
		callback: TaggedCallback<TagT>
	) -> () -> (),
}
return {}
