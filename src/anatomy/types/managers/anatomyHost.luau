--!strict
--!optimize 2
--!native

local CallbackSetTypes = require(script.Parent.Parent.Parent.utils.callbackSet)
local AnatomyInstanceTypes = require(script.Parent.Parent.components.anatomyInstance)
local AnatomySocketTypes = require(script.Parent.Parent.components.anatomySocket)
local AnatomyTaggedElementTypes = require(script.Parent.Parent.components.anatomyTaggedElement)
local AnatomyTemplateTypes = require(script.Parent.Parent.components.anatomyTemplate)
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

export type SocketQueryCallbackEntry<SocketT> = {
	name: SocketT,
	query: AnatomyHostSocketQuery?,
	callback: SocketChangedCallback<SocketT>,
	current: AnatomySocketTypes.AnatomySocket<SocketT>?,
}

export type AnatomyHostOptions<SocketT> = {
	id: string?,
	socketNameGuard: NameGuard<SocketT>?,
}

export type AnatomyHostLayerOptions = {
	id: LayerId?,
	priority: number?,
	category: AnatomyCategory?,
	allowSocketOverrides: boolean?,
}

export type AnatomyHostLayer<SocketT, TagT> = {
	id: LayerId,
	getInstance: (
		self: AnatomyHostLayer<SocketT, TagT>
	) -> AnatomyInstanceTypes.AnatomyInstance<AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>, SocketT, TagT>,
	getPriority: (self: AnatomyHostLayer<SocketT, TagT>) -> number,
	setPriority: (self: AnatomyHostLayer<SocketT, TagT>, priority: number) -> (),
	remove: (self: AnatomyHostLayer<SocketT, TagT>) -> (),
}

export type AnatomyHostSocketQuery = {
	layerId: LayerId?,
	includeOverrides: boolean?,
}

export type AnatomyHostTagQuery = AnatomyHostSocketQuery

export type AnatomyHostSocketAddress<SocketT> = AnatomyHostSocketQuery & {
	socket: SocketT,
}

export type AnatomyInstanceSocketAddress<SocketT, TagT> = {
	instance: AnatomyInstanceTypes.AnatomyInstance<AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>, SocketT, TagT>,
	socket: SocketT,
}

export type AnatomyHostMountEndpoint<SocketT, TagT> =
	AnatomyHostSocketAddress<SocketT>
	| AnatomyInstanceSocketAddress<SocketT, TagT>
	| AnatomySocketTypes.AnatomySocket<SocketT>
	| SocketBindingTypes.SocketBinding<SocketT>
	| Attachment

export type AnatomyHostMountConfig<SocketT, TagT> = {
	from: AnatomyHostMountEndpoint<SocketT, TagT>,
	to: AnatomyHostMountEndpoint<SocketT, TagT>,
	options: SocketMountOptions?,
}

export type SocketChangedCallback<SocketT> = (AnatomySocketTypes.AnatomySocket<SocketT>?) -> ()
export type TagChangedCallback<TagT> = (AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>) -> ()

export type AnatomyHost<SocketT, TagT> = {
	push: (
		self: AnatomyHost<SocketT, TagT>,
		instance: AnatomyInstanceTypes.AnatomyInstance<AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>, SocketT, TagT>,
		options: AnatomyHostLayerOptions?
	) -> AnatomyHostLayer<SocketT, TagT>,
	remove: (self: AnatomyHost<SocketT, TagT>, layerId: LayerId) -> boolean,
	clear: (self: AnatomyHost<SocketT, TagT>) -> (),

	getLayer: (
		self: AnatomyHost<SocketT, TagT>,
		layerId: LayerId
	) -> AnatomyHostLayer<SocketT, TagT>?,
	getLayers: (self: AnatomyHost<SocketT, TagT>) -> { AnatomyHostLayer<SocketT, TagT> },
	getSocketNames: (
		self: AnatomyHost<SocketT, TagT>,
		query: AnatomyHostSocketQuery?
	) -> { SocketT },
	getSockets: (
		self: AnatomyHost<SocketT, TagT>,
		query: AnatomyHostSocketQuery?
	) -> { [SocketT]: AnatomySocketTypes.AnatomySocket<SocketT> },
	getSocket: (
		self: AnatomyHost<SocketT, TagT>,
		name: SocketT,
		query: AnatomyHostSocketQuery?
	) -> AnatomySocketTypes.AnatomySocket<SocketT>?,
	bindSocket: (
		self: AnatomyHost<SocketT, TagT>,
		name: SocketT,
		callback: SocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
	socket: (
		self: AnatomyHost<SocketT, TagT>,
		name: SocketT,
		query: AnatomyHostSocketQuery?
	) -> SocketBindingTypes.SocketBinding<SocketT>,

	getByTag: (
		self: AnatomyHost<SocketT, TagT>,
		prefix: string,
		query: AnatomyHostTagQuery?
	) -> { AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT> },
	bindByTag: (
		self: AnatomyHost<SocketT, TagT>,
		prefix: string,
		onAdded: TagChangedCallback<TagT>,
		onRemoved: TagChangedCallback<TagT>,
		runInitially: boolean?
	) -> () -> (),

	mount: (
		self: AnatomyHost<SocketT, TagT>,
		config: AnatomyHostMountConfig<SocketT, TagT>
	) -> SocketMount,
	deconstruct: (self: AnatomyHost<SocketT, TagT>) -> (),
}

export type AnatomyHostLayerImpl<SocketT, TagT> = AnatomyHostLayer<SocketT, TagT> & {
	_host: AnatomyHostImpl<SocketT, TagT>,
	_instance: AnatomyInstanceTypes.AnatomyInstance<AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>, SocketT, TagT>,
	_priority: number,
	_category: AnatomyCategory?,
	_allowSocketOverrides: boolean,
	_insertOrder: number,
	_destroyed: boolean,
}

export type AnatomyHostImpl<SocketT, TagT> = AnatomyHost<SocketT, TagT> & {
	_id: string?,
	_socketNameGuard: NameGuard<SocketT>?,
	_layers: { [LayerId]: AnatomyHostLayerImpl<SocketT, TagT> },
	_layerOrder: { AnatomyHostLayerImpl<SocketT, TagT> },
	_resolvedSockets: { [SocketT]: AnatomySocketTypes.AnatomySocket<SocketT>? },
	_socketCallbacks: { [SocketT]: CallbackSet },
	_socketQueryCallbacks: { [SocketQueryCallbackEntry<SocketT>]: true },
	_tagPrefixCallbacks: { [string]: { added: CallbackSet, removed: CallbackSet } },
	_resolvedByPrefix: { [string]: { [AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>]: true } },
	_bindings: { [SocketBindingTypes.SocketBindingImpl<SocketT>]: true },
	_mounts: { [SocketMountTypes.SocketMountImpl]: true },
	_nextLayerOrdinal: number,
	_destroyed: boolean,

	_resolveSocket: (
		self: AnatomyHostImpl<SocketT, TagT>,
		name: SocketT,
		query: AnatomyHostSocketQuery?
	) -> AnatomySocketTypes.AnatomySocket<SocketT>?,
	_refreshSocket: (self: AnatomyHostImpl<SocketT, TagT>, name: SocketT) -> (),
	_refreshAllSockets: (self: AnatomyHostImpl<SocketT, TagT>) -> (),
	_refreshTagPrefix: (self: AnatomyHostImpl<SocketT, TagT>, prefix: string) -> (),
	_refreshAllWatchedPrefixes: (self: AnatomyHostImpl<SocketT, TagT>) -> (),
	_normalizeEndpoint: (
		self: AnatomyHostImpl<SocketT, TagT>,
		endpoint: AnatomyHostMountEndpoint<SocketT, TagT>
	) -> SocketEndpoint,
}

return {}
