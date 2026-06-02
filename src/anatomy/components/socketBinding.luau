--!strict
--!optimize 2
--!native

local Hook = require(script.Parent.Parent.Parent.externalPackages.hook)
local Types = require(script.Parent.Parent.types.components.socketBinding)

export type AnatomySocket = Types.AnatomySocket
export type MountAttachment = Types.MountAttachment
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketBinding = Types.SocketBinding
export type SocketBindingImpl = Types.SocketBindingImpl
export type SocketChangedCallback = Types.SocketChangedCallback
export type SocketName = Types.SocketName

local SocketBinding = {}
SocketBinding.__index = SocketBinding

function SocketBinding.new(name: SocketName, source: any?, initialSocket: AnatomySocket?): SocketBinding
	local self: SocketBindingImpl = setmetatable({}, SocketBinding) :: any

	self._name = name
	self._socket = nil
	self._socketChangedHook = Hook.new()
	self._attachmentChangedHook = Hook.new()
	self._socketAttachmentBindId = nil
	self._source = source
	self._sourceBindId = nil
	self._destroyed = false

	if source ~= nil then
		self._sourceBindId = source:bindSocket(name, function(socket: AnatomySocket?)
			self:_setSocket(socket)
		end, true)
	elseif initialSocket ~= nil then
		self:_setSocket(initialSocket)
	end

	return self
end

function SocketBinding.getName(self: SocketBindingImpl): SocketName
	return self._name
end

function SocketBinding.getSocket(self: SocketBindingImpl): AnatomySocket?
	if self._destroyed then
		return nil
	end

	return self._socket
end

function SocketBinding.getAttachment(self: SocketBindingImpl): Attachment?
	local socket = self:getSocket()
	if socket == nil then
		return nil
	end

	return socket:getAttachment()
end

function SocketBinding.bindAttachmentChanged(
	self: SocketBindingImpl,
	callback: SocketAttachmentChangedCallback,
	runInitially: boolean?
): number
	if runInitially == true then
		callback(self:getAttachment())
	end

	return self._attachmentChangedHook:add(callback)
end

function SocketBinding.unbindAttachmentChanged(self: SocketBindingImpl, hookId: number): boolean
	return self._attachmentChangedHook:remove(hookId)
end

function SocketBinding.bindSocketChanged(
	self: SocketBindingImpl,
	callback: SocketChangedCallback,
	runInitially: boolean?
): number
	if runInitially == true then
		callback(self:getSocket())
	end

	return self._socketChangedHook:add(callback)
end

function SocketBinding.unbindSocketChanged(self: SocketBindingImpl, hookId: number): boolean
	return self._socketChangedHook:remove(hookId)
end

function SocketBinding._setSocket(self: SocketBindingImpl, socket: AnatomySocket?): ()
	if self._socket == socket then
		return
	end

	local oldSocket = self._socket
	local oldAttachmentBindId = self._socketAttachmentBindId
	if oldSocket ~= nil and oldAttachmentBindId ~= nil then
		oldSocket:unbindAttachmentChanged(oldAttachmentBindId)
	end

	self._socket = socket
	self._socketAttachmentBindId = nil

	if socket ~= nil then
		self._socketAttachmentBindId = socket:bindAttachmentChanged(function(attachment: Attachment?)
			self._attachmentChangedHook:fire(attachment)
		end, false)
	end

	self._socketChangedHook:fire(socket)
	self._attachmentChangedHook:fire(self:getAttachment())
end

function SocketBinding.deconstruct(self: SocketBindingImpl): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	if self._source ~= nil and self._sourceBindId ~= nil then
		self._source:unbindSocket(self._name, self._sourceBindId)
	end

	if self._socket ~= nil and self._socketAttachmentBindId ~= nil then
		self._socket:unbindAttachmentChanged(self._socketAttachmentBindId)
	end

	self._socketChangedHook:deconstruct()
	self._attachmentChangedHook:deconstruct()
	self._socket = nil
	self._source = nil
	self._sourceBindId = nil
	self._socketAttachmentBindId = nil
end

return SocketBinding
