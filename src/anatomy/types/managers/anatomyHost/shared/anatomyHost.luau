--!strict
--!optimize 2

local SocketEndpointLifecycleTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.socketEndpoint.shared.socketEndpointLifecycle
)
local CallbackSetTypes =
	require(script.Parent.Parent.Parent.Parent.def.callbackSet.shared.callbackSet)
local AnatomyHostLayerTypes =
	require(script.Parent.Parent.Parent.Parent.components.anatomyHostLayer.shared.anatomyHostLayer)
local AnatomyHostLayerCommandsTypes = require(
	script.Parent.Parent.Parent.Parent.ports.managers.anatomyHost.shared.anatomyHostLayerCommands
)
local AnatomySocketLookupTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.anatomyInstance.shared.anatomySocketLookup
)
local SocketSubscriptionTypes =
	require(script.Parent.Parent.Parent.Parent.ports.managers.anatomyHost.shared.socketSubscription)
local AnatomyInstanceTypes =
	require(script.Parent.Parent.Parent.Parent.components.anatomyInstance.shared.anatomyInstance)
local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.components.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes = require(
	script.Parent.Parent.Parent.Parent.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local AnatomyTemplateTypes =
	require(script.Parent.Parent.Parent.Parent.components.anatomyTemplate.shared.anatomyTemplate)
local SocketBindingTypes =
	require(script.Parent.Parent.Parent.Parent.components.socketBinding.shared.socketBinding)
local SocketEndpointTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.socketEndpoint.shared.socketEndpoint
)
local SocketMountTypes =
	require(script.Parent.Parent.Parent.Parent.components.socketMount.shared.socketMount)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)

type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
type SocketBinding<SocketT> = SocketBindingTypes.SocketBinding<SocketT>
type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>

type SocketEndpointLifecycle = SocketEndpointLifecycleTypes.SocketEndpointLifecycle

export type AnatomyCategory = AnatomyTypes.AnatomyCategory
type CallbackSet<Args...> = CallbackSetTypes.CallbackSet<Args...>
export type LayerId = AnatomyTypes.LayerId
export type NameGuard<TName> = AnatomyTypes.NameGuard<TName>
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions

export type SocketQueryCallbackEntry<SocketT> = {
	name: SocketT,
	query: AnatomyHostSocketQuery?,
	callback: SocketChangedCallback<SocketT>,
	current: AnatomySocket<SocketT>?,
}

export type AnatomyHostOptions<SocketT, TagT> = {
	read id: string?,
	read socketNameGuard: NameGuard<SocketT>,
	read tagGuard: NameGuard<TagT>,
}

export type AnatomyHostLayerOptions = AnatomyHostLayerTypes.AnatomyHostLayerOptions
export type AnatomyHostLayer<SocketT, TagT> = AnatomyHostLayerTypes.AnatomyHostLayer<SocketT, TagT>
type AnatomyHostLayerOwned<SocketT, TagT> = AnatomyHostLayerTypes.AnatomyHostLayerOwned<
	SocketT,
	TagT
>
type AnatomyHostLayerCommands = AnatomyHostLayerCommandsTypes.AnatomyHostLayerCommands
type AnatomySocketLookup<SocketT> = AnatomySocketLookupTypes.AnatomySocketLookup<SocketT>

export type AnatomyHostSocketQuery = {
	layerId: LayerId?,
	includeOverrides: boolean?,
}

export type AnatomyHostTagQuery = AnatomyHostSocketQuery

export type AnatomyHostSocketAddress<SocketT> = AnatomyHostSocketQuery & {
	socket: SocketT,
}

export type AnatomyInstanceSocketAddress<SocketT, TagT> = {
	instance: AnatomySocketLookup<SocketT>,
	socket: SocketT,
}

export type AnatomyHostMountEndpoint<SocketT, TagT> =
	AnatomyHostSocketAddress<SocketT>
	| AnatomyInstanceSocketAddress<SocketT, TagT>
	| SocketEndpoint
	| Attachment

-- Private field view for inspecting the declared table endpoint alternatives.
-- The original endpoint supplies the complete callable contract after narrowing.
export type AnatomyHostMountEndpointFields<SocketT, TagT> = {
	read getAttachment: unknown,
	read bindAttachmentChanged: unknown,
	read instance: AnatomySocketLookup<SocketT>?,
	read socket: SocketT?,
	read layerId: LayerId?,
	read includeOverrides: boolean?,
}

export type AnatomyHostMountConfig<SocketT, TagT> = {
	from: AnatomyHostMountEndpoint<SocketT, TagT>,
	to: AnatomyHostMountEndpoint<SocketT, TagT>,
	options: SocketMountOptions?,
}

export type SocketChangedCallback<SocketT> = SocketSubscriptionTypes.SocketChangedCallback<SocketT>
export type TagChangedCallback<TagT> = (AnatomyTaggedElement<TagT>) -> ()

export type AnatomyHost<SocketT, TagT> = {
	read push: (
		self: AnatomyHost<SocketT, TagT>,
		instance: AnatomyInstance<SocketT, TagT>,
		options: AnatomyHostLayerOptions?
	) -> AnatomyHostLayer<SocketT, TagT>,
	read remove: (self: AnatomyHost<SocketT, TagT>, layerId: LayerId) -> boolean,
	read clear: (self: AnatomyHost<SocketT, TagT>) -> (),

	read getLayer: (
		self: AnatomyHost<SocketT, TagT>,
		layerId: LayerId
	) -> AnatomyHostLayer<SocketT, TagT>?,
	read getLayers: (self: AnatomyHost<SocketT, TagT>) -> { AnatomyHostLayer<SocketT, TagT> },
	read getSocketNames: (
		self: AnatomyHost<SocketT, TagT>,
		query: AnatomyHostSocketQuery?
	) -> { SocketT },
	read getSockets: (
		self: AnatomyHost<SocketT, TagT>,
		query: AnatomyHostSocketQuery?
	) -> { [SocketT]: AnatomySocket<SocketT> },
	read getSocket: (
		self: AnatomyHost<SocketT, TagT>,
		name: SocketT,
		query: AnatomyHostSocketQuery?
	) -> AnatomySocket<SocketT>?,
	read bindSocket: (
		self: AnatomyHost<SocketT, TagT>,
		name: SocketT,
		callback: SocketChangedCallback<SocketT>,
		runInitially: boolean?
	) -> () -> (),
	read socket: (
		self: AnatomyHost<SocketT, TagT>,
		name: SocketT,
		query: AnatomyHostSocketQuery?
	) -> SocketBinding<SocketT>,

	read getByTag: (
		self: AnatomyHost<SocketT, TagT>,
		prefix: string,
		query: AnatomyHostTagQuery?
	) -> { AnatomyTaggedElement<TagT> },
	read bindByTag: (
		self: AnatomyHost<SocketT, TagT>,
		prefix: string,
		onAdded: TagChangedCallback<TagT>,
		onRemoved: TagChangedCallback<TagT>,
		runInitially: boolean?
	) -> () -> (),

	read mount: (
		self: AnatomyHost<SocketT, TagT>,
		config: AnatomyHostMountConfig<SocketT, TagT>
	) -> SocketMount,
	read deconstruct: (self: AnatomyHost<SocketT, TagT>) -> (),
}

export type AnatomyHostImpl<SocketT, TagT> =
	AnatomyHost<SocketT, TagT>
	& AnatomyHostLayerCommands
	& {
		_id: string?,
		_socketNameGuard: NameGuard<SocketT>,
		_tagGuard: NameGuard<TagT>,
		_layers: { [LayerId]: AnatomyHostLayerOwned<SocketT, TagT> },
		_layerOrder: { AnatomyHostLayerOwned<SocketT, TagT> },
		_resolvedSockets: { [SocketT]: AnatomySocket<SocketT>? },
		_socketCallbacks: { [SocketT]: CallbackSet<AnatomySocket<SocketT>?> },
		_socketQueryCallbacks: { [SocketQueryCallbackEntry<SocketT>]: true },
		_tagPrefixCallbacks: {
			[string]: {
				added: CallbackSet<AnatomyTaggedElement<TagT>>,
				removed: CallbackSet<AnatomyTaggedElement<TagT>>,
			},
		},
		_resolvedByPrefix: { [string]: { [AnatomyTaggedElement<TagT>]: true } },
		_bindings: { [SocketBinding<SocketT>]: true },
		_mounts: { [SocketMount]: true },
		_nextLayerOrdinal: number,
		_destroyed: boolean,

		_resolveSocket: (
			self: AnatomyHostImpl<SocketT, TagT>,
			name: SocketT,
			query: AnatomyHostSocketQuery?
		) -> AnatomySocket<SocketT>?,
		_refreshSocket: (self: AnatomyHostImpl<SocketT, TagT>, name: SocketT) -> (),
		_refreshAllSockets: (self: AnatomyHostImpl<SocketT, TagT>) -> (),
		_refreshTagPrefix: (self: AnatomyHostImpl<SocketT, TagT>, prefix: string) -> (),
		_refreshAllWatchedPrefixes: (self: AnatomyHostImpl<SocketT, TagT>) -> (),
		_normalizeEndpoint: (
			self: AnatomyHostImpl<SocketT, TagT>,
			endpoint: AnatomyHostMountEndpoint<SocketT, TagT>
		) -> (SocketEndpoint, SocketEndpointLifecycle?),
	}

return {}
