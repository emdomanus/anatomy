--!strict
--!optimize 2
--!native

local Hook = require(script.Parent.Parent.Parent.externalPackages.hook)
local SocketBinding = require(script.Parent.Parent.components.socketBinding)
local SocketEndpoint = require(script.Parent.Parent.components.socketEndpoint)
local SocketMount = require(script.Parent.Parent.components.socketMount)
local Types = require(script.Parent.Parent.types.managers.anatomyHost)

export type AnatomyHost = Types.AnatomyHost
export type AnatomyHostImpl = Types.AnatomyHostImpl
export type AnatomyHostLayer = Types.AnatomyHostLayer
export type AnatomyHostLayerImpl = Types.AnatomyHostLayerImpl
export type AnatomyHostLayerOptions = Types.AnatomyHostLayerOptions
export type AnatomyHostMountConfig = Types.AnatomyHostMountConfig
export type AnatomyHostMountEndpoint = Types.AnatomyHostMountEndpoint
export type AnatomyHostOptions = Types.AnatomyHostOptions
export type AnatomyHostSocketQuery = Types.AnatomyHostSocketQuery
export type AnatomyInstance = Types.AnatomyInstance
export type AnatomySocket = Types.AnatomySocket
export type LayerId = Types.LayerId
export type SocketBinding = Types.SocketBinding
export type SocketChangedCallback = Types.SocketChangedCallback
export type SocketEndpoint = Types.SocketEndpoint
export type SocketMount = Types.SocketMount
export type SocketName = Types.SocketName

local AnatomyHost = {}
AnatomyHost.__index = AnatomyHost

local AnatomyHostLayer = {}
AnatomyHostLayer.__index = AnatomyHostLayer

local function weakKeySet(): { [any]: true }
	return setmetatable({}, {
		__mode = "k",
	}) :: any
end

local function sortLayers(layerOrder: { AnatomyHostLayerImpl })
	table.sort(layerOrder, function(left, right)
		if left._priority == right._priority then
			return left._insertOrder < right._insertOrder
		end

		return left._priority < right._priority
	end)
end

local function collectSocketNames(self: AnatomyHostImpl): { [SocketName]: boolean }
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

local function makeSortedNameList(names: { [SocketName]: boolean }): { SocketName }
	local count = 0
	for _ in names do
		count += 1
	end

	local nameList = table.create(count)
	for name in names do
		table.insert(nameList, name)
	end

	table.sort(nameList)
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

function AnatomyHost.new(options: AnatomyHostOptions?): AnatomyHost
	local self: AnatomyHostImpl = setmetatable({}, AnatomyHost) :: any

	self._id = if options then options.id else nil
	self._layers = {}
	self._layerOrder = {}
	self._resolvedSockets = {}
	self._socketHooks = {}
	self._socketQueryHooks = {}
	self._bindings = weakKeySet() :: any
	self._mounts = weakKeySet() :: any
	self._nextLayerOrdinal = 1
	self._nextSocketQueryBindId = 1
	self._destroyed = false

	return self
end

function AnatomyHostLayer.getInstance(self: AnatomyHostLayerImpl): AnatomyInstance
	return self._instance
end

function AnatomyHostLayer.getPriority(self: AnatomyHostLayerImpl): number
	return self._priority
end

function AnatomyHostLayer.setPriority(self: AnatomyHostLayerImpl, priority: number): ()
	if self._destroyed or self._priority == priority then
		return
	end

	self._priority = priority
	sortLayers(self._host._layerOrder)
	self._host:_refreshAllSockets()
end

function AnatomyHostLayer.remove(self: AnatomyHostLayerImpl): ()
	if self._destroyed then
		return
	end

	self._host:remove(self.id)
end

function AnatomyHost.push(
	self: AnatomyHostImpl,
	instance: AnatomyInstance,
	options: AnatomyHostLayerOptions?
): AnatomyHostLayer
	local layerId = if options and options.id then options.id else `layer_{self._nextLayerOrdinal}`
	if self._layers[layerId] ~= nil then
		error(`AnatomyHost layer "{layerId}" already exists`, 2)
	end

	local insertOrder = self._nextLayerOrdinal
	self._nextLayerOrdinal += 1

	local layer: AnatomyHostLayerImpl = setmetatable({}, AnatomyHostLayer) :: any
	layer.id = layerId
	layer._host = self
	layer._instance = instance
	layer._priority = if options and options.priority ~= nil then options.priority else 0
	layer._category = if options and options.category ~= nil then options.category else instance:getCategory()
	layer._allowSocketOverrides = if options and options.allowSocketOverrides ~= nil
		then options.allowSocketOverrides
		else true
	layer._insertOrder = insertOrder
	layer._destroyed = false

	self._layers[layerId] = layer
	table.insert(self._layerOrder, layer)
	sortLayers(self._layerOrder)
	self:_refreshAllSockets()

	return layer
end

function AnatomyHost.remove(self: AnatomyHostImpl, layerId: LayerId): boolean
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
	return true
end

function AnatomyHost.clear(self: AnatomyHostImpl): ()
	local layerIds = {}
	for layerId in self._layers do
		table.insert(layerIds, layerId)
	end

	for _, layerId in layerIds do
		self:remove(layerId)
	end
end

function AnatomyHost.getLayer(self: AnatomyHostImpl, layerId: LayerId): AnatomyHostLayer?
	return self._layers[layerId]
end

function AnatomyHost.getLayers(self: AnatomyHostImpl): { AnatomyHostLayer }
	return table.clone(self._layerOrder) :: any
end

function AnatomyHost.getSocketNames(
	self: AnatomyHostImpl,
	query: AnatomyHostSocketQuery?
): { SocketName }
	local names: { [SocketName]: boolean } = {}

	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return {}
		end

		for name in layer._instance:getSockets() do
			names[name] = true
		end

		return makeSortedNameList(names)
	end

	for name in collectSocketNames(self) do
		if self:_resolveSocket(name, query) ~= nil then
			names[name] = true
		end
	end

	return makeSortedNameList(names)
end

function AnatomyHost.getSockets(
	self: AnatomyHostImpl,
	query: AnatomyHostSocketQuery?
): { [SocketName]: AnatomySocket }
	local sockets: { [SocketName]: AnatomySocket } = {}

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

function AnatomyHost.getSocket(
	self: AnatomyHostImpl,
	name: SocketName,
	query: AnatomyHostSocketQuery?
): AnatomySocket?
	return self:_resolveSocket(name, query)
end

function AnatomyHost.bindSocket(
	self: AnatomyHostImpl,
	name: SocketName,
	callback: SocketChangedCallback,
	runInitially: boolean?
): number
	local hook = self._socketHooks[name]
	if hook == nil then
		hook = Hook.new()
		self._socketHooks[name] = hook
	end

	if runInitially == true then
		callback(self:_resolveSocket(name, nil))
	end

	return hook:add(callback)
end

function AnatomyHost.unbindSocket(self: AnatomyHostImpl, name: SocketName, hookId: number): boolean
	local hook = self._socketHooks[name]
	if hook == nil then
		return false
	end

	return hook:remove(hookId)
end

local function bindSocketQuery(
	host: AnatomyHostImpl,
	name: SocketName,
	query: AnatomyHostSocketQuery?,
	callback: SocketChangedCallback,
	runInitially: boolean?
): number
	if query == nil then
		return host:bindSocket(name, callback, runInitially)
	end

	local id = host._nextSocketQueryBindId
	host._nextSocketQueryBindId += 1

	local current = host:_resolveSocket(name, query)
	local entry = {
		name = name,
		query = copyQuery(query),
		hook = Hook.new(),
		current = current,
	}
	host._socketQueryHooks[id] = entry

	if runInitially == true then
		callback(current)
	end

	entry.hook:add(callback)
	return id
end

local function unbindSocketQuery(
	host: AnatomyHostImpl,
	name: SocketName,
	query: AnatomyHostSocketQuery?,
	hookId: number
): boolean
	if query == nil then
		return host:unbindSocket(name, hookId)
	end

	local entry = host._socketQueryHooks[hookId]
	if entry == nil then
		return false
	end

	entry.hook:deconstruct()
	host._socketQueryHooks[hookId] = nil
	return true
end

function AnatomyHost.socket(
	self: AnatomyHostImpl,
	name: SocketName,
	query: AnatomyHostSocketQuery?
): SocketBinding
	local queryCopy = copyQuery(query)
	local source = {
		bindSocket = function(_source, socketName, callback, runInitially)
			return bindSocketQuery(self, socketName, queryCopy, callback, runInitially)
		end,
		unbindSocket = function(_source, socketName, hookId)
			return unbindSocketQuery(self, socketName, queryCopy, hookId)
		end,
	}

	local binding = SocketBinding.new(name, source, nil) :: any
	self._bindings[binding] = true

	return binding
end

function AnatomyHost.mount(self: AnatomyHostImpl, config: AnatomyHostMountConfig): SocketMount
	local mount = SocketMount.new(
		self:_normalizeEndpoint(config.from),
		self:_normalizeEndpoint(config.to),
		config.options
	) :: any
	self._mounts[mount] = true

	return mount
end

function AnatomyHost._resolveSocket(
	self: AnatomyHostImpl,
	name: SocketName,
	query: AnatomyHostSocketQuery?
): AnatomySocket?
	if query ~= nil and query.layerId ~= nil then
		local layer = self._layers[query.layerId]
		if layer == nil then
			return nil
		end

		return layer._instance:getSocket(name)
	end

	local resolved: AnatomySocket? = nil
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

function AnatomyHost._refreshSocket(self: AnatomyHostImpl, name: SocketName): ()
	local oldSocket = self._resolvedSockets[name]
	local newSocket = self:_resolveSocket(name, nil)
	if oldSocket == newSocket then
		return
	end

	self._resolvedSockets[name] = newSocket

	local hook = self._socketHooks[name]
	if hook ~= nil then
		hook:fire(newSocket)
	end
end

function AnatomyHost._refreshAllSockets(self: AnatomyHostImpl): ()
	for name in collectSocketNames(self) do
		self:_refreshSocket(name)
	end

	for _, entry in self._socketQueryHooks do
		local current = self:_resolveSocket(entry.name, entry.query)
		if entry.current ~= current then
			entry.current = current
			entry.hook:fire(current)
		end
	end
end

function AnatomyHost._normalizeEndpoint(
	self: AnatomyHostImpl,
	endpoint: AnatomyHostMountEndpoint
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
			local socket = endpointValue.instance:getSocket(endpointValue.socket)
			if socket == nil then
				error(`Anatomy instance socket "{endpointValue.socket}" could not be resolved`, 2)
			end

			return socket :: any
		end

		if endpointValue.socket ~= nil then
			return self:socket(endpointValue.socket, endpointValue)
		end
	end

	error("Invalid anatomy socket mount endpoint", 2)
end

function AnatomyHost.deconstruct(self: AnatomyHostImpl): ()
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

	for _, entry in self._socketQueryHooks do
		entry.hook:deconstruct()
	end
	table.clear(self._socketQueryHooks)

	for _, hook in self._socketHooks do
		hook:deconstruct()
	end
	table.clear(self._socketHooks)

	for _, layer in self._layerOrder do
		layer._destroyed = true
	end
	table.clear(self._layerOrder)
	table.clear(self._layers)
	table.clear(self._resolvedSockets)
end

return AnatomyHost
