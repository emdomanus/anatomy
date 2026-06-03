--!strict
--!optimize 2
--!native

local CallbackSetTypes = require(script.Parent.Parent.Parent.utils.callbackSet)
local AnatomyInstanceTypes = require(script.Parent.Parent.components.anatomyInstance)
local AnatomySocketTypes = require(script.Parent.Parent.components.anatomySocket)
local AnatomySurfaceTypes = require(script.Parent.Parent.components.anatomySurface)
local SocketBindingTypes = require(script.Parent.Parent.components.socketBinding)
local SocketEndpointTypes = require(script.Parent.Parent.components.socketEndpoint)
local SocketMountTypes = require(script.Parent.Parent.components.socketMount)
local DefTypes = require(script.Parent.Parent.def)

export type AnatomyCategory = DefTypes.AnatomyCategory
export type CallbackSet = CallbackSetTypes.CallbackSet
export type LayerId = DefTypes.LayerId
export type NameGuard<TName> = DefTypes.NameGuard<TName>
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions

export type SocketQueryCallbackEntry<TSocketName> = {
	name: TSocketName,
	query: AnatomyHostSocketQuery?,
	callback: SocketChangedCallback<TSocketName>,
	current: AnatomySocketTypes.AnatomySocket<TSocketName>?,
}

export type AnatomyHostOptions<TSocketName, TSurfaceName> = {
	id: string?,
	socketNameGuard: NameGuard<TSocketName>?,
	surfaceNameGuard: NameGuard<TSurfaceName>?,
}

export type AnatomyHostLayerOptions = {
	id: LayerId?,
	priority: number?,
	category: AnatomyCategory?,
	allowSocketOverrides: boolean?,
}

export type AnatomyHostLayer<TSocketName, TSurfaceName> = {
	id: LayerId,
	getInstance: (
		self: AnatomyHostLayer<TSocketName, TSurfaceName>
	) -> AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>,
	getPriority: (self: AnatomyHostLayer<TSocketName, TSurfaceName>) -> number,
	setPriority: (self: AnatomyHostLayer<TSocketName, TSurfaceName>, priority: number) -> (),
	remove: (self: AnatomyHostLayer<TSocketName, TSurfaceName>) -> (),
}

export type AnatomyHostSocketQuery = {
	layerId: LayerId?,
	includeOverrides: boolean?,
}

export type AnatomyHostSurfaceQuery = AnatomyHostSocketQuery

export type AnatomyHostSocketAddress<TSocketName> = AnatomyHostSocketQuery & {
	socket: TSocketName,
}

export type AnatomyInstanceSocketAddress<TSocketName, TSurfaceName> = {
	instance: AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>,
	socket: TSocketName,
}

export type AnatomyHostMountEndpoint<TSocketName, TSurfaceName> =
	AnatomyHostSocketAddress<TSocketName>
	| AnatomyInstanceSocketAddress<TSocketName, TSurfaceName>
	| AnatomySocketTypes.AnatomySocket<TSocketName>
	| SocketBindingTypes.SocketBinding<TSocketName>
	| Attachment

export type AnatomyHostMountConfig<TSocketName, TSurfaceName> = {
	from: AnatomyHostMountEndpoint<TSocketName, TSurfaceName>,
	to: AnatomyHostMountEndpoint<TSocketName, TSurfaceName>,
	options: SocketMountOptions?,
}

export type SocketChangedCallback<TSocketName> = (AnatomySocketTypes.AnatomySocket<TSocketName>?) -> ()
export type SurfaceChangedCallback<TSurfaceName> = (AnatomySurfaceTypes.AnatomySurface<TSurfaceName>?) -> ()
export type SurfaceAddedCallback<TSocketName, TSurfaceName> = (
	AnatomySurfaceTypes.AnatomySurface<TSurfaceName>,
	AnatomyHostLayer<TSocketName, TSurfaceName>
) -> ()
export type SurfaceRemovedCallback<TSocketName, TSurfaceName> = (
	AnatomySurfaceTypes.AnatomySurface<TSurfaceName>,
	AnatomyHostLayer<TSocketName, TSurfaceName>
) -> ()

export type AnatomyHost<TSocketName, TSurfaceName> = {
	push: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		instance: AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>,
		options: AnatomyHostLayerOptions?
	) -> AnatomyHostLayer<TSocketName, TSurfaceName>,
	remove: (self: AnatomyHost<TSocketName, TSurfaceName>, layerId: LayerId) -> boolean,
	clear: (self: AnatomyHost<TSocketName, TSurfaceName>) -> (),

	getLayer: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		layerId: LayerId
	) -> AnatomyHostLayer<TSocketName, TSurfaceName>?,
	getLayers: (self: AnatomyHost<TSocketName, TSurfaceName>) -> { AnatomyHostLayer<TSocketName, TSurfaceName> },
	getSocketNames: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		query: AnatomyHostSocketQuery?
	) -> { TSocketName },
	getSockets: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		query: AnatomyHostSocketQuery?
	) -> { [TSocketName]: AnatomySocketTypes.AnatomySocket<TSocketName> },
	getSocket: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		name: TSocketName,
		query: AnatomyHostSocketQuery?
	) -> AnatomySocketTypes.AnatomySocket<TSocketName>?,
	bindSocket: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		name: TSocketName,
		callback: SocketChangedCallback<TSocketName>,
		runInitially: boolean?
	) -> () -> (),
	socket: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		name: TSocketName,
		query: AnatomyHostSocketQuery?
	) -> SocketBindingTypes.SocketBinding<TSocketName>,

	getSurfaceNames: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		query: AnatomyHostSurfaceQuery?
	) -> { TSurfaceName },
	getSurfaces: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		query: AnatomyHostSurfaceQuery?
	) -> { [TSurfaceName]: AnatomySurfaceTypes.AnatomySurface<TSurfaceName> },
	getSurface: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		name: TSurfaceName,
		query: AnatomyHostSurfaceQuery?
	) -> AnatomySurfaceTypes.AnatomySurface<TSurfaceName>?,
	bindSurface: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		name: TSurfaceName,
		callback: SurfaceChangedCallback<TSurfaceName>,
		runInitially: boolean?
	) -> () -> (),
	bindSurfaceAdded: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		name: TSurfaceName,
		callback: SurfaceAddedCallback<TSocketName, TSurfaceName>,
		runInitially: boolean?
	) -> () -> (),
	bindSurfaceRemoved: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		name: TSurfaceName,
		callback: SurfaceRemovedCallback<TSocketName, TSurfaceName>
	) -> () -> (),

	mount: (
		self: AnatomyHost<TSocketName, TSurfaceName>,
		config: AnatomyHostMountConfig<TSocketName, TSurfaceName>
	) -> SocketMount,
	deconstruct: (self: AnatomyHost<TSocketName, TSurfaceName>) -> (),
}

export type AnatomyHostLayerImpl<TSocketName, TSurfaceName> = AnatomyHostLayer<TSocketName, TSurfaceName> & {
	_host: AnatomyHostImpl<TSocketName, TSurfaceName>,
	_instance: AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>,
	_priority: number,
	_category: AnatomyCategory?,
	_allowSocketOverrides: boolean,
	_insertOrder: number,
	_destroyed: boolean,
}

export type AnatomyHostImpl<TSocketName, TSurfaceName> = AnatomyHost<TSocketName, TSurfaceName> & {
	_id: string?,
	_socketNameGuard: NameGuard<TSocketName>?,
	_surfaceNameGuard: NameGuard<TSurfaceName>?,
	_layers: { [LayerId]: AnatomyHostLayerImpl<TSocketName, TSurfaceName> },
	_layerOrder: { AnatomyHostLayerImpl<TSocketName, TSurfaceName> },
	_resolvedSockets: { [TSocketName]: AnatomySocketTypes.AnatomySocket<TSocketName>? },
	_socketCallbacks: { [TSocketName]: CallbackSet },
	_socketQueryCallbacks: { [SocketQueryCallbackEntry<TSocketName>]: true },
	_resolvedSurfaces: { [TSurfaceName]: AnatomySurfaceTypes.AnatomySurface<TSurfaceName>? },
	_surfaceCallbacks: { [TSurfaceName]: CallbackSet },
	_surfaceAddedCallbacks: { [TSurfaceName]: CallbackSet },
	_surfaceRemovedCallbacks: { [TSurfaceName]: CallbackSet },
	_bindings: { [SocketBindingTypes.SocketBindingImpl<TSocketName>]: true },
	_mounts: { [SocketMountTypes.SocketMountImpl]: true },
	_nextLayerOrdinal: number,
	_destroyed: boolean,

	_resolveSocket: (
		self: AnatomyHostImpl<TSocketName, TSurfaceName>,
		name: TSocketName,
		query: AnatomyHostSocketQuery?
	) -> AnatomySocketTypes.AnatomySocket<TSocketName>?,
	_refreshSocket: (self: AnatomyHostImpl<TSocketName, TSurfaceName>, name: TSocketName) -> (),
	_refreshAllSockets: (self: AnatomyHostImpl<TSocketName, TSurfaceName>) -> (),
	_resolveSurface: (
		self: AnatomyHostImpl<TSocketName, TSurfaceName>,
		name: TSurfaceName,
		query: AnatomyHostSurfaceQuery?
	) -> AnatomySurfaceTypes.AnatomySurface<TSurfaceName>?,
	_refreshSurface: (self: AnatomyHostImpl<TSocketName, TSurfaceName>, name: TSurfaceName) -> (),
	_refreshAllSurfaces: (self: AnatomyHostImpl<TSocketName, TSurfaceName>) -> (),
	_normalizeEndpoint: (
		self: AnatomyHostImpl<TSocketName, TSurfaceName>,
		endpoint: AnatomyHostMountEndpoint<TSocketName, TSurfaceName>
	) -> SocketEndpoint,
}

return {}
