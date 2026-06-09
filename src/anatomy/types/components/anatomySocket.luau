--!strict
--!optimize 2
--!native

local CallbackSetTypes = require(script.Parent.Parent.Parent.utils.callbackSet)
local SocketEndpointTypes = require(script.Parent.socketEndpoint)
local DefTypes = require(script.Parent.Parent.def)

export type AnatomyPath = DefTypes.AnatomyPath
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type CallbackSet = CallbackSetTypes.CallbackSet
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback

export type AnatomySocket<SocketT> = SocketEndpoint & {
	getName: (self: AnatomySocket<SocketT>) -> SocketT,
	getPath: (self: AnatomySocket<SocketT>) -> AnatomyPath,
	getMetadata: (self: AnatomySocket<SocketT>) -> DescriptorMetadata?,
	deconstruct: (self: AnatomySocket<SocketT>) -> (),
}

export type AnatomySocketImpl<SocketT> = AnatomySocket<SocketT> & {
	_owner: any,
	_name: SocketT,
	_path: AnatomyPath,
	_attachment: MountAttachment?,
	_metadata: DescriptorMetadata?,
	_attachmentChangedCallbacks: CallbackSet,
	_destroyed: boolean,

	_setAttachment: (self: AnatomySocketImpl<SocketT>, attachment: MountAttachment?) -> (),
}

return {}
