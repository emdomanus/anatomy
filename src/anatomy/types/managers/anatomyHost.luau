--!strict
--!optimize 2
--!native

local HookModule = require(script.Parent.Parent.Parent.Parent.externalPackages.hook)
local AnatomyInstanceTypes = require(script.Parent.Parent.components.anatomyInstance)
local AnatomySocketTypes = require(script.Parent.Parent.components.anatomySocket)
local SocketBindingTypes = require(script.Parent.Parent.components.socketBinding)
local SocketEndpointTypes = require(script.Parent.Parent.components.socketEndpoint)
local SocketMountTypes = require(script.Parent.Parent.components.socketMount)
local DefTypes = require(script.Parent.Parent.def)

type Hook<T...> = HookModule.Hook<T...>

export type AnatomyCategory = DefTypes.AnatomyCategory
export type AnatomyInstance = AnatomyInstanceTypes.AnatomyInstance
export type AnatomySocket = AnatomySocketTypes.AnatomySocket
export type LayerId = DefTypes.LayerId
export type SocketBinding = SocketBindingTypes.SocketBinding
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions
export type SocketName = DefTypes.SocketName

export type SocketQueryHookEntry = {
	name: SocketName,
	query: AnatomyHostSocketQuery?,
	hook: Hook<AnatomySocket?>,
	current: AnatomySocket?,
}

export type AnatomyHostOptions = {
	id: string?,
}

export type AnatomyHostLayerOptions = {
	id: LayerId?,
	priority: number?,
	category: AnatomyCategory?,
	allowSocketOverrides: boolean?,
}

export type AnatomyHostLayer = {
	id: LayerId,
	getInstance: (self: AnatomyHostLayer) -> AnatomyInstance,
	getPriority: (self: AnatomyHostLayer) -> number,
	setPriority: (self: AnatomyHostLayer, priority: number) -> (),
	remove: (self: AnatomyHostLayer) -> (),
}

export type AnatomyHostSocketQuery = {
	layerId: LayerId?,
	includeOverrides: boolean?,
}

export type AnatomyHostSocketAddress = AnatomyHostSocketQuery & {
	socket: SocketName,
}

export type AnatomyInstanceSocketAddress = {
	instance: AnatomyInstance,
	socket: SocketName,
}

export type AnatomyHostMountEndpoint =
	AnatomyHostSocketAddress | AnatomyInstanceSocketAddress | AnatomySocket | SocketBinding | Attachment

export type AnatomyHostMountConfig = {
	from: AnatomyHostMountEndpoint,
	to: AnatomyHostMountEndpoint,
	options: SocketMountOptions?,
}

export type SocketChangedCallback = (AnatomySocket?) -> ()

export type AnatomyHost = {
	push: (
		self: AnatomyHost,
		instance: AnatomyInstance,
		options: AnatomyHostLayerOptions?
	) -> AnatomyHostLayer,
	remove: (self: AnatomyHost, layerId: LayerId) -> boolean,
	clear: (self: AnatomyHost) -> (),

	getLayer: (self: AnatomyHost, layerId: LayerId) -> AnatomyHostLayer?,
	getLayers: (self: AnatomyHost) -> { AnatomyHostLayer },
	getSocket: (self: AnatomyHost, name: SocketName, query: AnatomyHostSocketQuery?) -> AnatomySocket?,
	bindSocket: (
		self: AnatomyHost,
		name: SocketName,
		callback: SocketChangedCallback,
		runInitially: boolean?
	) -> number,
	unbindSocket: (self: AnatomyHost, name: SocketName, hookId: number) -> boolean,
	socket: (self: AnatomyHost, name: SocketName, query: AnatomyHostSocketQuery?) -> SocketBinding,

	mount: (self: AnatomyHost, config: AnatomyHostMountConfig) -> SocketMount,
	deconstruct: (self: AnatomyHost) -> (),
}

export type AnatomyHostLayerImpl = AnatomyHostLayer & {
	_host: AnatomyHostImpl,
	_instance: AnatomyInstance,
	_priority: number,
	_category: AnatomyCategory?,
	_allowSocketOverrides: boolean,
	_insertOrder: number,
	_destroyed: boolean,
}

export type AnatomyHostImpl = AnatomyHost & {
	_id: string?,
	_layers: { [LayerId]: AnatomyHostLayerImpl },
	_layerOrder: { AnatomyHostLayerImpl },
	_resolvedSockets: { [SocketName]: AnatomySocket? },
	_socketHooks: { [SocketName]: Hook<AnatomySocket?> },
	_socketQueryHooks: { [number]: SocketQueryHookEntry },
	_bindings: { [SocketBindingTypes.SocketBindingImpl]: true },
	_mounts: { [SocketMountTypes.SocketMountImpl]: true },
	_nextLayerOrdinal: number,
	_nextSocketQueryBindId: number,
	_destroyed: boolean,

	_resolveSocket: (
		self: AnatomyHostImpl,
		name: SocketName,
		query: AnatomyHostSocketQuery?
	) -> AnatomySocket?,
	_refreshSocket: (self: AnatomyHostImpl, name: SocketName) -> (),
	_refreshAllSockets: (self: AnatomyHostImpl) -> (),
	_normalizeEndpoint: (
		self: AnatomyHostImpl,
		endpoint: AnatomyHostMountEndpoint
	) -> SocketEndpoint,
	_disconnectBinding: (self: AnatomyHostImpl, binding: SocketBindingTypes.SocketBindingImpl) -> (),
	_disconnectMount: (self: AnatomyHostImpl, mount: SocketMountTypes.SocketMountImpl) -> (),
}

return {}
