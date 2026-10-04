--!strict
local SocketTypes =
	require(script.Parent.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)
export type SocketChangedCallback<SocketT> = (SocketTypes.AnatomySocket<SocketT>?) -> ()
export type SourceSocketChangedCallback<SocketT> = (
	SocketT,
	SocketTypes.AnatomySocket<SocketT>?
) -> ()
export type SocketSubscription<SocketT> = {
	read bindSocketChanged: (
		self: SocketSubscription<SocketT>,
		callback: SourceSocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
}
return {}
