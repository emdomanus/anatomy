--!strict
--!optimize 2

local CallbackSetTypes =
	require(script.Parent.Parent.Parent.Parent.def.callbackSet.shared.callbackSet)
local SocketSubscriptionTypes =
	require(script.Parent.Parent.Parent.Parent.ports.managers.anatomyHost.shared.socketSubscription)
local AnatomySocketTypes = require(script.Parent.Parent.Parent.anatomySocket.shared.anatomySocket)

export type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type CallbackSet<Args...> = CallbackSetTypes.CallbackSet<Args...>
export type SocketChangedCallback<SocketT> = SocketSubscriptionTypes.SocketChangedCallback<SocketT>
export type SocketSubscription<SocketT> = SocketSubscriptionTypes.SocketSubscription<SocketT>

export type SocketWatcher<SocketT> = {
	read getName: (self: SocketWatcher<SocketT>) -> SocketT,
	read getSocket: (self: SocketWatcher<SocketT>) -> AnatomySocket<SocketT>?,
	read bindSocketChanged: (
		self: SocketWatcher<SocketT>,
		callback: SocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
	read deconstruct: (self: SocketWatcher<SocketT>) -> (),
}
export type SocketWatcherImpl<SocketT> = SocketWatcher<SocketT> & {
	_name: SocketT,
	_socket: AnatomySocket<SocketT>?,
	_socketChangedCallbacks: CallbackSet<AnatomySocket<SocketT>?>,
	_sourceDisconnect: (() -> ())?,
	_destroyed: boolean,
	_setSocket: (self: SocketWatcherImpl<SocketT>, socket: AnatomySocket<SocketT>?) -> (),
}
return {}
