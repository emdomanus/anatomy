--!strict
--!optimize 2

local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)

type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
export type SocketChangedCallback<SocketT> = (AnatomySocket<SocketT>?) -> ()
export type SocketSubscription<SocketT> = {
	read bindSocket: (
		self: SocketSubscription<SocketT>,
		name: SocketT,
		callback: SocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
}
return {}
