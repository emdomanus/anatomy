--!strict
--!optimize 2

export type SocketMountOptions = {
	name: string?,
	rigidName: string?,
	parent: Instance?,
	enabled: boolean?,
}

export type SocketMount = {
	read getName: (self: SocketMount) -> string?,
	read getFromAttachment: (self: SocketMount) -> Attachment?,
	read getToAttachment: (self: SocketMount) -> Attachment?,
	read getConstraint: (self: SocketMount) -> RigidConstraint?,
	read isConnected: (self: SocketMount) -> boolean,
	read setAttachments: (self: SocketMount, from: Attachment?, to: Attachment?) -> (),
	read setEnabled: (self: SocketMount, enabled: boolean) -> (),
	read setParent: (self: SocketMount, parent: Instance?) -> (),
	read deconstruct: (self: SocketMount) -> (),
}

export type SocketMountImpl = SocketMount & {
	_name: string?,
	_rigid: RigidConstraint?,
	_enabled: boolean,
}

return {}
