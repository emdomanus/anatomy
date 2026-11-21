--!native
--!strict
--!optimize 2
-- Composes anatomy sources by priority. A source is an anatomyInstance or another anatomyHost; for
-- each socket name and each tag prefix the highest-precedence source that supplies it wins.
--
-- `push`, `remove` and `setPriority` work in two passes over the socket names and prefixes of the
-- source they moved. The first pass scans `_anatomySources` from the top for each name and writes
-- the winner, so every query on this host is correct before any callback runs. The second pass
-- reports each name whose winner differs from `_reportedWinnerInstances`: it fires
-- `_anySocketChangedList` with the name, for the hosts this one is pushed to, and
-- `_socketChangedLists[name]` with the two results.
--
-- A host pushed into this one reports by calling `_handleSourceSocketChanged(socketName)`, the one
-- function this host gave it at `push`. That runs both passes for that one name.
--
-- A callback may change the composition. The host keeps no flag about a report in progress: after
-- a fire returns it compares the winner with the instance it fired and fires again while they
-- differ, so the last call every subscriber receives carries the current results.
local LuauUtils = require("../../../luau_packages/luauUtils")
local AnatomyHostPrivateTypes = require("../../types/components/anatomyHost/anatomyHost/private")
local AnatomyHostTypes = require("../../types/components/anatomyHost/anatomyHost/public")
local AnatomySourceTypes = require("../../types/def/anatomy/anatomySource/public")

type AnatomyHostImpl = AnatomyHostPrivateTypes.AnatomyHostImpl
type AnatomyHostOwned = AnatomyHostTypes.AnatomyHostOwned
type AnatomySource = AnatomySourceTypes.AnatomySource
type CallbackList<Args...> = LuauUtils.CallbackList<Args...>
export type AnatomyHostModule = {
	read new: () -> AnatomyHostOwned,
}

local DECONSTRUCTED_MESSAGE = "AnatomyHost is deconstructed"

-- First pass for one socket name: lists the name the first time it is seen, then scans the sources
-- from the top and writes the first one's results, or nil when none supplies it.
local function resolveSocket(self: AnatomyHostImpl, socketName: string): ()
	if not self._knownSocketNames[socketName] then
		self._knownSocketNames[socketName] = true
		table.insert(self._socketNames, socketName)
	end
	local anatomySources = self._anatomySources
	local winnerElementIndex: number? = nil
	local winnerInstance: AnatomySource? = nil
	for index = #anatomySources, 1, -1 do
		local elementIndex, anatomyInstance = anatomySources[index]:getSocket(socketName)
		if elementIndex ~= nil then
			winnerElementIndex, winnerInstance = elementIndex, anatomyInstance
			break
		end
	end
	self._winnerElementIndexes[socketName] = winnerElementIndex
	self._winnerInstances[socketName] = winnerInstance
end

local function resolveTopTagged(self: AnatomyHostImpl, prefix: string): ()
	if not self._knownTaggedPrefixes[prefix] then
		self._knownTaggedPrefixes[prefix] = true
		table.insert(self._taggedPrefixes, prefix)
	end
	local anatomySources = self._anatomySources
	local topElementIndex: number? = nil
	local topInstance: AnatomySource? = nil
	for index = #anatomySources, 1, -1 do
		local elementIndex, anatomyInstance = anatomySources[index]:getTopTagged(prefix)
		if elementIndex ~= nil then
			topElementIndex, topInstance = elementIndex, anatomyInstance
			break
		end
	end
	self._topTaggedElementIndexes[prefix] = topElementIndex
	self._topTaggedInstances[prefix] = topInstance
end

-- Second pass for one socket name. A changed winner is fired to the hosts this one is pushed to
-- and to the name's subscribers, and fired again while a callback changed it meanwhile. The "among
-- others" entries of the name are called whether or not the winner changed: the winner among the
-- other sources can change while the overall winner does not.
local function reportSocket(self: AnatomyHostImpl, socketName: string): ()
	if self._winnerInstances[socketName] ~= self._reportedWinnerInstances[socketName] then
		repeat
			local firedElementIndex: number? = self._winnerElementIndexes[socketName]
			local firedInstance: AnatomySource? = self._winnerInstances[socketName]
			self._reportedWinnerInstances[socketName] = firedInstance
			local anySocketChangedList = self._anySocketChangedList
			if anySocketChangedList ~= nil then
				anySocketChangedList:fire(socketName)
			end
			local socketChangedList = self._socketChangedLists[socketName]
			if socketChangedList ~= nil then
				socketChangedList:fire(firedElementIndex, firedInstance)
			end
		until self._winnerInstances[socketName] == firedInstance
	end
	local socketAmongOthersList = self._socketAmongOthersLists[socketName]
	if socketAmongOthersList ~= nil then
		socketAmongOthersList:fire()
	end
end

local function reportTopTagged(self: AnatomyHostImpl, prefix: string): ()
	if self._topTaggedInstances[prefix] ~= self._reportedTopTaggedInstances[prefix] then
		repeat
			local firedElementIndex: number? = self._topTaggedElementIndexes[prefix]
			local firedInstance: AnatomySource? = self._topTaggedInstances[prefix]
			self._reportedTopTaggedInstances[prefix] = firedInstance
			local anyTopTaggedChangedList = self._anyTopTaggedChangedList
			if anyTopTaggedChangedList ~= nil then
				anyTopTaggedChangedList:fire(prefix)
			end
			local topTaggedChangedList = self._topTaggedChangedLists[prefix]
			if topTaggedChangedList ~= nil then
				topTaggedChangedList:fire(firedElementIndex, firedInstance)
			end
		until self._topTaggedInstances[prefix] == firedInstance
	end
end

-- Both passes for every socket name and prefix in the two lists: the first pass for all of them,
-- then the second. The lists are a source's, or this host's own at `deconstruct`. A callback of the
-- second pass can make a host's list grow; the operation that appended a name ran both passes for
-- it, so the bounds read here are enough.
local function resolveAndReport(
	self: AnatomyHostImpl,
	socketNames: { read [number]: string },
	taggedPrefixes: { read [number]: string }
): ()
	local socketNameCount = #socketNames
	local taggedPrefixCount = #taggedPrefixes
	for index = 1, socketNameCount do
		resolveSocket(self, socketNames[index])
	end
	for index = 1, taggedPrefixCount do
		resolveTopTagged(self, taggedPrefixes[index])
	end
	for index = 1, socketNameCount do
		reportSocket(self, socketNames[index])
	end
	for index = 1, taggedPrefixCount do
		reportTopTagged(self, taggedPrefixes[index])
	end
end

-- The socket as the highest-precedence source other than `excluded` supplies it.
local function resolveSocketAmongOthers(
	self: AnatomyHostImpl,
	socketName: string,
	excluded: AnatomySource
): (number?, AnatomySource?)
	local anatomySources = self._anatomySources
	for index = #anatomySources, 1, -1 do
		local anatomySource = anatomySources[index]
		if anatomySource ~= excluded then
			local elementIndex, anatomyInstance = anatomySource:getSocket(socketName)
			if elementIndex ~= nil then
				return elementIndex, anatomyInstance
			end
		end
	end
	return nil, nil
end

-- Where a source of `priority` goes in `_anatomySources`: above every source of the same or a lower
-- priority.
local function findPosition(self: AnatomyHostImpl, priority: number): number
	local priorities = self._priorities
	local position = #priorities + 1
	while position > 1 and priorities[position - 1] > priority do
		position -= 1
	end
	return position
end

local AnatomyHost = {}
AnatomyHost.__index = AnatomyHost

function AnatomyHost.new(): AnatomyHostOwned
	local socketNames: { string } = {}
	local taggedPrefixes: { string } = {}
	local self: AnatomyHostImpl
	self = (
		setmetatable({
			socketNames = socketNames,
			taggedPrefixes = taggedPrefixes,
			_anatomySources = {},
			_priorities = {},
			_releaseAnySocketChanged = {},
			_releaseAnyTopTaggedChanged = {},
			_socketNames = socketNames,
			_taggedPrefixes = taggedPrefixes,
			_knownSocketNames = {},
			_knownTaggedPrefixes = {},
			_winnerElementIndexes = {},
			_winnerInstances = {},
			_topTaggedElementIndexes = {},
			_topTaggedInstances = {},
			_reportedWinnerInstances = {},
			_reportedTopTaggedInstances = {},
			_anySocketChangedList = nil,
			_anyTopTaggedChangedList = nil,
			_socketChangedLists = {},
			_topTaggedChangedLists = {},
			_socketAmongOthersLists = {},
			-- A source that is a host calls these when one of its own winners changes.
			_handleSourceSocketChanged = function(socketName: string): ()
				resolveSocket(self, socketName)
				reportSocket(self, socketName)
			end,
			_handleSourceTopTaggedChanged = function(prefix: string): ()
				resolveTopTagged(self, prefix)
				reportTopTagged(self, prefix)
			end,
			_deconstructed = false,
		}, AnatomyHost) :: unknown
	) :: AnatomyHostImpl
	return self
end

function AnatomyHost.getSocket(self: AnatomyHostImpl, socketName: string): (number?, AnatomySource?)
	return self._winnerElementIndexes[socketName], self._winnerInstances[socketName]
end

function AnatomyHost.getTopTagged(self: AnatomyHostImpl, prefix: string): (number?, AnatomySource?)
	return self._topTaggedElementIndexes[prefix], self._topTaggedInstances[prefix]
end

function AnatomyHost.getTagged(
	self: AnatomyHostImpl,
	prefix: string,
	intoElementIndexes: { number },
	intoAnatomyInstances: { AnatomySource }
): ()
	local anatomySources = self._anatomySources
	for index = 1, #anatomySources do
		anatomySources[index]:getTagged(prefix, intoElementIndexes, intoAnatomyInstances)
	end
end

function AnatomyHost.onAnySocketChanged(
	self: AnatomyHostImpl,
	callback: (socketName: string) -> ()
): () -> ()
	if self._deconstructed then
		error(DECONSTRUCTED_MESSAGE, 2)
	end
	local anySocketChangedList = self._anySocketChangedList
	if anySocketChangedList == nil then
		local created: CallbackList<string> = LuauUtils.callbackList.new()
		self._anySocketChangedList = created
		return created:add(callback)
	end
	return anySocketChangedList:add(callback)
end

function AnatomyHost.onAnyTopTaggedChanged(
	self: AnatomyHostImpl,
	callback: (prefix: string) -> ()
): () -> ()
	if self._deconstructed then
		error(DECONSTRUCTED_MESSAGE, 2)
	end
	local anyTopTaggedChangedList = self._anyTopTaggedChangedList
	if anyTopTaggedChangedList == nil then
		local created: CallbackList<string> = LuauUtils.callbackList.new()
		self._anyTopTaggedChangedList = created
		return created:add(callback)
	end
	return anyTopTaggedChangedList:add(callback)
end

function AnatomyHost.containsSource(self: AnatomyHostImpl, anatomySource: AnatomySource): boolean
	if anatomySource == self then
		return true
	end
	local anatomySources = self._anatomySources
	for index = 1, #anatomySources do
		if anatomySources[index]:containsSource(anatomySource) then
			return true
		end
	end
	return false
end

function AnatomyHost.onSocketChanged(
	self: AnatomyHostImpl,
	socketName: string,
	callback: (
		elementIndex: number?,
		anatomyInstance: AnatomySource?
	) -> (),
	initially: boolean?
): () -> ()
	if self._deconstructed then
		error(DECONSTRUCTED_MESSAGE, 2)
	end
	local socketChangedList = self._socketChangedLists[socketName]
	if socketChangedList == nil then
		local created: CallbackList<number?, AnatomySource?> = LuauUtils.callbackList.new()
		self._socketChangedLists[socketName] = created
		socketChangedList = created
	end
	-- Added before the first call, so a change the callback itself makes reaches it.
	local release = socketChangedList:add(callback)
	if initially then
		callback(self._winnerElementIndexes[socketName], self._winnerInstances[socketName])
	end
	return release
end

function AnatomyHost.onTopTaggedChanged(
	self: AnatomyHostImpl,
	prefix: string,
	callback: (
		elementIndex: number?,
		anatomyInstance: AnatomySource?
	) -> (),
	initially: boolean?
): () -> ()
	if self._deconstructed then
		error(DECONSTRUCTED_MESSAGE, 2)
	end
	local topTaggedChangedList = self._topTaggedChangedLists[prefix]
	if topTaggedChangedList == nil then
		local created: CallbackList<number?, AnatomySource?> = LuauUtils.callbackList.new()
		self._topTaggedChangedLists[prefix] = created
		topTaggedChangedList = created
	end
	local release = topTaggedChangedList:add(callback)
	if initially then
		callback(self._topTaggedElementIndexes[prefix], self._topTaggedInstances[prefix])
	end
	return release
end

function AnatomyHost.onSocketAmongOthersChanged(
	self: AnatomyHostImpl,
	socketName: string,
	excluded: AnatomySource,
	callback: (
		elementIndex: number?,
		anatomyInstance: AnatomySource?
	) -> (),
	initially: boolean?
): () -> ()
	if self._deconstructed then
		error(DECONSTRUCTED_MESSAGE, 2)
	end
	local socketAmongOthersList = self._socketAmongOthersLists[socketName]
	if socketAmongOthersList == nil then
		local created: CallbackList<> = LuauUtils.callbackList.new()
		self._socketAmongOthersLists[socketName] = created
		socketAmongOthersList = created
	end
	local elementIndex, anatomyInstance = resolveSocketAmongOthers(self, socketName, excluded)
	-- What this subscriber was last told, or what it would have been told when it subscribed.
	local reportedInstance = anatomyInstance
	local release = socketAmongOthersList:add(function(): ()
		local currentElementIndex, currentInstance =
			resolveSocketAmongOthers(self, socketName, excluded)
		if currentInstance ~= reportedInstance then
			-- Written before the call, so a change the callback makes is compared with this one.
			reportedInstance = currentInstance
			callback(currentElementIndex, currentInstance)
		end
	end)
	if initially then
		callback(elementIndex, anatomyInstance)
	end
	return release
end

function AnatomyHost.push(self: AnatomyHostImpl, anatomySource: AnatomySource, priority: number): ()
	if self._deconstructed then
		error(DECONSTRUCTED_MESSAGE, 2)
	end
	local anatomySources = self._anatomySources
	if table.find(anatomySources, anatomySource) ~= nil then
		error("AnatomyHost.push: the source is already pushed to this host", 2)
	end
	if anatomySource:containsSource(self) then
		error("AnatomyHost.push: the source is this host or contains it", 2)
	end
	local releaseAnySocketChanged =
		anatomySource:onAnySocketChanged(self._handleSourceSocketChanged)
	local releaseAnyTopTaggedChanged =
		anatomySource:onAnyTopTaggedChanged(self._handleSourceTopTaggedChanged)
	local position = findPosition(self, priority)
	table.insert(anatomySources, position, anatomySource)
	table.insert(self._priorities, position, priority)
	table.insert(self._releaseAnySocketChanged, position, releaseAnySocketChanged)
	table.insert(self._releaseAnyTopTaggedChanged, position, releaseAnyTopTaggedChanged)
	resolveAndReport(self, anatomySource.socketNames, anatomySource.taggedPrefixes)
end

function AnatomyHost.remove(self: AnatomyHostImpl, anatomySource: AnatomySource): ()
	local anatomySources = self._anatomySources
	local position = table.find(anatomySources, anatomySource)
	if position == nil then
		return
	end
	local releaseAnySocketChanged = self._releaseAnySocketChanged[position]
	local releaseAnyTopTaggedChanged = self._releaseAnyTopTaggedChanged[position]
	table.remove(anatomySources, position)
	table.remove(self._priorities, position)
	table.remove(self._releaseAnySocketChanged, position)
	table.remove(self._releaseAnyTopTaggedChanged, position)
	releaseAnySocketChanged()
	releaseAnyTopTaggedChanged()
	resolveAndReport(self, anatomySource.socketNames, anatomySource.taggedPrefixes)
end

function AnatomyHost.setPriority(
	self: AnatomyHostImpl,
	anatomySource: AnatomySource,
	priority: number
): ()
	local anatomySources = self._anatomySources
	local position = table.find(anatomySources, anatomySource)
	if position == nil then
		error("AnatomyHost.setPriority: the source is not pushed to this host", 2)
	end
	local priorities = self._priorities
	if priorities[position] == priority then
		return
	end
	local releaseAnySocketChanged = self._releaseAnySocketChanged[position]
	local releaseAnyTopTaggedChanged = self._releaseAnyTopTaggedChanged[position]
	table.remove(anatomySources, position)
	table.remove(priorities, position)
	table.remove(self._releaseAnySocketChanged, position)
	table.remove(self._releaseAnyTopTaggedChanged, position)
	local newPosition = findPosition(self, priority)
	table.insert(anatomySources, newPosition, anatomySource)
	table.insert(priorities, newPosition, priority)
	table.insert(self._releaseAnySocketChanged, newPosition, releaseAnySocketChanged)
	table.insert(self._releaseAnyTopTaggedChanged, newPosition, releaseAnyTopTaggedChanged)
	resolveAndReport(self, anatomySource.socketNames, anatomySource.taggedPrefixes)
end

function AnatomyHost.deconstruct(self: AnatomyHostImpl): ()
	if self._deconstructed then
		return
	end
	self._deconstructed = true
	local releaseAnySocketChanged = self._releaseAnySocketChanged
	local releaseAnyTopTaggedChanged = self._releaseAnyTopTaggedChanged
	for index = 1, #releaseAnySocketChanged do
		releaseAnySocketChanged[index]()
		releaseAnyTopTaggedChanged[index]()
	end
	table.clear(self._anatomySources)
	table.clear(self._priorities)
	table.clear(releaseAnySocketChanged)
	table.clear(releaseAnyTopTaggedChanged)
	-- No source is left, so both passes over every name this host has listed write nil and report
	-- it once.
	resolveAndReport(self, self._socketNames, self._taggedPrefixes)

	local anySocketChangedList = self._anySocketChangedList
	if anySocketChangedList ~= nil then
		anySocketChangedList:clear()
	end
	local anyTopTaggedChangedList = self._anyTopTaggedChangedList
	if anyTopTaggedChangedList ~= nil then
		anyTopTaggedChangedList:clear()
	end
	for _, socketChangedList in self._socketChangedLists do
		socketChangedList:clear()
	end
	for _, topTaggedChangedList in self._topTaggedChangedLists do
		topTaggedChangedList:clear()
	end
	for _, socketAmongOthersList in self._socketAmongOthersLists do
		socketAmongOthersList:clear()
	end
end

table.freeze(AnatomyHost)

local module: AnatomyHostModule = table.freeze({ new = AnatomyHost.new })
return module
