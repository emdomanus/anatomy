--!strict
--!optimize 2
--!native

local SocketEndpointTypes = require(script.Parent.socketEndpoint)

export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint

export type SocketMountOptions = {
	name: string?,
	rigidName: string?,
	parent: Instance?,
	enabled: boolean?,
}

export type SocketMount = {
	getName: (self: SocketMount) -> string?,
	getFromAttachment: (self: SocketMount) -> MountAttachment?,
	getToAttachment: (self: SocketMount) -> MountAttachment?,
	getConstraint: (self: SocketMount) -> RigidConstraint?,
	isConnected: (self: SocketMount) -> boolean,
	setEnabled: (self: SocketMount, enabled: boolean) -> (),
	refresh: (self: SocketMount) -> (),
	deconstruct: (self: SocketMount) -> (),
}

export type SocketMountImpl = SocketMount & {
	_name: string?,
	_fromEndpoint: SocketEndpoint,
	_toEndpoint: SocketEndpoint,
	_fromAttachment: MountAttachment?,
	_toAttachment: MountAttachment?,
	_rigid: RigidConstraint?,
	_fromAttachmentBindId: number?,
	_toAttachmentBindId: number?,
	_options: SocketMountOptions,
	_enabled: boolean,
	_destroyed: boolean,

	_setFromAttachment: (self: SocketMountImpl, attachment: MountAttachment?) -> (),
	_setToAttachment: (self: SocketMountImpl, attachment: MountAttachment?) -> (),
	_reconcileConstraint: (self: SocketMountImpl) -> (),
}

return {}
