--!strict
--!optimize 2

local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes = require(
	script.Parent.Parent.Parent.Parent.Parent.components.anatomyTaggedElement.shared.anatomyTaggedElement
)

type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>

export type SocketChangedCallback<SocketT> = (AnatomySocket<SocketT>?) -> ()
export type SourceSocketChangedCallback<SocketT> = (SocketT, AnatomySocket<SocketT>?) -> ()
export type TaggedCallback<TagT> = (AnatomyTaggedElement<TagT>) -> ()
export type TaggedChangedCallback<TagT> = (AnatomyTaggedElement<TagT>?) -> ()

export type AnatomySource<SocketT, TagT> = {
	read getSocket: (self: AnatomySource<SocketT, TagT>, name: SocketT) -> AnatomySocket<SocketT>?,
	read getTagged: (
		self: AnatomySource<SocketT, TagT>,
		prefix: string
	) -> { AnatomyTaggedElement<TagT> },
	read getTopTagged: (
		self: AnatomySource<SocketT, TagT>,
		prefix: string
	) -> AnatomyTaggedElement<TagT>?,
	read bindTopTaggedChanged: (
		self: AnatomySource<SocketT, TagT>,
		prefix: string,
		callback: TaggedChangedCallback<TagT>,
		runInitially: boolean?
	) -> () -> (),
	read bindToSocket: (
		self: AnatomySource<SocketT, TagT>,
		name: SocketT,
		callback: SocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
	read bindSocketChanged: (
		self: AnatomySource<SocketT, TagT>,
		callback: SourceSocketChangedCallback<SocketT>,
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
