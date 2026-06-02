--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.types.components.socketMount)

export type MountAttachment = Types.MountAttachment
export type SocketEndpoint = Types.SocketEndpoint
export type SocketMount = Types.SocketMount
export type SocketMountImpl = Types.SocketMountImpl
export type SocketMountOptions = Types.SocketMountOptions

local SocketMount = {}
SocketMount.__index = SocketMount

local function getConstraintParent(options: SocketMountOptions, from: Attachment?, to: Attachment?): Instance?
	if options.parent ~= nil then
		return options.parent
	end
	if to ~= nil and to.Parent ~= nil then
		return to.Parent
	end
	if from ~= nil and from.Parent ~= nil then
		return from.Parent
	end

	return nil
end

function SocketMount.new(
	fromEndpoint: SocketEndpoint,
	toEndpoint: SocketEndpoint,
	options: SocketMountOptions?
): SocketMount
	local self: SocketMountImpl = setmetatable({}, SocketMount) :: any

	self._options = options or {}
	self._name = self._options.name
	self._fromEndpoint = fromEndpoint
	self._toEndpoint = toEndpoint
	self._fromAttachment = nil
	self._toAttachment = nil
	self._rigid = nil
	self._fromAttachmentBindId = nil
	self._toAttachmentBindId = nil
	self._enabled = self._options.enabled ~= false
	self._destroyed = false

	self._fromAttachmentBindId = fromEndpoint:bindAttachmentChanged(function(attachment: Attachment?)
		self:_setFromAttachment(attachment)
	end, true)

	self._toAttachmentBindId = toEndpoint:bindAttachmentChanged(function(attachment: Attachment?)
		self:_setToAttachment(attachment)
	end, true)

	self:refresh()

	return self
end

function SocketMount.getName(self: SocketMountImpl): string?
	return self._name
end

function SocketMount.getFromAttachment(self: SocketMountImpl): Attachment?
	return self._fromAttachment
end

function SocketMount.getToAttachment(self: SocketMountImpl): Attachment?
	return self._toAttachment
end

function SocketMount.getConstraint(self: SocketMountImpl): RigidConstraint?
	return self._rigid
end

function SocketMount.isConnected(self: SocketMountImpl): boolean
	return self._enabled and self._rigid ~= nil and self._fromAttachment ~= nil and self._toAttachment ~= nil
end

function SocketMount.setEnabled(self: SocketMountImpl, enabled: boolean): ()
	if self._enabled == enabled then
		return
	end

	self._enabled = enabled
	self:_reconcileConstraint()
end

function SocketMount.refresh(self: SocketMountImpl): ()
	self._fromAttachment = self._fromEndpoint:getAttachment()
	self._toAttachment = self._toEndpoint:getAttachment()
	self:_reconcileConstraint()
end

function SocketMount._setFromAttachment(self: SocketMountImpl, attachment: Attachment?): ()
	if self._fromAttachment == attachment then
		return
	end

	self._fromAttachment = attachment
	self:_reconcileConstraint()
end

function SocketMount._setToAttachment(self: SocketMountImpl, attachment: Attachment?): ()
	if self._toAttachment == attachment then
		return
	end

	self._toAttachment = attachment
	self:_reconcileConstraint()
end

function SocketMount._reconcileConstraint(self: SocketMountImpl): ()
	local hasAttachments = self._fromAttachment ~= nil and self._toAttachment ~= nil

	if self._rigid == nil and hasAttachments then
		local rigid = Instance.new("RigidConstraint")
		rigid.Name = self._options.rigidName or self._name or "AnatomySocketMount"
		rigid.Parent = getConstraintParent(self._options, self._fromAttachment, self._toAttachment)
		self._rigid = rigid
	end

	local rigid = self._rigid
	if rigid == nil then
		return
	end

	rigid.Attachment0 = self._fromAttachment
	rigid.Attachment1 = self._toAttachment
	rigid.Enabled = self._enabled and hasAttachments

	if rigid.Parent == nil and hasAttachments then
		rigid.Parent = getConstraintParent(self._options, self._fromAttachment, self._toAttachment)
	end
end

function SocketMount.deconstruct(self: SocketMountImpl): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	if self._fromAttachmentBindId ~= nil then
		self._fromEndpoint:unbindAttachmentChanged(self._fromAttachmentBindId)
	end
	if self._toAttachmentBindId ~= nil then
		self._toEndpoint:unbindAttachmentChanged(self._toAttachmentBindId)
	end

	if self._rigid ~= nil then
		self._rigid:Destroy()
	end

	self._fromAttachment = nil
	self._toAttachment = nil
	self._rigid = nil
	self._fromEndpoint = nil :: any
	self._toEndpoint = nil :: any
end

return SocketMount
