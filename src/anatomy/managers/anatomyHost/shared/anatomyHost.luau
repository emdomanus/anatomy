--!strict
--!optimize 2

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet.shared.callbackSet)
local SocketWatcher =
	require(script.Parent.Parent.Parent.Parent.components.socketWatcher.shared.socketWatcher)
local SocketMount =
	require(script.Parent.Parent.Parent.Parent.components.socketMount.shared.socketMount)
local HostTypes =
	require(script.Parent.Parent.Parent.Parent.types.managers.anatomyHost.shared.anatomyHost)
local SocketTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket.shared.anatomySocket)
local TaggedTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local MountTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.socketMount.shared.socketMount)
local WatcherTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.socketWatcher.shared.socketWatcher)

type Source<S, T> = HostTypes.AnatomySource<S, T>
type Host<S, T> = HostTypes.AnatomyHost<S, T>
type Impl<S, T> = HostTypes.AnatomyHostImpl<S, T>
type Registration<S, T> = HostTypes.Registration<S, T>
type Socket<S> = SocketTypes.AnatomySocket<S>
type Element<T> = TaggedTypes.AnatomyTaggedElement<T>

local weakKeys = table.freeze({ __mode = "k" })
-- Identity-only graph inspection does not depend on either source vocabulary.
-- Values borrow the host's source array; there is no second child collection.
local hostSources: { [unknown]: { unknown } } = setmetatable({}, weakKeys)

local function reaches(source: unknown, target: unknown): boolean
	if source == target then
		return true
	end
	local children = hostSources[source]
	if children then
		for _, child in children do
			if reaches(child, target) then
				return true
			end
		end
	end
	return false
end

local function disconnect<S, T>(registration: Registration<S, T>): ()
	registration.active = false
	if registration.disconnectSocketChanged then
		registration.disconnectSocketChanged()
	end
	if registration.disconnectTaggedAdded then
		registration.disconnectTaggedAdded()
	end
	if registration.disconnectTaggedRemoved then
		registration.disconnectTaggedRemoved()
	end
	registration.disconnectSocketChanged = nil
	registration.disconnectTaggedAdded = nil
	registration.disconnectTaggedRemoved = nil
end

local function sortSources<S, T>(
	sources: { Source<S, T> },
	registrations: { [Source<S, T>]: Registration<S, T> }
): ()
	table.sort(sources, function(left, right)
		local a, b = registrations[left], registrations[right]
		return if a.priority == b.priority then a.ordinal < b.ordinal else a.priority < b.priority
	end)
end

local AnatomyHost = {}
AnatomyHost.__index = AnatomyHost

local function new<S, T>(options: HostTypes.AnatomyHostOptions<S, T>): Host<S, T>
	local self: Impl<S, T> = setmetatable({}, AnatomyHost) :: Impl<S, T>
	self._socketNameGuard = options.socketNameGuard
	self._tagGuard = options.tagGuard
	self._registrations = {}
	self._sources = {}
	self._resolvedSockets = {}
	self._taggedElementCounts = {}
	self._socketChangedCallbacks = {}
	self._taggedAddedCallbacks = {}
	self._taggedRemovedCallbacks = {}
	self._socketWatchers = setmetatable({}, weakKeys)
	self._socketMounts = setmetatable({}, weakKeys)
	self._nextOrdinal = 1
	self._destroyed = false
	hostSources[self] = self._sources :: { unknown }
	return self
end

function AnatomyHost._refreshSocket<S, T>(self: Impl<S, T>, name: S): ()
	local selected: Socket<S>? = nil
	for index = #self._sources, 1, -1 do
		selected = self._registrations[self._sources[index]].socketsByName[name]
		if selected ~= nil then
			break
		end
	end
	if self._resolvedSockets[name] == selected then
		return
	end
	self._resolvedSockets[name] = selected
	for callback in self._socketChangedCallbacks do
		-- A callback may synchronously change the winner; never deliver stale state afterward.
		if self._resolvedSockets[name] ~= selected then
			break
		end
		callback(name, selected)
	end
end

function AnatomyHost.push<S, T>(self: Impl<S, T>, source: Source<S, T>, priority: number?): ()
	assert(not self._destroyed, "Cannot push to a destroyed AnatomyHost")
	assert(self._registrations[source] == nil, "AnatomySource is already registered")
	assert(not reaches(source, self), "AnatomyHost sources must not form a cycle")
	local registration: Registration<S, T> = {
		priority = priority or 0,
		ordinal = self._nextOrdinal,
		socketsByName = {},
		taggedElements = {},
		active = false,
	}
	-- Stage and validate initial membership before making the registration visible.
	-- On rejection release every subscription acquired so far.
	local ok, failure = pcall(function(): unknown
		registration.disconnectSocketChanged = source:bindSocketChanged(function(name, socket)
			assert(self._socketNameGuard(name) == name, "Invalid source socket name")
			registration.socketsByName[name] = socket
			if registration.active then
				self:_refreshSocket(name)
			end
		end, true)
		registration.disconnectTaggedAdded = source:bindTaggedAdded(function(element)
			for tag in element:getTags() do
				assert(self._tagGuard(tag) == tag, "Invalid source tag")
			end
			if registration.taggedElements[element] then
				return
			end
			registration.taggedElements[element] = true
			if registration.active then
				local count = self._taggedElementCounts[element] or 0
				self._taggedElementCounts[element] = count + 1
				if count == 0 then
					for callback in self._taggedAddedCallbacks do
						if self._taggedElementCounts[element] == nil then
							break
						end
						callback(element)
					end
				end
			end
		end, true)
		registration.disconnectTaggedRemoved = source:bindTaggedRemoved(function(element)
			if not registration.taggedElements[element] then
				return
			end
			registration.taggedElements[element] = nil
			if registration.active then
				local count = self._taggedElementCounts[element]
				self._taggedElementCounts[element] = if count == 1 then nil else count - 1
				if count == 1 then
					for callback in self._taggedRemovedCallbacks do
						if self._taggedElementCounts[element] ~= nil then
							break
						end
						callback(element)
					end
				end
			end
		end)
		assert(
			not self._destroyed and self._registrations[source] == nil,
			"Host changed during source registration"
		)
		assert(not reaches(source, self), "AnatomyHost sources must not form a cycle")
		return nil
	end)
	if not ok then
		disconnect(registration)
		error(failure, 0)
	end
	self._nextOrdinal += 1
	self._registrations[source] = registration
	table.insert(self._sources, source)
	sortSources(self._sources, self._registrations)
	registration.active = true
	local addedTaggedElements: { Element<T> } = {}
	for element in registration.taggedElements do
		local count = self._taggedElementCounts[element] or 0
		self._taggedElementCounts[element] = count + 1
		if count == 0 then
			table.insert(addedTaggedElements, element)
		end
	end
	for name in registration.socketsByName do
		if not registration.active then
			break
		end
		self:_refreshSocket(name)
	end
	for _, element in addedTaggedElements do
		if not registration.active then
			break
		end
		for callback in self._taggedAddedCallbacks do
			if self._taggedElementCounts[element] == nil then
				break
			end
			callback(element)
		end
	end
end

function AnatomyHost.remove<S, T>(self: Impl<S, T>, source: Source<S, T>): boolean
	local registration = self._registrations[source]
	if registration == nil then
		return false
	end
	disconnect(registration)
	self._registrations[source] = nil
	local index = table.find(self._sources, source)
	if index then
		table.remove(self._sources, index)
	end
	local removedTaggedElements: { Element<T> } = {}
	for element in registration.taggedElements do
		local count = self._taggedElementCounts[element]
		self._taggedElementCounts[element] = if count == 1 then nil else count - 1
		if count == 1 then
			table.insert(removedTaggedElements, element)
		end
	end
	for name in registration.socketsByName do
		self:_refreshSocket(name)
	end
	for _, element in removedTaggedElements do
		for callback in self._taggedRemovedCallbacks do
			if self._taggedElementCounts[element] ~= nil then
				break
			end
			callback(element)
		end
	end
	return true
end

function AnatomyHost.setPriority<S, T>(self: Impl<S, T>, source: Source<S, T>, priority: number): ()
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	local registration = assert(self._registrations[source], "AnatomySource is not registered")
	if registration.priority == priority then
		return
	end
	registration.priority = priority
	sortSources(self._sources, self._registrations)
	for name in registration.socketsByName do
		if not registration.active then
			break
		end
		self:_refreshSocket(name)
	end
end

function AnatomyHost.clear<S, T>(self: Impl<S, T>): ()
	-- Snapshot identity membership because removal callbacks can register other sources.
	for _, source in table.clone(self._sources) do
		self:remove(source)
	end
end

function AnatomyHost.getSocket<S, T>(self: Impl<S, T>, name: S): Socket<S>?
	return self._resolvedSockets[name]
end

function AnatomyHost.getTagged<S, T>(self: Impl<S, T>, prefix: string): { Element<T> }
	local result: { Element<T> } = {}
	for element in self._taggedElementCounts do
		if element:hasTag(prefix) then
			table.insert(result, element)
		end
	end
	return result
end

function AnatomyHost.bindSocketChanged<S, T>(
	self: Impl<S, T>,
	callback: (S, Socket<S>?) -> (),
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	local release = CallbackSet.bind(self._socketChangedCallbacks, callback)
	if runInitially then
		local ok, failure = pcall(function(): unknown
			for name, socket in self._resolvedSockets do
				callback(name, socket)
			end
			return nil
		end)
		if not ok then
			release()
			error(failure, 0)
		end
	end
	return release
end

function AnatomyHost.bindTaggedAdded<S, T>(
	self: Impl<S, T>,
	callback: (Element<T>) -> (),
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	local release = CallbackSet.bind(self._taggedAddedCallbacks, callback)
	if runInitially then
		local ok, failure = pcall(function(): unknown
			for element in self._taggedElementCounts do
				callback(element)
			end
			return nil
		end)
		if not ok then
			release()
			error(failure, 0)
		end
	end
	return release
end

function AnatomyHost.bindTaggedRemoved<S, T>(self: Impl<S, T>, callback: (Element<T>) -> ()): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	return CallbackSet.bind(self._taggedRemovedCallbacks, callback)
end

function AnatomyHost.watchSocket<S, T>(self: Impl<S, T>, name: S): WatcherTypes.SocketWatcher<S>
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	assert(self._socketNameGuard(name) == name, "Invalid socket name")
	local watcher = SocketWatcher.new(self, name)
	self._socketWatchers[watcher] = true
	return watcher
end

function AnatomyHost.mount<S, T>(
	self: Impl<S, T>,
	from: Attachment?,
	to: Attachment?,
	options: MountTypes.SocketMountOptions?
): MountTypes.SocketMount
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	local mount = SocketMount.new(from, to, options)
	self._socketMounts[mount] = true
	return mount
end

function AnatomyHost.deconstruct<S, T>(self: Impl<S, T>): ()
	if self._destroyed then
		return
	end
	self._destroyed = true
	for mount in self._socketMounts do
		mount:deconstruct()
	end
	for watcher in self._socketWatchers do
		watcher:deconstruct()
	end
	for _, registration in self._registrations do
		disconnect(registration)
	end
	table.clear(self._registrations)
	table.clear(self._sources)
	table.clear(self._resolvedSockets)
	table.clear(self._taggedElementCounts)
	table.clear(self._socketChangedCallbacks)
	table.clear(self._taggedAddedCallbacks)
	table.clear(self._taggedRemovedCallbacks)
	table.clear(self._socketWatchers)
	table.clear(self._socketMounts)
	hostSources[self] = nil
end

return { new = new }
