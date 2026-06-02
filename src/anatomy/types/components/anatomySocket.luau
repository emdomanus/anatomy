--!strict
--!optimize 2
--!native

local HookModule = require(script.Parent.Parent.Parent.Parent.externalPackages.hook)
local SocketEndpointTypes = require(script.Parent.socketEndpoint)
local DefTypes = require(script.Parent.Parent.def)

type Hook<T...> = HookModule.Hook<T...>

export type AnatomyPath = DefTypes.AnatomyPath
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type SocketName = DefTypes.SocketName
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback

export type AnatomySocket = SocketEndpoint & {
	getName: (self: AnatomySocket) -> SocketName,
	getPath: (self: AnatomySocket) -> AnatomyPath,
	getMetadata: (self: AnatomySocket) -> DescriptorMetadata?,
	deconstruct: (self: AnatomySocket) -> (),
}

export type AnatomySocketImpl = AnatomySocket & {
	_owner: any,
	_name: SocketName,
	_path: AnatomyPath,
	_attachment: MountAttachment?,
	_metadata: DescriptorMetadata?,
	_attachmentChangedHook: Hook<MountAttachment?>,
	_destroyed: boolean,

	_setAttachment: (self: AnatomySocketImpl, attachment: MountAttachment?) -> (),
}

return {}
