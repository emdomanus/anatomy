--!strict
--!optimize 2

export type SocketEndpointLifecycle = {
	read deconstruct: (self: SocketEndpointLifecycle) -> (),
}
return {}
