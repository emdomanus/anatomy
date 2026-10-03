--!strict
--!optimize 2

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet.shared.callbackSet)
local AnatomyHostLayer =
	require(script.Parent.Parent.Parent.Parent.components.anatomyHostLayer.shared.anatomyHostLayer)
local SocketWatcher =
	require(script.Parent.Parent.Parent.Parent.components.socketWatcher.shared.socketWatcher)
local SocketMount =
	require(script.Parent.Parent.Parent.Parent.components.socketMount.shared.socketMount)
local AnatomyInstanceTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyInstance.shared.anatomyInstance
)
local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local AnatomyTemplateTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate.shared.anatomyTemplate
)
local SocketWatcherTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.socketWatcher.shared.socketWatcher)
local AnatomyHostTypes =
	require(script.Parent.Parent.Parent.Parent.types.managers.anatomyHost.shared.anatomyHost)
local AnatomyHostLayerTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyHostLayer.shared.anatomyHostLayer
)

type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>

type AnatomyHost<SocketT, TagT> = AnatomyHostTypes.AnatomyHost<SocketT, TagT>
type AnatomyHostImpl<SocketT, TagT> = AnatomyHostTypes.AnatomyHostImpl<SocketT, TagT>
type AnatomyHostLayer<SocketT, TagT> = AnatomyHostTypes.AnatomyHostLayer<SocketT, TagT>
type AnatomyHostLayerOwned<SocketT, TagT> = AnatomyHostLayerTypes.AnatomyHostLayerOwned<
	SocketT,
	TagT
>
type AnatomyHostLayerOptions = AnatomyHostTypes.AnatomyHostLayerOptions
type AnatomyHostOptions<SocketT, TagT> = AnatomyHostTypes.AnatomyHostOptions<SocketT, TagT>
type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type LayerId = AnatomyHostTypes.LayerId
type SocketWatcher<SocketT> = SocketWatcherTypes.SocketWatcher<SocketT>
type SocketChangedCallback<SocketT> = AnatomyHostTypes.SocketChangedCallback<SocketT>
type SocketMountOptions = AnatomyHostTypes.SocketMountOptions
type SocketMount = AnatomyHostTypes.SocketMount
type TagChangedCallback<TagT> = AnatomyHostTypes.TagChangedCallback<TagT>

local function sortHostLayers<SocketT, TagT>(layerOrder: { AnatomyHostLayerOwned<SocketT, TagT> }): ()
	table.sort(
		layerOrder,
		function(
			left: AnatomyHostLayerOwned<SocketT, TagT>,
			right: AnatomyHostLayerOwned<SocketT, TagT>
		)
			if left:getPriority() == right:getPriority() then
				return left:getRegistration() < right:getRegistration()
			end

			return left:getPriority() < right:getPriority()
		end
	)
end

local function collectSocketNames<SocketT, TagT>(
	resolvedSockets: { [SocketT]: AnatomySocket<SocketT>? },
	layerOrder: { AnatomyHostLayerOwned<SocketT, TagT> }
): { [SocketT]: boolean }
	local names = {}

	for name in resolvedSockets do
		names[name] = true
	end

	local function addName(name: SocketT)
		names[name] = true
	end
	for _, layer in layerOrder do
		layer:getInstance():forEachSocket(addName)
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

	table.sort(nameList, function(left: TName, right: TName): boolean
		return (left :: string) < (right :: string)
	end)
	return nameList
end

local function isCallbackSetEmpty<T>(callbacks: { [T]: true }): boolean
	for _ in callbacks do
		return false
	end

	return true
end

local function areTagCallbacksEmpty<TagT>(callbacks: {
	added: { [TagChangedCallback<TagT>]: true },
	removed: { [TagChangedCallback<TagT>]: true },
}): boolean
	return isCallbackSetEmpty(callbacks.added) and isCallbackSetEmpty(callbacks.removed)
end

local function collectTaggedElements<SocketT, TagT>(
	layerOrder: { AnatomyHostLayerOwned<SocketT, TagT> },
	layers: {
		[LayerId]: AnatomyHostLayerOwned<SocketT, TagT>,
	},
	prefix: string,
	layerId: LayerId?
): { AnatomyTaggedElement<TagT> }
	if layerId ~= nil then
		local layer = layers[layerId]
		if layer == nil then
			return {}
		end

		return layer:getInstance():getByTag(prefix)
	end

	local elements: { AnatomyTaggedElement<TagT> } = {}
	local function append(element: AnatomyTaggedElement<TagT>)
		table.insert(elements, element)
	end
	for _, layer in layerOrder do
		layer:getInstance():forEachByTag(prefix, append)
	end

	return elements
end

local function collectTaggedElementSet<SocketT, TagT>(
	layerOrder: { AnatomyHostLayerOwned<SocketT, TagT> },
	prefix: string
): { [AnatomyTaggedElement<TagT>]: true }
	local set: { [AnatomyTaggedElement<TagT>]: true } = {}
	local function add(element: AnatomyTaggedElement<TagT>)
		set[element] = true
	end
	for _, layer in layerOrder do
		layer:getInstance():forEachByTag(prefix, add)
	end

	return set
end

local function tagSetToList<TagT>(
	set: { [AnatomyTaggedElement<TagT>]: true }
): { AnatomyTaggedElement<TagT> }
	local elements = {}

	for element in set do
		table.insert(elements, element)
	end

	return elements
end

local function assertSocketNameAllowed<SocketT>(
	guard: AnatomyHostTypes.NameGuard<SocketT>,
	name: SocketT
): ()
	if guard(name) ~= name then
		error(`Anatomy socket name "{name}" is not allowed by this host`, 3)
	end
end

local weakKeys = table.freeze({ __mode = "k" })

local AnatomyHost = {}
AnatomyHost.__index = AnatomyHost

local function new<SocketT, TagT>(options: AnatomyHostOptions<SocketT, TagT>): AnatomyHost<SocketT, TagT>
	local self: AnatomyHostImpl<SocketT, TagT> =
		setmetatable({}, AnatomyHost) :: AnatomyHostImpl<SocketT, TagT>

	self._id = options.id
	self._socketNameGuard = options.socketNameGuard
	self._tagGuard = options.tagGuard
	self._layers = {}
	self._layerOrder = {}
	self._resolvedSockets = {}
	self._socketCallbacks = {}
	self._socketQueryCallbacks = {}
	self._tagPrefixCallbacks = {}
	self._resolvedByPrefix = {}
	self._watchers = setmetatable({}, weakKeys)
	self._mounts = setmetatable({}, weakKeys)
	self._nextLayerOrdinal = 1
	self._destroyed = false

	return self
end

function AnatomyHost.push<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	instance: AnatomyInstance<SocketT, TagT>,
	options: AnatomyHostLayerOptions?
): AnatomyHostLayer<SocketT, TagT>
	assert(not self._destroyed, "Cannot push to a destroyed AnatomyHost")
	local layerId = if options and options.id then options.id else `layer_{self._nextLayerOrdinal}`
	if self._layers[layerId] ~= nil then
		error(`AnatomyHost layer "{layerId}" already exists`, 2)
	end

	local insertOrder = self._nextLayerOrdinal

	instance:forEachSocket(function(name)
		assertSocketNameAllowed(self._socketNameGuard, name)
	end)
	local function validateTag(tag: TagT)
		assert(self._tagGuard(tag) == tag, "Tag guards must preserve identity")
	end
	instance:forEachTaggedElement(function(element)
		element:forEachTag(validateTag)
	end)

	local layer = AnatomyHostLayer.new(
		self,
		layerId,
		instance,
		if options and options.priority ~= nil then options.priority else 0,
		if options and options.category ~= nil then options.category else instance:getCategory(),
		if options and options.allowSocketOverrides ~= nil
			then options.allowSocketOverrides
			else true,
		insertOrder
	)

	self._nextLayerOrdinal += 1
	self._layers[layerId] = layer
	table.insert(self._layerOrder, layer)
	sortHostLayers(self._layerOrder)

	self:_refreshAllSockets()
	self:_refreshAllWatchedPrefixes()

	return layer
end

function AnatomyHost.setLayerPriority<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	layerId: LayerId,
	registration: number,
	priority: number
): ()
	local layer = self._layers[layerId]
	assert(layer ~= nil and layer:getRegistration() == registration, "Retired anatomy layer")
	if layer:getPriority() == priority then
		return
	end
	layer:applyPriority(priority)
	sortHostLayers(self._layerOrder)
	self:_refreshAllSockets()
	self:_refreshAllWatchedPrefixes()
end

function AnatomyHost.removeLayer<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	layerId: LayerId,
	registration: number
): ()
	local layer = self._layers[layerId]
	assert(layer ~= nil and layer:getRegistration() == registration, "Retired anatomy layer")
	self:remove(layerId)
end

function AnatomyHost.remove<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>, layerId: LayerId): boolean
	local layer = self._layers[layerId]
	if layer == nil then
		return false
	end

	layer:deconstruct()
	self._layers[layerId] = nil

	local index = table.find(self._layerOrder, layer)
	if index ~= nil then
		table.remove(self._layerOrder, index)
	end

	self:_refreshAllSockets()
	self:_refreshAllWatchedPrefixes()
	return true
end

function AnatomyHost.clear<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>): ()
	local layerIds = {}
	for layerId in self._layers do
		table.insert(layerIds, layerId)
	end

	for _, layerId in layerIds do
		self:remove(layerId)
	end
end

function AnatomyHost.getLayer<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	layerId: LayerId
): AnatomyHostLayer<SocketT, TagT>?
	return self._layers[layerId]
end

function AnatomyHost.getLayers<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>
): { AnatomyHostLayer<SocketT, TagT> }
	local layers: { AnatomyHostLayer<SocketT, TagT> } = {}
	for _, layer in self._layerOrder do
		table.insert(layers, layer)
	end
	return layers
end

function AnatomyHost.getSocketNames<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	layerId: LayerId?,
	includeOverrides: boolean?
): { SocketT }
	local names: { [SocketT]: boolean } = {}

	if layerId ~= nil then
		local layer = self._layers[layerId]
		if layer == nil then
			return {}
		end

		layer:getInstance():forEachSocket(function(name)
			names[name] = true
		end)

		return makeSortedNameList(names)
	end

	for name in collectSocketNames(self._resolvedSockets, self._layerOrder) do
		if self:_resolveSocket(name, layerId, includeOverrides) ~= nil then
			names[name] = true
		end
	end

	return makeSortedNameList(names)
end

function AnatomyHost.getSockets<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	layerId: LayerId?,
	includeOverrides: boolean?
): { [SocketT]: AnatomySocket<SocketT> }
	local sockets: { [SocketT]: AnatomySocket<SocketT> } = {}

	if layerId ~= nil then
		local layer = self._layers[layerId]
		if layer == nil then
			return sockets
		end

		return layer:getInstance():getSockets()
	end

	for name in collectSocketNames(self._resolvedSockets, self._layerOrder) do
		local socket = self:_resolveSocket(name, layerId, includeOverrides)
		if socket == nil then
			continue
		end

		sockets[name] = socket
	end

	return sockets
end

function AnatomyHost.getSocket<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	name: SocketT,
	layerId: LayerId?,
	includeOverrides: boolean?
): AnatomySocket<SocketT>?
	assertSocketNameAllowed(self._socketNameGuard, name)
	return self:_resolveSocket(name, layerId, includeOverrides)
end

function AnatomyHost.bindSocket<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	name: SocketT,
	callback: SocketChangedCallback<SocketT>,
	runInitially: boolean?,
	layerId: LayerId?,
	includeOverrides: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	assertSocketNameAllowed(self._socketNameGuard, name)

	if layerId ~= nil or includeOverrides == false then
		local current = self:_resolveSocket(name, layerId, includeOverrides)
		local entry = {
			name = name,
			layerId = layerId,
			includeOverrides = includeOverrides,
			callback = callback,
			current = current,
		}
		self._socketQueryCallbacks[entry] = true
		if runInitially == true then
			callback(current)
		end
		return function()
			self._socketQueryCallbacks[entry] = nil
		end
	end

	local callbacks = self._socketCallbacks[name]
	if callbacks == nil then
		callbacks = {}
		self._socketCallbacks[name] = callbacks
	end

	if runInitially == true then
		callback(self:_resolveSocket(name, nil, nil))
	end

	return CallbackSet.bind(callbacks, callback)
end

function AnatomyHost.getFirstByTag<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string,
	layerId: LayerId?
): AnatomyTaggedElement<TagT>?
	if layerId ~= nil then
		local layer = self._layers[layerId]
		return if layer then layer:getInstance():getFirstByTag(prefix) else nil
	end
	local resolved = self._resolvedByPrefix[prefix]
	if resolved ~= nil then
		for element in resolved do
			return element
		end
		return nil
	end
	for _, layer in self._layerOrder do
		local element = layer:getInstance():getFirstByTag(prefix)
		if element ~= nil then
			return element
		end
	end
	return nil
end

function AnatomyHost.getLastByTag<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string,
	layerId: LayerId?
): AnatomyTaggedElement<TagT>?
	if layerId ~= nil then
		local layer = self._layers[layerId]
		return if layer then layer:getInstance():getLastByTag(prefix) else nil
	end
	local resolved = self._resolvedByPrefix[prefix]
	if resolved ~= nil then
		local last: AnatomyTaggedElement<TagT>? = nil
		for element in resolved do
			last = element
		end
		return last
	end
	for index = #self._layerOrder, 1, -1 do
		local layer = self._layerOrder[index]
		local element = layer:getInstance():getLastByTag(prefix)
		if element ~= nil then
			return element
		end
	end
	return nil
end

function AnatomyHost.getByTag<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string,
	layerId: LayerId?
): { AnatomyTaggedElement<TagT> }
	local resolved = if layerId == nil then self._resolvedByPrefix[prefix] else nil
	if resolved ~= nil then
		return tagSetToList(resolved)
	end

	return collectTaggedElements(self._layerOrder, self._layers, prefix, layerId)
end

function AnatomyHost.bindByTag<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string,
	onAdded: TagChangedCallback<TagT>,
	onRemoved: TagChangedCallback<TagT>,
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	local callbacks = self._tagPrefixCallbacks[prefix]
	if callbacks == nil then
		callbacks = {
			added = {},
			removed = {},
		}
		self._tagPrefixCallbacks[prefix] = callbacks
		self._resolvedByPrefix[prefix] = collectTaggedElementSet(self._layerOrder, prefix)
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

function AnatomyHost.watchSocket<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	name: SocketT,
	layerId: LayerId?,
	includeOverrides: boolean?
): SocketWatcher<SocketT>
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	local watcher = SocketWatcher.new(self, name, layerId, includeOverrides)
	self._watchers[watcher] = true
	return watcher
end

function AnatomyHost.mount<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	from: Attachment?,
	to: Attachment?,
	options: SocketMountOptions?
): SocketMount
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	local mount = SocketMount.new(from, to, options)
	self._mounts[mount] = true
	return mount
end

function AnatomyHost._resolveSocket<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	name: SocketT,
	layerId: LayerId?,
	includeOverrides: boolean?
): AnatomySocket<SocketT>?
	if layerId ~= nil then
		local layer = self._layers[layerId]
		if layer == nil then
			return nil
		end

		return layer:getInstance():getSocket(name)
	end

	local resolved: AnatomySocket<SocketT>? = nil
	local useOverrides = includeOverrides ~= false

	for _, layer in self._layerOrder do
		local socket = layer:getInstance():getSocket(name)
		if socket == nil then
			continue
		end

		if resolved == nil then
			resolved = socket
			continue
		end

		if useOverrides and layer:allowsSocketOverrides() then
			resolved = socket
		end
	end

	return resolved
end

function AnatomyHost._refreshSocket<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>, name: SocketT): ()
	local oldSocket = self._resolvedSockets[name]
	local newSocket = self:_resolveSocket(name, nil, nil)
	if oldSocket == newSocket then
		return
	end

	self._resolvedSockets[name] = newSocket

	local callbacks = self._socketCallbacks[name]
	if callbacks ~= nil then
		CallbackSet.fire(callbacks, newSocket)
	end
end

function AnatomyHost._refreshAllSockets<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>): ()
	for name in collectSocketNames(self._resolvedSockets, self._layerOrder) do
		self:_refreshSocket(name)
	end

	for entry in self._socketQueryCallbacks do
		local current = self:_resolveSocket(entry.name, entry.layerId, entry.includeOverrides)
		if entry.current ~= current then
			entry.current = current
			entry.callback(current)
		end
	end
end

function AnatomyHost._refreshTagPrefix<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>, prefix: string): ()
	local oldSet = self._resolvedByPrefix[prefix]
	if oldSet == nil then
		return
	end

	local newSet = collectTaggedElementSet(self._layerOrder, prefix)
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

function AnatomyHost._refreshAllWatchedPrefixes<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>): ()
	for prefix in self._tagPrefixCallbacks do
		self:_refreshTagPrefix(prefix)
	end
end

function AnatomyHost.deconstruct<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	for mount in self._mounts do
		mount:deconstruct()
	end
	table.clear(self._mounts)

	for watcher in self._watchers do
		watcher:deconstruct()
	end
	table.clear(self._watchers)

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
		layer:deconstruct()
	end
	table.clear(self._layerOrder)
	table.clear(self._layers)
	table.clear(self._resolvedSockets)
	table.clear(self._resolvedByPrefix)
end

return {
	new = new,
}
