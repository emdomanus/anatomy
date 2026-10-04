--!strict
--!optimize 2

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet.shared.callbackSet)
local SocketMount =
	require(script.Parent.Parent.Parent.Parent.components.socketMount.shared.socketMount)
local AnatomySourceTypes = require(
	script.Parent.Parent.Parent.Parent.types.ports.components.anatomySource.shared.anatomySource
)
local AnatomyHostTypes =
	require(script.Parent.Parent.Parent.Parent.types.managers.anatomyHost.shared.anatomyHost)
local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local SocketMountTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.socketMount.shared.socketMount)

type AnatomySource<SocketT, TagT> = AnatomySourceTypes.AnatomySource<SocketT, TagT>
type AnatomyHostOptions<SocketT, TagT> = AnatomyHostTypes.AnatomyHostOptions<SocketT, TagT>
type SocketMount = SocketMountTypes.SocketMount
type SocketMountOptions = SocketMountTypes.SocketMountOptions
type AnatomyHost<SocketT, TagT> = AnatomyHostTypes.AnatomyHost<SocketT, TagT>
type AnatomyHostImpl<SocketT, TagT> = AnatomyHostTypes.AnatomyHostImpl<SocketT, TagT>
type AnatomyHostTaggedSelection<SocketT, TagT> = AnatomyHostTypes.AnatomyHostTaggedSelection<
	SocketT,
	TagT
>
type AnatomyHostRegistration<SocketT, TagT> = AnatomyHostTypes.AnatomyHostRegistration<
	SocketT,
	TagT
>
type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>

local weakKeys = table.freeze({ __mode = "k" })
-- Identity-only graph inspection does not depend on either source vocabulary.
-- Values borrow the host's source array; there is no second child collection.
local hostSources: { [unknown]: { unknown } } = setmetatable({}, weakKeys)

local function reaches(anatomySource: unknown, target: unknown): boolean
	if anatomySource == target then
		return true
	end
	local children = hostSources[anatomySource]
	if children then
		for _, child in children do
			if reaches(child, target) then
				return true
			end
		end
	end
	return false
end

local function disconnect<SocketT, TagT>(anatomyHostRegistration: AnatomyHostRegistration<SocketT, TagT>): ()
	anatomyHostRegistration.active = false
	if anatomyHostRegistration.disconnectSocketChanged then
		anatomyHostRegistration.disconnectSocketChanged()
	end
	if anatomyHostRegistration.disconnectTaggedAdded then
		anatomyHostRegistration.disconnectTaggedAdded()
	end
	if anatomyHostRegistration.disconnectTaggedRemoved then
		anatomyHostRegistration.disconnectTaggedRemoved()
	end
	anatomyHostRegistration.disconnectSocketChanged = nil
	anatomyHostRegistration.disconnectTaggedAdded = nil
	anatomyHostRegistration.disconnectTaggedRemoved = nil
end

local function sortSources<SocketT, TagT>(
	anatomySources: { AnatomySource<SocketT, TagT> },
	anatomyHostRegistrations: {
		[AnatomySource<SocketT, TagT>]: AnatomyHostRegistration<SocketT, TagT>,
	}
): ()
	table.sort(anatomySources, function(left, right)
		local a, b = anatomyHostRegistrations[left], anatomyHostRegistrations[right]
		return if a.priority == b.priority then a.ordinal < b.ordinal else a.priority < b.priority
	end)
end

local function disconnectTaggedSource<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	anatomySource: AnatomySource<SocketT, TagT>
): ()
	for _, anatomyHostTaggedSelection in self._taggedSelections do
		local release = anatomyHostTaggedSelection.disconnects[anatomySource]
		if release then
			anatomyHostTaggedSelection.disconnects[anatomySource] = nil
			release()
		end
	end
end

local function connectTaggedSource<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string,
	anatomyHostTaggedSelection: AnatomyHostTaggedSelection<SocketT, TagT>,
	anatomySource: AnatomySource<SocketT, TagT>,
	anatomyHostRegistration: AnatomyHostRegistration<SocketT, TagT>
): ()
	anatomyHostTaggedSelection.disconnects[anatomySource] = anatomySource:bindTopTaggedChanged(
		prefix,
		function()
			if
				anatomyHostRegistration.active
				and self._taggedSelections[prefix] == anatomyHostTaggedSelection
			then
				self:_refreshTopTagged(prefix)
			end
		end
	)
end

local function refreshTaggedSource<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	anatomyHostRegistration: AnatomyHostRegistration<SocketT, TagT>
): ()
	for prefix in self._taggedSelections do
		for anatomyTaggedElement in anatomyHostRegistration.taggedElements do
			if anatomyTaggedElement:hasTag(prefix) then
				self:_refreshTopTagged(prefix)
				break
			end
		end
	end
end

local function resolveTopTagged<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string
): AnatomyTaggedElement<TagT>?
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

local function new<SocketT, TagT>(options: AnatomyHostOptions<SocketT, TagT>): AnatomyHost<SocketT, TagT>
	local self: AnatomyHostImpl<SocketT, TagT> =
		setmetatable({}, AnatomyHost) :: AnatomyHostImpl<SocketT, TagT>
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

function AnatomyHost._refreshSocket<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>, name: SocketT): ()
	local selected: AnatomySocket<SocketT>? = nil
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

function AnatomyHost.push<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	anatomySource: AnatomySource<SocketT, TagT>,
	priority: number?
): ()
	assert(not self._destroyed, "Cannot push to a destroyed AnatomyHost")
	assert(self._registrations[anatomySource] == nil, "AnatomySource is already registered")
	assert(not reaches(anatomySource, self), "AnatomyHost sources must not form a cycle")
	local anatomyHostRegistration: AnatomyHostRegistration<SocketT, TagT> = {
		priority = priority or 0,
		ordinal = self._nextOrdinal,
		socketsByName = {},
		taggedElements = {},
		active = false,
	}
	-- Stage and validate initial membership before making the registration visible.
	-- On rejection release every subscription acquired so far.
	local ok, failure = pcall(function(): unknown
		anatomyHostRegistration.disconnectSocketChanged = anatomySource:bindSocketChanged(
			function(name, anatomySocket)
				assert(self._socketNameGuard(name) == name, "Invalid source socket name")
				anatomyHostRegistration.socketsByName[name] = anatomySocket
				if anatomyHostRegistration.active then
					self:_refreshSocket(name)
				end
			end,
			true
		)
		anatomyHostRegistration.disconnectTaggedAdded = anatomySource:bindTaggedAdded(
			function(anatomyTaggedElement)
				for tag in anatomyTaggedElement:getTags() do
					assert(self._tagGuard(tag) == tag, "Invalid source tag")
				end
				if anatomyHostRegistration.taggedElements[anatomyTaggedElement] then
					return
				end
				anatomyHostRegistration.taggedElements[anatomyTaggedElement] = true
				if anatomyHostRegistration.active then
					local count = self._taggedElementCounts[anatomyTaggedElement] or 0
					self._taggedElementCounts[anatomyTaggedElement] = count + 1
					if count == 0 then
						for callback in self._taggedAddedCallbacks do
							if self._taggedElementCounts[anatomyTaggedElement] == nil then
								break
							end
							callback(anatomyTaggedElement)
						end
					end
				end
			end,
			true
		)
		anatomyHostRegistration.disconnectTaggedRemoved = anatomySource:bindTaggedRemoved(
			function(anatomyTaggedElement)
				if not anatomyHostRegistration.taggedElements[anatomyTaggedElement] then
					return
				end
				anatomyHostRegistration.taggedElements[anatomyTaggedElement] = nil
				if anatomyHostRegistration.active then
					local count = self._taggedElementCounts[anatomyTaggedElement]
					self._taggedElementCounts[anatomyTaggedElement] = if count == 1
						then nil
						else count - 1
					if count == 1 then
						for callback in self._taggedRemovedCallbacks do
							if self._taggedElementCounts[anatomyTaggedElement] ~= nil then
								break
							end
							callback(anatomyTaggedElement)
						end
					end
				end
			end
		)
		for prefix, anatomyHostTaggedSelection in self._taggedSelections do
			connectTaggedSource(
				self,
				prefix,
				anatomyHostTaggedSelection,
				anatomySource,
				anatomyHostRegistration
			)
		end
		assert(
			not self._destroyed and self._registrations[anatomySource] == nil,
			"Host changed during source registration"
		)
		assert(not reaches(anatomySource, self), "AnatomyHost sources must not form a cycle")
		return nil
	end)
	if not ok then
		disconnectTaggedSource(self, anatomySource)
		disconnect(anatomyHostRegistration)
		error(failure, 0)
	end
	self._nextOrdinal += 1
	self._registrations[anatomySource] = anatomyHostRegistration
	table.insert(self._sources, anatomySource)
	sortSources(self._sources, self._registrations)
	anatomyHostRegistration.active = true
	local addedTaggedElements: { AnatomyTaggedElement<TagT> } = {}
	for anatomyTaggedElement in anatomyHostRegistration.taggedElements do
		local count = self._taggedElementCounts[anatomyTaggedElement] or 0
		self._taggedElementCounts[anatomyTaggedElement] = count + 1
		if count == 0 then
			table.insert(addedTaggedElements, anatomyTaggedElement)
		end
	end
	for name in anatomyHostRegistration.socketsByName do
		if not anatomyHostRegistration.active then
			break
		end
		self:_refreshSocket(name)
	end
	if anatomyHostRegistration.active then
		refreshTaggedSource(self, anatomyHostRegistration)
	end
	for _, anatomyTaggedElement in addedTaggedElements do
		if not anatomyHostRegistration.active then
			break
		end
		for callback in self._taggedAddedCallbacks do
			if self._taggedElementCounts[anatomyTaggedElement] == nil then
				break
			end
			callback(anatomyTaggedElement)
		end
	end
end

function AnatomyHost.remove<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	anatomySource: AnatomySource<SocketT, TagT>
): boolean
	local anatomyHostRegistration = self._registrations[anatomySource]
	if anatomyHostRegistration == nil then
		return false
	end
	disconnect(anatomyHostRegistration)
	disconnectTaggedSource(self, anatomySource)
	self._registrations[anatomySource] = nil
	local index = table.find(self._sources, anatomySource)
	if index then
		table.remove(self._sources, index)
	end
	local removedTaggedElements: { AnatomyTaggedElement<TagT> } = {}
	for anatomyTaggedElement in anatomyHostRegistration.taggedElements do
		local count = self._taggedElementCounts[anatomyTaggedElement]
		self._taggedElementCounts[anatomyTaggedElement] = if count == 1 then nil else count - 1
		if count == 1 then
			table.insert(removedTaggedElements, anatomyTaggedElement)
		end
	end
	for name in anatomyHostRegistration.socketsByName do
		self:_refreshSocket(name)
	end
	refreshTaggedSource(self, anatomyHostRegistration)
	for _, anatomyTaggedElement in removedTaggedElements do
		for callback in self._taggedRemovedCallbacks do
			if self._taggedElementCounts[anatomyTaggedElement] ~= nil then
				break
			end
			callback(anatomyTaggedElement)
		end
	end
	return true
end

function AnatomyHost.setPriority<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	anatomySource: AnatomySource<SocketT, TagT>,
	priority: number
): ()
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	local anatomyHostRegistration =
		assert(self._registrations[anatomySource], "AnatomySource is not registered")
	if anatomyHostRegistration.priority == priority then
		return
	end
	anatomyHostRegistration.priority = priority
	sortSources(self._sources, self._registrations)
	refreshTaggedSource(self, anatomyHostRegistration)
	for name in anatomyHostRegistration.socketsByName do
		if not anatomyHostRegistration.active then
			break
		end
		self:_refreshSocket(name)
	end
end

function AnatomyHost.clear<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>): ()
	-- Snapshot identity membership because removal callbacks can register other sources.
	for _, anatomySource in table.clone(self._sources) do
		self:remove(anatomySource)
	end
end

function AnatomyHost.getSocket<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	name: SocketT
): AnatomySocket<SocketT>?
	return self._resolvedSockets[name]
end

function AnatomyHost.getTagged<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string
): { AnatomyTaggedElement<TagT> }
	local result: { AnatomyTaggedElement<TagT> } = {}
	local seen: { [AnatomyTaggedElement<TagT>]: true } = {}
	-- Keep the highest-precedence occurrence of a shared element, then reverse.
	for index = #self._sources, 1, -1 do
		local anatomyTaggedElements = self._sources[index]:getTagged(prefix)
		for elementIndex = #anatomyTaggedElements, 1, -1 do
			local anatomyTaggedElement = anatomyTaggedElements[elementIndex]
			if not seen[anatomyTaggedElement] then
				seen[anatomyTaggedElement] = true
				table.insert(result, anatomyTaggedElement)
			end
		end
	end
	for index = 1, math.floor(#result / 2) do
		local opposite = #result - index + 1
		result[index], result[opposite] = result[opposite], result[index]
	end
	return result
end

function AnatomyHost.getTopTagged<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string
): AnatomyTaggedElement<TagT>?
	local anatomyHostTaggedSelection = self._taggedSelections[prefix]
	return if anatomyHostTaggedSelection
		then anatomyHostTaggedSelection.current
		else resolveTopTagged(self, prefix)
end

function AnatomyHost._refreshTopTagged<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>, prefix: string): ()
	local anatomyHostTaggedSelection = self._taggedSelections[prefix]
	if anatomyHostTaggedSelection == nil then
		return
	end
	local selected = resolveTopTagged(self, prefix)
	if anatomyHostTaggedSelection.current == selected then
		return
	end
	anatomyHostTaggedSelection.current = selected
	for callback in anatomyHostTaggedSelection.callbacks do
		if
			self._taggedSelections[prefix] ~= anatomyHostTaggedSelection
			or anatomyHostTaggedSelection.current ~= selected
		then
			break
		end
		callback(selected)
	end
end

function AnatomyHost.bindTopTaggedChanged<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	prefix: string,
	callback: (AnatomyTaggedElement<TagT>?) -> (),
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	local anatomyHostTaggedSelection = self._taggedSelections[prefix]
	if anatomyHostTaggedSelection == nil then
		anatomyHostTaggedSelection =
			{ current = self:getTopTagged(prefix), callbacks = {}, disconnects = {} }
		self._taggedSelections[prefix] = anatomyHostTaggedSelection
		local created: AnatomyHostTaggedSelection<SocketT, TagT> = anatomyHostTaggedSelection
		local ok, failure = pcall(function(): unknown
			for _, anatomySource in self._sources do
				connectTaggedSource(
					self,
					prefix,
					created,
					anatomySource,
					self._registrations[anatomySource]
				)
			end
			return nil
		end)
		if not ok then
			self._taggedSelections[prefix] = nil
			for _, disconnectSource in anatomyHostTaggedSelection.disconnects do
				disconnectSource()
			end
			error(failure, 0)
		end
	end
	local retained = anatomyHostTaggedSelection
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

function AnatomyHost.bindToSocket<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	name: SocketT,
	callback: (AnatomySocket<SocketT>?) -> (),
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

function AnatomyHost.bindSocketChanged<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	callback: (SocketT, AnatomySocket<SocketT>?) -> (),
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	local release = CallbackSet.bind(self._socketChangedCallbacks, callback)
	if runInitially then
		local ok, failure = pcall(function(): unknown
			for name, anatomySocket in self._resolvedSockets do
				callback(name, anatomySocket)
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

function AnatomyHost.bindTaggedAdded<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	callback: (AnatomyTaggedElement<TagT>) -> (),
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	local release = CallbackSet.bind(self._taggedAddedCallbacks, callback)
	if runInitially then
		local ok, failure = pcall(function(): unknown
			for anatomyTaggedElement in self._taggedElementCounts do
				callback(anatomyTaggedElement)
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

function AnatomyHost.bindTaggedRemoved<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	callback: (AnatomyTaggedElement<TagT>) -> ()
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomyHost")
	return CallbackSet.bind(self._taggedRemovedCallbacks, callback)
end

function AnatomyHost.mount<SocketT, TagT>(
	self: AnatomyHostImpl<SocketT, TagT>,
	from: Attachment?,
	to: Attachment?,
	options: SocketMountOptions?
): SocketMount
	assert(not self._destroyed, "Cannot use a destroyed AnatomyHost")
	local socketMount = SocketMount.new(from, to, options)
	self._socketMounts[socketMount] = true
	return socketMount
end

function AnatomyHost.deconstruct<SocketT, TagT>(self: AnatomyHostImpl<SocketT, TagT>): ()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self:clear()
	for socketMount in self._socketMounts do
		socketMount:deconstruct()
	end
	for _, anatomyHostRegistration in self._registrations do
		disconnect(anatomyHostRegistration)
	end
	table.clear(self._registrations)
	table.clear(self._sources)
	table.clear(self._resolvedSockets)
	table.clear(self._taggedElementCounts)
	table.clear(self._socketChangedCallbacks)
	table.clear(self._taggedAddedCallbacks)
	table.clear(self._taggedRemovedCallbacks)
	for _, anatomyHostTaggedSelection in self._taggedSelections do
		for _, release in anatomyHostTaggedSelection.disconnects do
			release()
		end
		table.clear(anatomyHostTaggedSelection.disconnects)
		table.clear(anatomyHostTaggedSelection.callbacks)
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
