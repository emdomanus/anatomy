--!strict
--!optimize 2

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet.shared.callbackSet)
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

type Source<S, T> = HostTypes.AnatomySource<S, T>
type Host<S, T> = HostTypes.AnatomyHost<S, T>
type Impl<S, T> = HostTypes.AnatomyHostImpl<S, T>
type TaggedSelection<S, T> = HostTypes.TaggedSelection<S, T>
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

local function disconnectTaggedSource<S, T>(self: Impl<S, T>, source: Source<S, T>): ()
	for _, selection in self._taggedSelections do
		local release = selection.disconnects[source]
		if release then
			selection.disconnects[source] = nil
			release()
		end
	end
end

local function connectTaggedSource<S, T>(
	self: Impl<S, T>,
	prefix: string,
	selection: TaggedSelection<S, T>,
	source: Source<S, T>,
	registration: Registration<S, T>
): ()
	selection.disconnects[source] = source:bindTopTaggedChanged(prefix, function()
		if registration.active and self._taggedSelections[prefix] == selection then
			self:_refreshTopTagged(prefix)
		end
	end)
end

local function refreshTaggedSource<S, T>(self: Impl<S, T>, registration: Registration<S, T>): ()
	for prefix in self._taggedSelections do
		for element in registration.taggedElements do
			if element:hasTag(prefix) then
				self:_refreshTopTagged(prefix)
				break
			end
		end
	end
end

local function resolveTopTagged<S, T>(self: Impl<S, T>, prefix: string): Element<T>?
	for index = #self._sources, 1, -1 do
		local selected = self._sources[index]:getTopTagged(prefix)
		if selected ~= nil then
			return selected
		end
	end
	return nil
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
	self._socketCallbacksByName = {}
	self._taggedSelections = {}
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
	local callbacks = self._socketCallbacksByName[name]
	if callbacks then
		for callback in callbacks do
			if self._resolvedSockets[name] ~= selected then
				break
			end
			callback(selected)
		end
	end
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
		for prefix, selection in self._taggedSelections do
			connectTaggedSource(self, prefix, selection, source, registration)
		end
		assert(
			not self._destroyed and self._registrations[source] == nil,
			"Host changed during source registration"
		)
		assert(not reaches(source, self), "AnatomyHost sources must not form a cycle")
		return nil
	end)
	if not ok then
		disconnectTaggedSource(self, source)
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
	if registration.active then
		refreshTaggedSource(self, registration)
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
	disconnectTaggedSource(self, source)
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
	refreshTaggedSource(self, registration)
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
	refreshTaggedSource(self, registration)
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
	local seen: { [Element<T>]: true } = {}
	-- Keep the highest-precedence occurrence of a shared element, then reverse.
	for index = #self._sources, 1, -1 do
		local elements = self._sources[index]:getTagged(prefix)
		for elementIndex = #elements, 1, -1 do
			local element = elements[elementIndex]
			if not seen[element] then
				seen[element] = true
				table.insert(result, element)
			end
		end
	end
	for index = 1, math.floor(#result / 2) do
		local opposite = #result - index + 1
		result[index], result[opposite] = result[opposite], result[index]
	end
	return result
end

function AnatomyHost.getTopTagged<S, T>(self: Impl<S, T>, prefix: string): Element<T>?
	local selection = self._taggedSelections[prefix]
	return if selection then selection.current else resolveTopTagged(self, prefix)
end

function AnatomyHost._refreshTopTagged<S, T>(self: Impl<S, T>, prefix: string): ()
	local selection = self._taggedSelections[prefix]
	if selection == nil then
		return
	end
	local selected = resolveTopTagged(self, prefix)
	if selection.current == selected then
		return
	end
	selection.current = selected
	for callback in selection.callbacks do
		if self._taggedSelections[prefix] ~= selection or selection.current ~= selected then
			break
		end
		callback(selected)
	end
end

function AnatomyHost.bindTopTaggedChanged<S, T>(
	self: Impl<S, T>,
	prefix: string,
	callback: (Element<T>?) -> (),
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	local selection = self._taggedSelections[prefix]
	if selection == nil then
		selection = { current = self:getTopTagged(prefix), callbacks = {}, disconnects = {} }
		self._taggedSelections[prefix] = selection
		local created: TaggedSelection<S, T> = selection
		local ok, failure = pcall(function(): unknown
			for _, source in self._sources do
				connectTaggedSource(self, prefix, created, source, self._registrations[source])
			end
			return nil
		end)
		if not ok then
			self._taggedSelections[prefix] = nil
			for _, disconnectSource in selection.disconnects do
				disconnectSource()
			end
			error(failure, 0)
		end
	end
	local retained = selection
	local disconnectCallback = CallbackSet.bind(retained.callbacks, callback)
	local function release(): ()
		disconnectCallback()
		if next(retained.callbacks) == nil and self._taggedSelections[prefix] == retained then
			self._taggedSelections[prefix] = nil
			for _, disconnectSource in retained.disconnects do
				disconnectSource()
			end
			table.clear(retained.disconnects)
			retained.current = nil
		end
	end
	if runInitially then
		local ok, failure = pcall(function(): unknown
			callback(retained.current)
			return nil
		end)
		if not ok then
			release()
			error(failure, 0)
		end
	end
	return release
end

function AnatomyHost.bindToSocket<S, T>(
	self: Impl<S, T>,
	name: S,
	callback: (Socket<S>?) -> (),
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	assert(self._socketNameGuard(name) == name, "Invalid socket name")
	local callbacks = self._socketCallbacksByName[name]
	if callbacks == nil then
		callbacks = {}
		self._socketCallbacksByName[name] = callbacks
	end
	local retained = callbacks
	local disconnectCallback = CallbackSet.bind(retained, callback)
	local function release(): ()
		disconnectCallback()
		if next(retained) == nil and self._socketCallbacksByName[name] == retained then
			self._socketCallbacksByName[name] = nil
		end
	end
	if runInitially then
		local ok, failure = pcall(function(): unknown
			callback(self:getSocket(name))
			return nil
		end)
		if not ok then
			release()
			error(failure, 0)
		end
	end
	return release
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
	self:clear()
	for mount in self._socketMounts do
		mount:deconstruct()
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
	for _, selection in self._taggedSelections do
		for _, release in selection.disconnects do
			release()
		end
		table.clear(selection.disconnects)
		table.clear(selection.callbacks)
	end
	for _, callbacks in self._socketCallbacksByName do
		table.clear(callbacks)
	end
	table.clear(self._socketCallbacksByName)
	table.clear(self._taggedSelections)
	table.clear(self._socketMounts)
	hostSources[self] = nil
end

return { new = new }
