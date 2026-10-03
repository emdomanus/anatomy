--!strict
--!optimize 2

local SocketEndpointTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.socketEndpoint.shared.socketEndpoint
)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)
local CallbackSetTypes =
	require(script.Parent.Parent.Parent.Parent.def.callbackSet.shared.callbackSet)

type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
type AnatomyPath = AnatomyTypes.AnatomyPath
type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
type CallbackSet<Args...> = CallbackSetTypes.CallbackSet<Args...>
export type AnatomySocket<SocketT> = SocketEndpoint & {
	read getName: (self: AnatomySocket<SocketT>) -> SocketT,
	read getPath: (self: AnatomySocket<SocketT>) -> AnatomyPath,
	read getMetadata: (self: AnatomySocket<SocketT>) -> DescriptorMetadata?,
}
export type AnatomySocketOwned<SocketT> = AnatomySocket<SocketT> & {
	read deconstruct: (self: AnatomySocketOwned<SocketT>) -> (),
}
export type AnatomySocketImpl<SocketT> = AnatomySocketOwned<SocketT> & {
	_name: SocketT,
	_path: AnatomyPath,
	_attachment: Attachment?,
	_metadata: DescriptorMetadata?,
	_attachmentChangedCallbacks: CallbackSet<Attachment?>,
	_destroyed: boolean,
}
return {}
