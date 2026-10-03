--!strict
--!optimize 2

local SocketEndpointLifecycleTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.socketEndpoint.shared.socketEndpointLifecycle
)
local CallbackSetTypes =
	require(script.Parent.Parent.Parent.Parent.def.callbackSet.shared.callbackSet)
local SocketSubscriptionTypes =
	require(script.Parent.Parent.Parent.Parent.ports.managers.anatomyHost.shared.socketSubscription)
local AnatomySocketTypes = require(script.Parent.Parent.Parent.anatomySocket.shared.anatomySocket)
local SocketEndpointTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.socketEndpoint.shared.socketEndpoint
)

type SocketEndpointLifecycle = SocketEndpointLifecycleTypes.SocketEndpointLifecycle

export type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type CallbackSet<Args...> = CallbackSetTypes.CallbackSet<Args...>
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint

export type SocketChangedCallback<SocketT> = SocketSubscriptionTypes.SocketChangedCallback<SocketT>
export type SocketBindingSource<SocketT> = SocketSubscriptionTypes.SocketSubscription<SocketT>

export type SocketBinding<SocketT> = SocketEndpoint & SocketEndpointLifecycle & {
	read getName: (self: SocketBinding<SocketT>) -> SocketT,
	read getSocket: (self: SocketBinding<SocketT>) -> AnatomySocket<SocketT>?,
	read bindSocketChanged: (
		self: SocketBinding<SocketT>,
		callback: SocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
}

export type SocketBindingImpl<SocketT> = SocketBinding<SocketT> & {
	_name: SocketT,
	_socket: AnatomySocket<SocketT>?,
	_socketChangedCallbacks: CallbackSet<AnatomySocket<SocketT>?>,
	_attachmentChangedCallbacks: CallbackSet<Attachment?>,
	_socketAttachmentDisconnect: (() -> ())?,
	_source: SocketBindingSource<SocketT>?,
	_sourceDisconnect: (() -> ())?,
	_destroyed: boolean,

	_setSocket: (self: SocketBindingImpl<SocketT>, socket: AnatomySocket<SocketT>?) -> (),
}

return {}
