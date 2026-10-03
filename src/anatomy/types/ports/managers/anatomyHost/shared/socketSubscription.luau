--!strict
--!optimize 2

local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)

local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)

export type LayerId = AnatomyTypes.LayerId
type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
export type SocketChangedCallback<SocketT> = (AnatomySocket<SocketT>?) -> ()
export type SocketSubscription<SocketT> = {
	read bindSocket: (
		self: SocketSubscription<SocketT>,
		name: SocketT,
		callback: SocketChangedCallback<SocketT>,
		runInitially: boolean?,
		layerId: LayerId?,
		includeOverrides: boolean?
	) -> () -> (),
}
return {}
