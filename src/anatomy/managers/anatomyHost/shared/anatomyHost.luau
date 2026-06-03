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
local AnatomySurfaceTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomySurface)
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
export type AnatomyHostSurfaceQuery = Types.AnatomyHostSurfaceQuery
export type AnatomyHostSocketQuery = Types.AnatomyHostSocketQuery
export type AnatomyInstance<TSocketName, TSurfaceName> = AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>
export type AnatomySurface<TSurfaceName> = AnatomySurfaceTypes.AnatomySurface<TSurfaceName>
export type AnatomySocket<TSocketName> = AnatomySocketTypes.AnatomySocket<TSocketName>
export type LayerId = Types.LayerId
export type SocketBinding<TSocketName> = SocketBindingTypes.SocketBinding<TSocketName>
export type SocketChangedCallback<TSocketName> = Types.SocketChangedCallback<TSocketName>
export type SocketEndpoint = Types.SocketEndpoint
export type SocketMount = Types.SocketMount
export type SurfaceAddedCallback<TSocketName, TSurfaceName> = Types.SurfaceAddedCallback<TSocketName, TSurfaceName>
export type SurfaceChangedCallback<TSurfaceName> = Types.SurfaceChangedCallback<TSurfaceName>
export type SurfaceRemovedCallback<TSocketName, TSurfaceName> = Types.SurfaceRemovedCallback<TSocketName, TSurfaceName>

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

local function collectSurfaceNames<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>
): { [TSurfaceName]: boolean }
	local names = {}

	for name in self._resolvedSurfaces do
		names[name] = true
	end

	for _, layer in self._layerOrder do
		for name in layer._instance:getSurfaces() do
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

local function assertSurfaceNameAllowed<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName
): ()
	local guard = self._surfaceNameGuard
	if guard ~= nil and not guard(name :: any) then
		error(`Anatomy surface name "{name}" is not allowed by this host`, 3)
	end
end

local function new<TSocketName, TSurfaceName>(
	options: AnatomyHostOptions<TSocketName, TSurfaceName>?
): AnatomyHost<TSocketName, TSurfaceName>
	local self = setmetatable({} :: AnatomyHostImpl<TSocketName, TSurfaceName>, AnatomyHost)

	self._id = if options then options.id else nil
	self._socketNameGuard = if options then options.socketNameGuard else nil
	self._surfaceNameGuard = if options then options.surfaceNameGuard else nil
	self._layers = {}
	self._layerOrder = {}
	self._resolvedSockets = {}
	self._socketCallbacks = {}
	self._socketQueryCallbacks = {}
	self._resolvedSurfaces = {}
	self._surfaceCallbacks = {}
	self._surfaceAddedCallbacks = {}
	self._surfaceRemovedCallbacks = {}
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

	for name in instance:getSurfaces() do
		assertSurfaceNameAllowed(self, name)
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

	for name, surface in instance:getSurfaces() do
		local callbacks = self._surfaceAddedCallbacks[name]
		if callbacks ~= nil then
			CallbackSet.fire(callbacks, surface, layer)
		end
	end

	self:_refreshAllSockets()
	self:_refreshAllSurfaces()

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

	for name, surface in layer._instance:getSurfaces() do
		local callbacks = self._surfaceRemovedCallbacks[name]
		if callbacks ~= nil then
			CallbackSet.fire(callbacks, surface, layer)
		end
	end

	self:_refreshAllSockets()
	self:_refreshAllSurfaces()
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

function AnatomyHost.getSurfaceNames<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	query: AnatomyHostSurfaceQuery?
): { TSurfaceName }
	local names: { [TSurfaceName]: boolean } = {}

	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return {}
		end

		for name in layer._instance:getSurfaces() do
			names[name] = true
		end

		return makeSortedNameList(names :: any) :: any
	end

	for name in collectSurfaceNames(self) do
		if self:_resolveSurface(name, query) ~= nil then
			names[name] = true
		end
	end

	return makeSortedNameList(names :: any) :: any
end

function AnatomyHost.getSurfaces<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	query: AnatomyHostSurfaceQuery?
): { [TSurfaceName]: AnatomySurface<TSurfaceName> }
	local surfaces: { [TSurfaceName]: AnatomySurface<TSurfaceName> } = {}

	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return surfaces
		end

		return layer._instance:getSurfaces()
	end

	for name in collectSurfaceNames(self) do
		local surface = self:_resolveSurface(name, query)
		if surface == nil then
			continue
		end

		surfaces[name] = surface
	end

	return surfaces
end

function AnatomyHost.getSurface<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName,
	query: AnatomyHostSurfaceQuery?
): AnatomySurface<TSurfaceName>?
	assertSurfaceNameAllowed(self, name)
	return self:_resolveSurface(name, query)
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

function AnatomyHost.bindSurface<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName,
	callback: SurfaceChangedCallback<TSurfaceName>,
	runInitially: boolean?
): () -> ()
	assertSurfaceNameAllowed(self, name)

	local callbacks = self._surfaceCallbacks[name]
	if callbacks == nil then
		callbacks = CallbackSet.new()
		self._surfaceCallbacks[name] = callbacks
	end

	if runInitially == true then
		callback(self:_resolveSurface(name, nil))
	end

	return CallbackSet.bind(callbacks, callback)
end

function AnatomyHost.bindSurfaceAdded<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName,
	callback: SurfaceAddedCallback<TSocketName, TSurfaceName>,
	runInitially: boolean?
): () -> ()
	assertSurfaceNameAllowed(self, name)

	local callbacks = self._surfaceAddedCallbacks[name]
	if callbacks == nil then
		callbacks = CallbackSet.new()
		self._surfaceAddedCallbacks[name] = callbacks
	end

	if runInitially == true then
		for _, layer in self._layerOrder do
			local surface = layer._instance:getSurface(name)
			if surface ~= nil then
				callback(surface, layer)
			end
		end
	end

	return CallbackSet.bind(callbacks, callback)
end

function AnatomyHost.bindSurfaceRemoved<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName,
	callback: SurfaceRemovedCallback<TSocketName, TSurfaceName>
): () -> ()
	assertSurfaceNameAllowed(self, name)

	local callbacks = self._surfaceRemovedCallbacks[name]
	if callbacks == nil then
		callbacks = CallbackSet.new()
		self._surfaceRemovedCallbacks[name] = callbacks
	end

	return CallbackSet.bind(callbacks, callback)
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

function AnatomyHost._resolveSurface<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName,
	query: AnatomyHostSurfaceQuery?
): AnatomySurface<TSurfaceName>?
	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return nil
		end

		return layer._instance:getSurface(name)
	end

	local resolved: AnatomySurface<TSurfaceName>? = nil
	local includeOverrides = query == nil or query.includeOverrides ~= false

	for _, layer in self._layerOrder do
		local surface = layer._instance:getSurface(name)
		if surface == nil then
			continue
		end

		if resolved == nil then
			resolved = surface
			continue
		end

		if includeOverrides and layer._allowSocketOverrides then
			resolved = surface
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

function AnatomyHost._refreshSurface<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName
): ()
	local oldSurface = self._resolvedSurfaces[name]
	local newSurface = self:_resolveSurface(name, nil)
	if oldSurface == newSurface then
		return
	end

	self._resolvedSurfaces[name] = newSurface

	local callbacks = self._surfaceCallbacks[name]
	if callbacks ~= nil then
		CallbackSet.fire(callbacks, newSurface)
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

function AnatomyHost._refreshAllSurfaces<TSocketName, TSurfaceName>(
	self: AnatomyHostImpl<TSocketName, TSurfaceName>
): ()
	for name in collectSurfaceNames(self) do
		self:_refreshSurface(name)
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

	for _, callbacks in self._surfaceCallbacks do
		table.clear(callbacks)
	end
	table.clear(self._surfaceCallbacks)

	for _, callbacks in self._surfaceAddedCallbacks do
		table.clear(callbacks)
	end
	table.clear(self._surfaceAddedCallbacks)

	for _, callbacks in self._surfaceRemovedCallbacks do
		table.clear(callbacks)
	end
	table.clear(self._surfaceRemovedCallbacks)

	for _, layer in self._layerOrder do
		layer._destroyed = true
	end
	table.clear(self._layerOrder)
	table.clear(self._layers)
	table.clear(self._resolvedSockets)
	table.clear(self._resolvedSurfaces)
end


return {
	new = new,
}
