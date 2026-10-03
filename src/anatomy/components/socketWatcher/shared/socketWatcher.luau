--!strict
--!optimize 2

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet.shared.callbackSet)
local SocketWatcherTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.socketWatcher.shared.socketWatcher)

type AnatomySocket<SocketT> = SocketWatcherTypes.AnatomySocket<SocketT>
type SocketWatcher<SocketT> = SocketWatcherTypes.SocketWatcher<SocketT>
type SocketWatcherImpl<SocketT> = SocketWatcherTypes.SocketWatcherImpl<SocketT>
type SocketSubscription<SocketT> = SocketWatcherTypes.SocketSubscription<SocketT>
type SocketChangedCallback<SocketT> = SocketWatcherTypes.SocketChangedCallback<SocketT>
type LayerId = SocketWatcherTypes.LayerId

local SocketWatcher = {}
SocketWatcher.__index = SocketWatcher

local function new<SocketT>(
	source: SocketSubscription<SocketT>,
	name: SocketT,
	layerId: LayerId?,
	includeOverrides: boolean?
): SocketWatcher<SocketT>
	local self: SocketWatcherImpl<SocketT> =
		setmetatable({}, SocketWatcher) :: SocketWatcherImpl<SocketT>
	self._name = name
	self._socket = nil
	self._socketChangedCallbacks = {}
	self._sourceDisconnect = nil
	self._destroyed = false
	self._sourceDisconnect = source:bindSocket(name, function(socket: AnatomySocket<SocketT>?)
		self:_setSocket(socket)
	end, true, layerId, includeOverrides)
	return self
end

function SocketWatcher.getName<SocketT>(self: SocketWatcherImpl<SocketT>): SocketT
	return self._name
end

function SocketWatcher.getSocket<SocketT>(self: SocketWatcherImpl<SocketT>): AnatomySocket<SocketT>?
	return self._socket
end

function SocketWatcher.bindSocketChanged<SocketT>(
	self: SocketWatcherImpl<SocketT>,
	callback: SocketChangedCallback<SocketT>,
	runInitially: boolean?
): () -> ()
	assert(not self._destroyed, "Cannot subscribe to a destroyed SocketWatcher")
	if runInitially == true then
		callback(self._socket)
	end
	return CallbackSet.bind(self._socketChangedCallbacks, callback)
end

function SocketWatcher._setSocket<SocketT>(
	self: SocketWatcherImpl<SocketT>,
	socket: AnatomySocket<SocketT>?
): ()
	if self._socket == socket then
		return
	end
	self._socket = socket
	CallbackSet.fire(self._socketChangedCallbacks, socket)
end

function SocketWatcher.deconstruct<SocketT>(self: SocketWatcherImpl<SocketT>): ()
	if self._destroyed then
		return
	end
	self._destroyed = true
	if self._sourceDisconnect ~= nil then
		self._sourceDisconnect()
		self._sourceDisconnect = nil
	end
	self:_setSocket(nil)
	table.clear(self._socketChangedCallbacks)
end

return { new = new }
