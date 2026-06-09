--!strict
--!optimize 2
--!native

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet)
local AnatomyHostLayer = require(script.Parent.Parent.Parent.Parent.managers.anatomyHostLayer.shared.anatomyHostLayer)
local SocketBinding = require(script.Parent.Parent.Parent.Parent.components.socketBinding.shared.socketBinding)
local SocketEndpoint = require(script.Parent.Parent.Parent.Parent.components.socketEndpoint.shared.socketEndpoint)
local SocketMount = require(script.Parent.Parent.Parent.Parent.components.socketMount.shared.socketMount)
local AnatomyInstanceTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyInstance)
local AnatomySocketTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket)
local AnatomyTaggedElementTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyTaggedElement)
local SocketBindingTypes = require(script.Parent.Parent.Parent.Parent.types.components.socketBinding)
local Types = require(script.Parent.Parent.Parent.Parent.types.managers.anatomyHost)

export type AnatomyHost<TSocketName, TSurfaceName> = Types.AnatomyHost<TSocketName, TSurfaceName>
export type AnatomyHostImpl<TSocketName, TSurfaceName> = Types.AnatomyHostImpl<TSocketName, TSurfaceName>
export type AnatomyHostLayer<TSocketName, TSurfaceName> = Types.AnatomyHostLayer<TSocketName, TSurfaceName>
export type AnatomyHostLayerImpl<TSocketName, TSurfaceName> = Types.AnatomyHostLayerImpl<TSocketName, TSurfaceName>
export type AnatomyHostLayerOptions = Types.AnatomyHostLayerOptions
export type AnatomyHostMountConfig<TSocketName, TSurfaceName> = Types.AnatomyHostMountConfig<TSocketName, TSurfaceName>
export type AnatomyHostMountEndpoint<TSocketName, TSurfaceName> = Types.AnatomyHostMountEndpoint<TSocketName, TSurfaceName>
export type AnatomyHostOptions<TSocketName, TSurfaceName> = Types.AnatomyHostOptions<TSocketName, TSurfaceName>
export type AnatomyHostTagQuery = Types.AnatomyHostTagQuery
export type AnatomyHostSocketQuery = Types.AnatomyHostSocketQuery
export type AnatomyInstance<TSocketName, TSurfaceName> = AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>
export type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
export type AnatomySocket<TSocketName> = AnatomySocketTypes.AnatomySocket<TSocketName>
export type LayerId = Types.LayerId
export type SocketBinding<TSocketName> = SocketBindingTypes.SocketBinding<TSocketName>
export type SocketChangedCallback<TSocketName> = Types.SocketChangedCallback<TSocketName>
export type SocketEndpoint = Types.SocketEndpoint
export type SocketMount = Types.SocketMount
export type TagChangedCallback<TagT> = Types.TagChangedCallback<TagT>

local AnatomyHost = {}
AnatomyHost.__index = AnatomyHost

local function weakKeySet(): { [any]: true }
	return setmetatable({}, {
		__mode = "k",
	}) :: any
end

local function sortHostLayers<TSocketName, TSurfaceName>(
	layerOrder: { AnatomyHostLayerImpl<TSocketName, TSurfaceName> }
): ()
	table.sort(layerOrder, function(left, right)
		if left._priority == right._priority then
			return left._insertOrder < right._insertOrder
		end

		return left._priority < right._priority
	end)
end

local function collectSocketNames<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>
): { [TSocketName]: boolean }
	local names = {}

	for name in self._resolvedSockets do
		names[name] = true
	end

	for _, layer in self._layerOrder do
		for name in layer._instance:getSockets() do
			names[name] = true
		end
	end

	return names
end

local function makeSortedNameList<TName>(names: { [TName]: boolean }): { TName }
	local count = 0
	for _ in names do
		count += 1
	end

	local nameList: { TName } = table.create(count)
	for name in names do
		table.insert(nameList, name)
	end

	table.sort(nameList :: any)
	return nameList
end

local function isCallbackSetEmpty(callbacks: { [any]: true }): boolean
	for _ in callbacks do
		return false
	end

	return true
end

local function areTagCallbacksEmpty(callbacks: { added: { [any]: true }, removed: { [any]: true } }): boolean
	return isCallbackSetEmpty(callbacks.added) and isCallbackSetEmpty(callbacks.removed)
end

local function collectTaggedElements<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	prefix: string,
	query: AnatomyHostTagQuery?
): { AnatomyTaggedElement<TSurfaceName> }
	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return {}
		end

		return layer._instance:getByTag(prefix)
	end

	local elements = {}
	for _, layer in self._layerOrder do
		for _, element in layer._instance:getByTag(prefix) do
			table.insert(elements, element)
		end
	end

	return elements
end

local function collectTaggedElementSet<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	prefix: string
): { [AnatomyTaggedElement<TSurfaceName>]: true }
	local set = {}

	for _, element in collectTaggedElements(self, prefix, nil) do
		set[element] = true
	end

	return set
end

local function tagSetToList<TagT>(set: { [AnatomyTaggedElement<TagT>]: true }): { AnatomyTaggedElement<TagT> }
	local elements = {}

	for element in set do
		table.insert(elements, element)
	end

	return elements
end

local function copyQuery(query: AnatomyHostSocketQuery?): AnatomyHostSocketQuery?
	if query == nil then
		return nil
	end

	return {
		layerId = query.layerId,
		includeOverrides = query.includeOverrides,
	}
end

local function assertSocketNameAllowed<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSocketName
): ()
	local guard = self._socketNameGuard
	if guard ~= nil and not guard(name :: any) then
		error(`Anatomy socket name "{name}" is not allowed by this host`, 3)
	end
end

local function new<TSocketName, TSurfaceName>(
	options: AnatomyHostOptions<TSocketName, TSurfaceName>?
): AnatomyHost<TSocketName, TSurfaceName>
	local self = setmetatable({} :: AnatomyHostImpl<TSocketName, TSurfaceName>, AnatomyHost)

	self._id = if options then options.id else nil
	self._socketNameGuard = if options then options.socketNameGuard else nil
	self._layers = {}
	self._layerOrder = {}
	self._resolvedSockets = {}
	self._socketCallbacks = {}
	self._socketQueryCallbacks = {}
	self._tagPrefixCallbacks = {}
	self._resolvedByPrefix = {}
	self._bindings = weakKeySet() :: any
	self._mounts = weakKeySet() :: any
	self._nextLayerOrdinal = 1
	self._destroyed = false

	return self
end

function AnatomyHost.push<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	instance: AnatomyInstance<TSocketName, TSurfaceName>,
	options: AnatomyHostLayerOptions?
): AnatomyHostLayer<TSocketName, TSurfaceName>
	local layerId = if options and options.id then options.id else `layer_{self._nextLayerOrdinal}`
	if self._layers[layerId] ~= nil then
		error(`AnatomyHost layer "{layerId}" already exists`, 2)
	end

	local insertOrder = self._nextLayerOrdinal
	self._nextLayerOrdinal += 1

	for name in instance:getSockets() do
		assertSocketNameAllowed(self, name)
	end

	local layer = AnatomyHostLayer.new(
		self,
		layerId,
		instance,
		if options and options.priority ~= nil then options.priority else 0,
		if options and options.category ~= nil then options.category else instance:getCategory(),
		if options and options.allowSocketOverrides ~= nil then options.allowSocketOverrides else true,
		insertOrder
	)

	self._layers[layerId] = layer
	table.insert(self._layerOrder, layer)
	sortHostLayers(self._layerOrder)

	self:_refreshAllSockets()
	self:_refreshAllWatchedPrefixes()

	return layer
end

function AnatomyHost.remove<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	layerId: LayerId
): boolean
	local layer = self._layers[layerId]
	if layer == nil then
		return false
	end

	layer._destroyed = true
	self._layers[layerId] = nil

	local index = table.find(self._layerOrder, layer)
	if index ~= nil then
		table.remove(self._layerOrder, index)
	end

	self:_refreshAllSockets()
	self:_refreshAllWatchedPrefixes()
	return true
end

function AnatomyHost.clear<TSocketName, TSurfaceName>(self: AnatomyHostImpl<TSocketName, TSurfaceName>): ()
	local layerIds = {}
	for layerId in self._layers do
		table.insert(layerIds, layerId)
	end

	for _, layerId in layerIds do
		self:remove(layerId)
	end
end

function AnatomyHost.getLayer<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	layerId: LayerId
): AnatomyHostLayer<TSocketName, TSurfaceName>?
	return self._layers[layerId]
end

function AnatomyHost.getLayers<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>
): { AnatomyHostLayer<TSocketName, TSurfaceName> }
	return table.clone(self._layerOrder) :: any
end

function AnatomyHost.getSocketNames<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	query: AnatomyHostSocketQuery?
): { TSocketName }
	local names: { [TSocketName]: boolean } = {}

	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return {}
		end

		for name in layer._instance:getSockets() do
			names[name] = true
		end

		return makeSortedNameList(names) :: any
	end

	for name in collectSocketNames(self) do
		if self:_resolveSocket(name, query) ~= nil then
			names[name] = true
		end
	end

	return makeSortedNameList(names) :: any
end

function AnatomyHost.getSockets<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	query: AnatomyHostSocketQuery?
): { [TSocketName]: AnatomySocket<TSocketName> }
	local sockets: { [TSocketName]: AnatomySocket<TSocketName> } = {}

	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return sockets
		end

		return layer._instance:getSockets()
	end

	for name in collectSocketNames(self) do
		local socket = self:_resolveSocket(name, query)
		if socket == nil then
			continue
		end

		sockets[name] = socket
	end

	return sockets
end

function AnatomyHost.getSocket<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSocketName,
	query: AnatomyHostSocketQuery?
): AnatomySocket<TSocketName>?
	assertSocketNameAllowed(self, name)
	return self:_resolveSocket(name, query)
end

function AnatomyHost.bindSocket<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSocketName,
	callback: SocketChangedCallback<TSocketName>,
	runInitially: boolean?
): () -> ()
	assertSocketNameAllowed(self, name)

	local callbacks = self._socketCallbacks[name]
	if callbacks == nil then
		callbacks = CallbackSet.new()
		self._socketCallbacks[name] = callbacks
	end

	if runInitially == true then
		callback(self:_resolveSocket(name, nil))
	end

	return CallbackSet.bind(callbacks, callback)
end

local function bindSocketQuery<TSocketName, TSurfaceName>(
	host: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSocketName,
	query: AnatomyHostSocketQuery?,
	callback: SocketChangedCallback<TSocketName>,
	runInitially: boolean?
): () -> ()
	assertSocketNameAllowed(host, name)

	if query == nil then
		return host:bindSocket(name, callback, runInitially)
	end

	local current = host:_resolveSocket(name, query)
	local entry = {
		name = name,
		query = copyQuery(query),
		callback = callback,
		current = current,
	}
	host._socketQueryCallbacks[entry] = true

	if runInitially == true then
		callback(current)
	end

	return function()
		host._socketQueryCallbacks[entry] = nil
	end
end

function AnatomyHost.getByTag<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	prefix: string,
	query: AnatomyHostTagQuery?
): { AnatomyTaggedElement<TSurfaceName> }
	local resolved = if query == nil then self._resolvedByPrefix[prefix] else nil
	if resolved ~= nil then
		return tagSetToList(resolved)
	end

	return collectTaggedElements(self, prefix, query)
end

function AnatomyHost.bindByTag<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	prefix: string,
	onAdded: TagChangedCallback<TSurfaceName>,
	onRemoved: TagChangedCallback<TSurfaceName>,
	runInitially: boolean?
): () -> ()
	local callbacks = self._tagPrefixCallbacks[prefix]
	if callbacks == nil then
		callbacks = {
			added = CallbackSet.new(),
			removed = CallbackSet.new(),
		}
		self._tagPrefixCallbacks[prefix] = callbacks
		self._resolvedByPrefix[prefix] = collectTaggedElementSet(self, prefix)
	end

	local unbindAdded = CallbackSet.bind(callbacks.added, onAdded)
	local unbindRemoved = CallbackSet.bind(callbacks.removed, onRemoved)

	if runInitially == true then
		for element in self._resolvedByPrefix[prefix] do
			onAdded(element)
		end
	end

	local connected = true
	return function()
		if not connected then
			return
		end

		connected = false
		unbindAdded()
		unbindRemoved()

		if areTagCallbacksEmpty(callbacks) then
			self._tagPrefixCallbacks[prefix] = nil
			self._resolvedByPrefix[prefix] = nil
		end
	end
end

function AnatomyHost.socket<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSocketName,
	query: AnatomyHostSocketQuery?
): SocketBinding<TSocketName>
	assertSocketNameAllowed(self, name)

	local queryCopy = copyQuery(query)
	local source = {
		bindSocket = function(
			_source: any,
			socketName: TSocketName,
			callback: SocketChangedCallback<TSocketName>,
			runInitially: boolean?
		): () -> ()
			return bindSocketQuery(self, socketName, queryCopy, callback, runInitially)
		end,
	}

	local binding = SocketBinding.new(name, source, nil) :: any
	self._bindings[binding] = true

	return binding
end

function AnatomyHost.mount<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	config: AnatomyHostMountConfig<TSocketName, TSurfaceName>
): SocketMount
	local mount = SocketMount.new(
		self:_normalizeEndpoint(config.from),
		self:_normalizeEndpoint(config.to),
		config.options
	) :: any
	self._mounts[mount] = true

	return mount
end

function AnatomyHost._resolveSocket<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSocketName,
	query: AnatomyHostSocketQuery?
): AnatomySocket<TSocketName>?
	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return nil
		end

		return layer._instance:getSocket(name)
	end

	local resolved: AnatomySocket<TSocketName>? = nil
	local includeOverrides = query == nil or query.includeOverrides ~= false

	for _, layer in self._layerOrder do
		local socket = layer._instance:getSocket(name)
		if socket == nil then
			continue
		end

		if resolved == nil then
			resolved = socket
			continue
		end

		if includeOverrides and layer._allowSocketOverrides then
			resolved = socket
		end
	end

	return resolved
end

function AnatomyHost._refreshSocket<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSocketName
): ()
	local oldSocket = self._resolvedSockets[name]
	local newSocket = self:_resolveSocket(name, nil)
	if oldSocket == newSocket then
		return
	end

	self._resolvedSockets[name] = newSocket

	local callbacks = self._socketCallbacks[name]
	if callbacks ~= nil then
		CallbackSet.fire(callbacks, newSocket)
	end
end

function AnatomyHost._refreshAllSockets<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>
): ()
	for name in collectSocketNames(self) do
		self:_refreshSocket(name)
	end

	for entry in self._socketQueryCallbacks do
		local current = self:_resolveSocket(entry.name, entry.query)
		if entry.current ~= current then
			entry.current = current
			entry.callback(current)
		end
	end
end

function AnatomyHost._refreshTagPrefix<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	prefix: string
): ()
	local oldSet = self._resolvedByPrefix[prefix]
	if oldSet == nil then
		return
	end

	local newSet = collectTaggedElementSet(self, prefix)
	self._resolvedByPrefix[prefix] = newSet

	local callbacks = self._tagPrefixCallbacks[prefix]
	if callbacks == nil then
		return
	end

	for element in newSet do
		if oldSet[element] ~= true then
			CallbackSet.fire(callbacks.added, element)
		end
	end

	for element in oldSet do
		if newSet[element] ~= true then
			CallbackSet.fire(callbacks.removed, element)
		end
	end
end

function AnatomyHost._refreshAllWatchedPrefixes<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>
): ()
	for prefix in self._tagPrefixCallbacks do
		self:_refreshTagPrefix(prefix)
	end
end

function AnatomyHost._normalizeEndpoint<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	endpoint: AnatomyHostMountEndpoint<TSocketName, TSurfaceName>
): SocketEndpoint
	local endpointValue = endpoint :: any
	if typeof(endpointValue) == "Instance" and endpointValue:IsA("Attachment") then
		return SocketEndpoint.fromAttachment(endpointValue)
	end

	if typeof(endpointValue) == "table" then
		if endpointValue.getAttachment ~= nil and endpointValue.bindAttachmentChanged ~= nil then
			return endpointValue :: SocketEndpoint
		end

		if endpointValue.instance ~= nil and endpointValue.socket ~= nil then
			local socketName = (endpointValue.socket :: any) :: TSocketName
			assertSocketNameAllowed(self, socketName)

			local socket = endpointValue.instance:getSocket(socketName)
			if socket == nil then
				error(`Anatomy instance socket "{socketName}" could not be resolved`, 2)
			end

			return socket :: any
		end

		if endpointValue.socket ~= nil then
			local socketName = (endpointValue.socket :: any) :: TSocketName
			assertSocketNameAllowed(self, socketName)

			return self:socket(socketName, endpointValue)
		end
	end

	error("Invalid anatomy socket mount endpoint", 2)
end

function AnatomyHost.deconstruct<TSocketName, TSurfaceName>(self: AnatomyHostImpl<TSocketName, TSurfaceName>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	for mount in self._mounts do
		mount:deconstruct()
	end
	table.clear(self._mounts)

	for binding in self._bindings do
		binding:deconstruct()
	end
	table.clear(self._bindings)

	table.clear(self._socketQueryCallbacks)

	for _, callbacks in self._socketCallbacks do
		table.clear(callbacks)
	end
	table.clear(self._socketCallbacks)

	for _, callbacks in self._tagPrefixCallbacks do
		table.clear(callbacks.added)
		table.clear(callbacks.removed)
	end
	table.clear(self._tagPrefixCallbacks)

	for _, layer in self._layerOrder do
		layer._destroyed = true
	end
	table.clear(self._layerOrder)
	table.clear(self._layers)
	table.clear(self._resolvedSockets)
	table.clear(self._resolvedByPrefix)
end


return {
	new = new,
}
