--!strict
--!optimize 2

local SocketEndpointLifecycleTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.socketEndpoint.shared.socketEndpointLifecycle
)
local SocketEndpointTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.socketEndpoint.shared.socketEndpoint
)

type SocketEndpointLifecycle = SocketEndpointLifecycleTypes.SocketEndpointLifecycle

export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint

export type SocketMountOptions = {
	name: string?,
	rigidName: string?,
	parent: Instance?,
	enabled: boolean?,
}

export type SocketMount = {
	read getName: (self: SocketMount) -> string?,
	read getFromAttachment: (self: SocketMount) -> MountAttachment?,
	read getToAttachment: (self: SocketMount) -> MountAttachment?,
	read getConstraint: (self: SocketMount) -> RigidConstraint?,
	read isConnected: (self: SocketMount) -> boolean,
	read setEnabled: (self: SocketMount, enabled: boolean) -> (),
	read refresh: (self: SocketMount) -> (),
	read deconstruct: (self: SocketMount) -> (),
}

export type SocketMountImpl = SocketMount & {
	_fromOwned: SocketEndpointLifecycle?,
	_toOwned: SocketEndpointLifecycle?,
	_name: string?,
	_fromEndpoint: SocketEndpoint?,
	_toEndpoint: SocketEndpoint?,
	_fromAttachment: MountAttachment?,
	_toAttachment: MountAttachment?,
	_rigid: RigidConstraint?,
	_fromAttachmentDisconnect: (() -> ())?,
	_toAttachmentDisconnect: (() -> ())?,
	_options: SocketMountOptions,
	_enabled: boolean,
	_destroyed: boolean,

	_setFromAttachment: (self: SocketMountImpl, attachment: MountAttachment?) -> (),
	_setToAttachment: (self: SocketMountImpl, attachment: MountAttachment?) -> (),
	_reconcileConstraint: (self: SocketMountImpl) -> (),
}

return {}
