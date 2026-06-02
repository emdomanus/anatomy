--!strict
--!optimize 2
--!native

local HookModule = require(script.Parent.Parent.Parent.Parent.externalPackages.hook)
local AnatomySocketTypes = require(script.Parent.anatomySocket)
local SocketEndpointTypes = require(script.Parent.socketEndpoint)
local DefTypes = require(script.Parent.Parent.def)

type Hook<T...> = HookModule.Hook<T...>

export type AnatomySocket = AnatomySocketTypes.AnatomySocket
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type SocketName = DefTypes.SocketName

export type SocketChangedCallback = (AnatomySocket?) -> ()

export type SocketBinding = SocketEndpoint & {
	getName: (self: SocketBinding) -> SocketName,
	getSocket: (self: SocketBinding) -> AnatomySocket?,
	bindSocketChanged: (
		self: SocketBinding,
		callback: SocketChangedCallback,
		runInitially: boolean?
	) -> number,
	unbindSocketChanged: (self: SocketBinding, hookId: number) -> boolean,
	deconstruct: (self: SocketBinding) -> (),
}

export type SocketBindingImpl = SocketBinding & {
	_name: SocketName,
	_socket: AnatomySocket?,
	_socketChangedHook: Hook<AnatomySocket?>,
	_attachmentChangedHook: Hook<MountAttachment?>,
	_socketAttachmentBindId: number?,
	_source: any?,
	_sourceBindId: number?,
	_destroyed: boolean,

	_setSocket: (self: SocketBindingImpl, socket: AnatomySocket?) -> (),
}

return {}
