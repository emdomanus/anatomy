--!strict
--!optimize 2
--!native

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet)
local DefTypes = require(script.Parent.Parent.Parent.Parent.types.def)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket)

export type AnatomyPath = Types.AnatomyPath
export type AnatomySocket<SocketT> = Types.AnatomySocket<SocketT>
export type AnatomySocketImpl<SocketT> = Types.AnatomySocketImpl<SocketT>
export type DescriptorMetadata = Types.DescriptorMetadata
export type MountAttachment = Types.MountAttachment
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketDescriptor<SocketT> = DefTypes.SocketDescriptor<SocketT>

local AnatomySocket = {}
AnatomySocket.__index = AnatomySocket

function AnatomySocket.new<SocketT>(
	owner: any,
	name: SocketT,
	path: AnatomyPath,
	attachment: Attachment?,
	metadata: DescriptorMetadata?
): AnatomySocket<SocketT>
	local self: AnatomySocketImpl<SocketT> = setmetatable({}, AnatomySocket) :: any

	self._owner = owner
	self._name = name
	self._path = path
	self._attachment = attachment
	self._metadata = metadata
	self._attachmentChangedCallbacks = CallbackSet.new()
	self._destroyed = false

	return self
end

function AnatomySocket.fromDescriptor<SocketT>(
	owner: any,
	descriptor: SocketDescriptor<SocketT>,
	attachment: Attachment?
): AnatomySocket<SocketT>
	return AnatomySocket.new(owner, descriptor.name, descriptor.path, attachment, descriptor.metadata)
end

function AnatomySocket.getName<SocketT>(self: AnatomySocketImpl<SocketT>): SocketT
	return self._name
end

function AnatomySocket.getAttachment<SocketT>(self: AnatomySocketImpl<SocketT>): Attachment?
	if self._destroyed then
		return nil
	end

	return self._attachment
end

function AnatomySocket.getPath<SocketT>(self: AnatomySocketImpl<SocketT>): AnatomyPath
	return self._path
end

function AnatomySocket.getMetadata<SocketT>(self: AnatomySocketImpl<SocketT>): DescriptorMetadata?
	return self._metadata
end

function AnatomySocket.bindAttachmentChanged<SocketT>(
	self: AnatomySocketImpl<SocketT>,
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
function AnatomySocket._setAttachment<SocketT>(self: AnatomySocketImpl<SocketT>, attachment: Attachment?): ()
	if self._attachment == attachment then
		return
	end

	self._attachment = attachment
	CallbackSet.fire(self._attachmentChangedCallbacks, attachment)
end

function AnatomySocket.deconstruct<SocketT>(self: AnatomySocketImpl<SocketT>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	table.clear(self._attachmentChangedCallbacks)
	self._attachment = nil
	self._owner = nil
end

return AnatomySocket
