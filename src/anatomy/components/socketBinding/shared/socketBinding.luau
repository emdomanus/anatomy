--!strict
--!optimize 2
--!native

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.socketBinding)

export type AnatomySocket<SocketT> = Types.AnatomySocket<SocketT>
export type MountAttachment = Types.MountAttachment
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketBinding<SocketT> = Types.SocketBinding<SocketT>
export type SocketBindingImpl<SocketT> = Types.SocketBindingImpl<SocketT>
export type SocketBindingSource<SocketT> = Types.SocketBindingSource<SocketT>
export type SocketChangedCallback<SocketT> = Types.SocketChangedCallback<SocketT>

local SocketBinding = {}
SocketBinding.__index = SocketBinding

function SocketBinding.new<SocketT>(
	name: SocketT,
	source: SocketBindingSource<SocketT>?,
	initialSocket: AnatomySocket<SocketT>?
): SocketBinding<SocketT>
	local self: SocketBindingImpl<SocketT> = setmetatable({}, SocketBinding) :: any

	self._name = name
	self._socket = nil
	self._socketChangedCallbacks = CallbackSet.new()
	self._attachmentChangedCallbacks = CallbackSet.new()
	self._socketAttachmentDisconnect = nil
	self._source = source
	self._sourceDisconnect = nil
	self._destroyed = false

	if source ~= nil then
		self._sourceDisconnect = source:bindSocket(name, function(socket: AnatomySocket<SocketT>?)
			self:_setSocket(socket)
		end, true)
	elseif initialSocket ~= nil then
		self:_setSocket(initialSocket)
	end

	return self
end

function SocketBinding.getName<SocketT>(self: SocketBindingImpl<SocketT>): SocketT
	return self._name
end

function SocketBinding.getSocket<SocketT>(self: SocketBindingImpl<SocketT>): AnatomySocket<SocketT>?
	if self._destroyed then
		return nil
	end

	return self._socket
end

function SocketBinding.getAttachment<SocketT>(self: SocketBindingImpl<SocketT>): Attachment?
	local socket = self:getSocket()
	if socket == nil then
		return nil
	end

	return socket:getAttachment()
end

function SocketBinding.bindAttachmentChanged<SocketT>(
	self: SocketBindingImpl<SocketT>,
	callback: SocketAttachmentChangedCallback,
	runInitially: boolean?
): () -> ()
	if runInitially == true then
		callback(self:getAttachment())
	end

	return CallbackSet.bind(self._attachmentChangedCallbacks, callback)
end

function SocketBinding.bindSocketChanged<SocketT>(
	self: SocketBindingImpl<SocketT>,
	callback: SocketChangedCallback<SocketT>,
	runInitially: boolean?
): () -> ()
	if runInitially == true then
		callback(self:getSocket())
	end

	return CallbackSet.bind(self._socketChangedCallbacks, callback)
end

function SocketBinding._setSocket<SocketT>(self: SocketBindingImpl<SocketT>, socket: AnatomySocket<SocketT>?): ()
	if self._socket == socket then
		return
	end

	local oldSocket = self._socket
	local oldAttachmentDisconnect = self._socketAttachmentDisconnect
	if oldSocket ~= nil and oldAttachmentDisconnect ~= nil then
		oldAttachmentDisconnect()
	end

	self._socket = socket
	self._socketAttachmentDisconnect = nil

	if socket ~= nil then
		self._socketAttachmentDisconnect = socket:bindAttachmentChanged(function(attachment: Attachment?)
			CallbackSet.fire(self._attachmentChangedCallbacks, attachment)
		end, false)
	end

	CallbackSet.fire(self._socketChangedCallbacks, socket)
	CallbackSet.fire(self._attachmentChangedCallbacks, self:getAttachment())
end

function SocketBinding.deconstruct<SocketT>(self: SocketBindingImpl<SocketT>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	if self._source ~= nil and self._sourceDisconnect ~= nil then
		self._sourceDisconnect()
	end

	if self._socket ~= nil and self._socketAttachmentDisconnect ~= nil then
		self._socketAttachmentDisconnect()
	end

	table.clear(self._socketChangedCallbacks)
	table.clear(self._attachmentChangedCallbacks)
	self._socket = nil
	self._source = nil
	self._sourceDisconnect = nil
	self._socketAttachmentDisconnect = nil
end

return SocketBinding
