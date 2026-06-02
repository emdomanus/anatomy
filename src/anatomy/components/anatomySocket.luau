--!strict
--!optimize 2
--!native

local Hook = require(script.Parent.Parent.Parent.externalPackages.hook)
local Types = require(script.Parent.Parent.types.components.anatomySocket)

export type AnatomyPath = Types.AnatomyPath
export type AnatomySocket = Types.AnatomySocket
export type AnatomySocketImpl = Types.AnatomySocketImpl
export type DescriptorMetadata = Types.DescriptorMetadata
export type MountAttachment = Types.MountAttachment
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketName = Types.SocketName

local AnatomySocket = {}
AnatomySocket.__index = AnatomySocket

function AnatomySocket.new(
	owner: any,
	name: SocketName,
	path: AnatomyPath,
	attachment: Attachment?,
	metadata: DescriptorMetadata?
): AnatomySocket
	local self: AnatomySocketImpl = setmetatable({}, AnatomySocket) :: any

	self._owner = owner
	self._name = name
	self._path = path
	self._attachment = attachment
	self._metadata = metadata
	self._attachmentChangedHook = Hook.new()
	self._destroyed = false

	return self
end

function AnatomySocket.fromDescriptor(
	owner: any,
	descriptor: {
		name: SocketName,
		path: AnatomyPath,
		metadata: DescriptorMetadata?,
	},
	attachment: Attachment?
): AnatomySocket
	return AnatomySocket.new(owner, descriptor.name, descriptor.path, attachment, descriptor.metadata)
end

function AnatomySocket.getName(self: AnatomySocketImpl): SocketName
	return self._name
end

function AnatomySocket.getAttachment(self: AnatomySocketImpl): Attachment?
	if self._destroyed then
		return nil
	end

	return self._attachment
end

function AnatomySocket.getPath(self: AnatomySocketImpl): AnatomyPath
	return self._path
end

function AnatomySocket.getMetadata(self: AnatomySocketImpl): DescriptorMetadata?
	return self._metadata
end

function AnatomySocket.bindAttachmentChanged(
	self: AnatomySocketImpl,
	callback: SocketAttachmentChangedCallback,
	runInitially: boolean?
): number
	if runInitially == true then
		callback(self:getAttachment())
	end

	return self._attachmentChangedHook:add(callback)
end

function AnatomySocket.unbindAttachmentChanged(self: AnatomySocketImpl, hookId: number): boolean
	return self._attachmentChangedHook:remove(hookId)
end

-- Reserved for a future live-socket mode where resolved attachments can retarget
-- inside one AnatomyInstance.
function AnatomySocket._setAttachment(self: AnatomySocketImpl, attachment: Attachment?): ()
	if self._attachment == attachment then
		return
	end

	self._attachment = attachment
	self._attachmentChangedHook:fire(attachment)
end

function AnatomySocket.deconstruct(self: AnatomySocketImpl): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._attachmentChangedHook:deconstruct()
	self._attachment = nil
	self._owner = nil
end

return AnatomySocket
