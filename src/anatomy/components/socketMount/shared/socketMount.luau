--!strict
--!optimize 2

local SocketEndpointLifecycleTypes = require(
	script.Parent.Parent.Parent.Parent.types.ports.components.socketEndpoint.shared.socketEndpointLifecycle
)
local SocketMountTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.socketMount.shared.socketMount)

type SocketEndpointLifecycle = SocketEndpointLifecycleTypes.SocketEndpointLifecycle

type MountAttachment = SocketMountTypes.MountAttachment
type SocketEndpoint = SocketMountTypes.SocketEndpoint
type SocketMount = SocketMountTypes.SocketMount
type SocketMountImpl = SocketMountTypes.SocketMountImpl
type SocketMountOptions = SocketMountTypes.SocketMountOptions

local function getConstraintParent(
	options: SocketMountOptions,
	from: Attachment?,
	to: Attachment?
): Instance?
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

local SocketMount = {}
SocketMount.__index = SocketMount

local function newOwned(
	fromEndpoint: SocketEndpoint,
	toEndpoint: SocketEndpoint,
	options: SocketMountOptions?,
	fromOwned: SocketEndpointLifecycle?,
	toOwned: SocketEndpointLifecycle?
): SocketMount
	local self: SocketMountImpl = setmetatable({}, SocketMount) :: SocketMountImpl

	self._fromOwned = fromOwned
	self._toOwned = toOwned
	self._options = options or {}
	self._name = self._options.name
	self._fromEndpoint = fromEndpoint
	self._toEndpoint = toEndpoint
	self._fromAttachment = nil
	self._toAttachment = nil
	self._rigid = nil
	self._fromAttachmentDisconnect = nil
	self._toAttachmentDisconnect = nil
	self._enabled = self._options.enabled ~= false
	self._destroyed = false

	self._fromAttachmentDisconnect = fromEndpoint:bindAttachmentChanged(
		function(attachment: Attachment?)
			self:_setFromAttachment(attachment)
		end,
		true
	)

	self._toAttachmentDisconnect = toEndpoint:bindAttachmentChanged(
		function(attachment: Attachment?)
			self:_setToAttachment(attachment)
		end,
		true
	)

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
	return self._enabled
		and self._rigid ~= nil
		and self._fromAttachment ~= nil
		and self._toAttachment ~= nil
end

function SocketMount.setEnabled(self: SocketMountImpl, enabled: boolean): ()
	assert(not self._destroyed, "Cannot use a destroyed SocketMount")
	if self._enabled == enabled then
		return
	end

	self._enabled = enabled
	self:_reconcileConstraint()
end

function SocketMount.refresh(self: SocketMountImpl): ()
	assert(not self._destroyed, "Cannot use a destroyed SocketMount")
	self._fromAttachment = (self._fromEndpoint :: SocketEndpoint):getAttachment()
	self._toAttachment = (self._toEndpoint :: SocketEndpoint):getAttachment()
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

	if self._fromAttachmentDisconnect ~= nil then
		self._fromAttachmentDisconnect()
	end
	if self._toAttachmentDisconnect ~= nil then
		self._toAttachmentDisconnect()
	end

	if self._fromOwned ~= nil then
		self._fromOwned:deconstruct()
	end
	if self._toOwned ~= nil then
		self._toOwned:deconstruct()
	end
	self._fromOwned = nil
	self._toOwned = nil

	if self._rigid ~= nil then
		self._rigid:Destroy()
	end

	self._fromAttachment = nil
	self._toAttachment = nil
	self._rigid = nil
	self._fromEndpoint = nil
	self._toEndpoint = nil
	self._fromAttachmentDisconnect = nil
	self._toAttachmentDisconnect = nil
end

local function new(
	fromEndpoint: SocketEndpoint,
	toEndpoint: SocketEndpoint,
	options: SocketMountOptions?
): SocketMount
	return newOwned(fromEndpoint, toEndpoint, options, nil, nil)
end
return { new = new, newOwned = newOwned }
