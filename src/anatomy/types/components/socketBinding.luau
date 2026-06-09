--!strict
--!optimize 2
--!native

local CallbackSetTypes = require(script.Parent.Parent.Parent.utils.callbackSet)
local AnatomySocketTypes = require(script.Parent.anatomySocket)
local SocketEndpointTypes = require(script.Parent.socketEndpoint)

export type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
export type CallbackSet = CallbackSetTypes.CallbackSet
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint

export type SocketChangedCallback<SocketT> = (AnatomySocketTypes.AnatomySocket<SocketT>?) -> ()

export type SocketBinding<SocketT> = SocketEndpoint & {
	getName: (self: SocketBinding<SocketT>) -> SocketT,
	getSocket: (self: SocketBinding<SocketT>) -> AnatomySocketTypes.AnatomySocket<SocketT>?,
	bindSocketChanged: (
		self: SocketBinding<SocketT>,
		callback: SocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
	deconstruct: (self: SocketBinding<SocketT>) -> (),
}

export type SocketBindingImpl<SocketT> = SocketBinding<SocketT> & {
	_name: SocketT,
	_socket: AnatomySocketTypes.AnatomySocket<SocketT>?,
	_socketChangedCallbacks: CallbackSet,
	_attachmentChangedCallbacks: CallbackSet,
	_socketAttachmentDisconnect: (() -> ())?,
	_source: any?,
	_sourceDisconnect: (() -> ())?,
	_destroyed: boolean,

	_setSocket: (self: SocketBindingImpl<SocketT>, socket: AnatomySocketTypes.AnatomySocket<SocketT>?) -> (),
}

return {}
