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

export type AnatomySocket<TSocketName> = SocketEndpoint & {
	getName: (self: AnatomySocket<TSocketName>) -> TSocketName,
	getPath: (self: AnatomySocket<TSocketName>) -> AnatomyPath,
	getMetadata: (self: AnatomySocket<TSocketName>) -> DescriptorMetadata?,
	deconstruct: (self: AnatomySocket<TSocketName>) -> (),
}

export type AnatomySocketImpl<TSocketName> = AnatomySocket<TSocketName> & {
	_owner: any,
	_name: TSocketName,
	_path: AnatomyPath,
	_attachment: MountAttachment?,
	_metadata: DescriptorMetadata?,
	_attachmentChangedCallbacks: CallbackSet,
	_destroyed: boolean,

	_setAttachment: (self: AnatomySocketImpl<TSocketName>, attachment: MountAttachment?) -> (),
}

return {}
