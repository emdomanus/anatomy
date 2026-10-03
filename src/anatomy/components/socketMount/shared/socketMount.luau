--!strict
--!optimize 2

local SocketMountTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.socketMount.shared.socketMount)

type SocketMount = SocketMountTypes.SocketMount
type SocketMountImpl = SocketMountTypes.SocketMountImpl
type SocketMountOptions = SocketMountTypes.SocketMountOptions

local SocketMount = {}
SocketMount.__index = SocketMount

local function new(from: Attachment?, to: Attachment?, options: SocketMountOptions?): SocketMount
	local rigid = Instance.new("RigidConstraint")
	rigid.Name = if options
		then options.rigidName or options.name or "AnatomySocketMount"
		else "AnatomySocketMount"
	rigid.Attachment0 = from
	rigid.Attachment1 = to
	local enabled = options == nil or options.enabled ~= false
	rigid.Enabled = enabled and from ~= nil and to ~= nil
	rigid.Parent = if options then options.parent else nil

	local self: SocketMountImpl = setmetatable({}, SocketMount) :: SocketMountImpl
	self._name = if options then options.name else nil
	self._rigid = rigid
	self._enabled = enabled
	return self
end

function SocketMount.getName(self: SocketMountImpl): string?
	return self._name
end

function SocketMount.getFromAttachment(self: SocketMountImpl): Attachment?
	local rigid = self._rigid
	return if rigid then rigid.Attachment0 else nil
end

function SocketMount.getToAttachment(self: SocketMountImpl): Attachment?
	local rigid = self._rigid
	return if rigid then rigid.Attachment1 else nil
end

function SocketMount.getConstraint(self: SocketMountImpl): RigidConstraint?
	return self._rigid
end

function SocketMount.isConnected(self: SocketMountImpl): boolean
	local rigid = self._rigid
	-- Configured connection state, not a claim about physics or ancestry.
	return rigid ~= nil and rigid.Enabled and rigid.Attachment0 ~= nil and rigid.Attachment1 ~= nil
end

function SocketMount.setAttachments(self: SocketMountImpl, from: Attachment?, to: Attachment?): ()
	local rigid = assert(self._rigid, "Cannot use a destroyed SocketMount")
	rigid.Attachment0 = from
	rigid.Attachment1 = to
	rigid.Enabled = self._enabled and from ~= nil and to ~= nil
end

function SocketMount.setEnabled(self: SocketMountImpl, enabled: boolean): ()
	local rigid = assert(self._rigid, "Cannot use a destroyed SocketMount")
	self._enabled = enabled
	rigid.Enabled = enabled and rigid.Attachment0 ~= nil and rigid.Attachment1 ~= nil
end

function SocketMount.setParent(self: SocketMountImpl, parent: Instance?): ()
	local rigid = assert(self._rigid, "Cannot use a destroyed SocketMount")
	rigid.Parent = parent
end

function SocketMount.deconstruct(self: SocketMountImpl): ()
	local rigid = self._rigid
	if rigid == nil then
		return
	end
	self._rigid = nil
	rigid:Destroy()
end

return { new = new }
