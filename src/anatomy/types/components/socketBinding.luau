--!strict
--!optimize 2
--!native

local CallbackSetTypes = require(script.Parent.Parent.Parent.utils.callbackSet)
local AnatomySocketTypes = require(script.Parent.anatomySocket)
local SocketEndpointTypes = require(script.Parent.socketEndpoint)

export type AnatomySocket<TSocketName> = AnatomySocketTypes.AnatomySocket<TSocketName>
export type CallbackSet = CallbackSetTypes.CallbackSet
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint

export type SocketChangedCallback<TSocketName> = (AnatomySocketTypes.AnatomySocket<TSocketName>?) -> ()

export type SocketBinding<TSocketName> = SocketEndpoint & {
	getName: (self: SocketBinding<TSocketName>) -> TSocketName,
	getSocket: (self: SocketBinding<TSocketName>) -> AnatomySocketTypes.AnatomySocket<TSocketName>?,
	bindSocketChanged: (
		self: SocketBinding<TSocketName>,
		callback: SocketChangedCallback<TSocketName>,
		runInitially: boolean?
	) -> () -> (),
	deconstruct: (self: SocketBinding<TSocketName>) -> (),
}

export type SocketBindingImpl<TSocketName> = SocketBinding<TSocketName> & {
	_name: TSocketName,
	_socket: AnatomySocketTypes.AnatomySocket<TSocketName>?,
	_socketChangedCallbacks: CallbackSet,
	_attachmentChangedCallbacks: CallbackSet,
	_socketAttachmentDisconnect: (() -> ())?,
	_source: any?,
	_sourceDisconnect: (() -> ())?,
	_destroyed: boolean,

	_setSocket: (self: SocketBindingImpl<TSocketName>, socket: AnatomySocketTypes.AnatomySocket<TSocketName>?) -> (),
}

return {}
