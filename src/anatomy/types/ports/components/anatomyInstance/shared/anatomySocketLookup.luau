--!strict
--!optimize 2

local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)

type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
export type AnatomySocketLookup<SocketT> = {
	read getSocket: (self: AnatomySocketLookup<SocketT>, name: SocketT) -> AnatomySocket<SocketT>?,
}
return {}
