--!strict
--!optimize 2
--!native

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet)
local DefTypes = require(script.Parent.Parent.Parent.Parent.types.def)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket)

export type AnatomyPath = Types.AnatomyPath
export type AnatomySocket<TSocketName> = Types.AnatomySocket<TSocketName>
export type AnatomySocketImpl<TSocketName> = Types.AnatomySocketImpl<TSocketName>
export type DescriptorMetadata = Types.DescriptorMetadata
export type MountAttachment = Types.MountAttachment
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketDescriptor<TSocketName> = DefTypes.SocketDescriptor<TSocketName>

local AnatomySocket = {}
AnatomySocket.__index = AnatomySocket

function AnatomySocket.new<TSocketName>(
	owner: any,
	name: TSocketName,
	path: AnatomyPath,
	attachment: Attachment?,
	metadata: DescriptorMetadata?
): AnatomySocket<TSocketName>
	local self: AnatomySocketImpl<TSocketName> = setmetatable({}, AnatomySocket) :: any

	self._owner = owner
	self._name = name
	self._path = path
	self._attachment = attachment
	self._metadata = metadata
	self._attachmentChangedCallbacks = CallbackSet.new()
	self._destroyed = false

	return self
end

function AnatomySocket.fromDescriptor<TSocketName>(
	owner: any,
	descriptor: SocketDescriptor<TSocketName>,
	attachment: Attachment?
): AnatomySocket<TSocketName>
	return AnatomySocket.new(owner, descriptor.name, descriptor.path, attachment, descriptor.metadata)
end

function AnatomySocket.getName<TSocketName>(self: AnatomySocketImpl<TSocketName>): TSocketName
	return self._name
end

function AnatomySocket.getAttachment<TSocketName>(self: AnatomySocketImpl<TSocketName>): Attachment?
	if self._destroyed then
		return nil
	end

	return self._attachment
end

function AnatomySocket.getPath<TSocketName>(self: AnatomySocketImpl<TSocketName>): AnatomyPath
	return self._path
end

function AnatomySocket.getMetadata<TSocketName>(self: AnatomySocketImpl<TSocketName>): DescriptorMetadata?
	return self._metadata
end

function AnatomySocket.bindAttachmentChanged<TSocketName>(
	self: AnatomySocketImpl<TSocketName>,
	callback: SocketAttachmentChangedCallback,
	runInitially: boolean?
): () -> ()
	if runInitially == true then
		callback(self:getAttachment())
	end

	return CallbackSet.bind(self._attachmentChangedCallbacks, callback)
end

-- Reserved for a future live-socket mode where resolved attachments can retarget
-- inside one AnatomyInstance.
function AnatomySocket._setAttachment<TSocketName>(self: AnatomySocketImpl<TSocketName>, attachment: Attachment?): ()
	if self._attachment == attachment then
		return
	end

	self._attachment = attachment
	CallbackSet.fire(self._attachmentChangedCallbacks, attachment)
end

function AnatomySocket.deconstruct<TSocketName>(self: AnatomySocketImpl<TSocketName>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	table.clear(self._attachmentChangedCallbacks)
	self._attachment = nil
	self._owner = nil
end

return AnatomySocket
