--!strict
--!optimize 2

local CallbackSet = require(script.Parent.Parent.Parent.Parent.utils.callbackSet.shared.callbackSet)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.types.def.anatomy.shared.anatomy)
local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket.shared.anatomySocket)
local SocketEndpointTypes = require(
	script.Parent.Parent.Parent.Parent.types.ports.components.socketEndpoint.shared.socketEndpoint
)

type AnatomyPath = AnatomyTypes.AnatomyPath
type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type AnatomySocketOwned<SocketT> = AnatomySocketTypes.AnatomySocketOwned<SocketT>
type AnatomySocketImpl<SocketT> = AnatomySocketTypes.AnatomySocketImpl<SocketT>
type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
type MountAttachment = SocketEndpointTypes.MountAttachment
type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
type SocketDescriptor<SocketT> = AnatomyTypes.SocketDescriptor<SocketT>

local AnatomySocket = {}
AnatomySocket.__index = AnatomySocket

function AnatomySocket.new<SocketT>(
	name: SocketT,
	path: AnatomyPath,
	attachment: Attachment?,
	metadata: DescriptorMetadata?
): AnatomySocketOwned<SocketT>
	local self: AnatomySocketImpl<SocketT> =
		setmetatable({}, AnatomySocket) :: AnatomySocketImpl<SocketT>

	self._name = name
	self._path = path
	self._attachment = attachment
	self._metadata = metadata
	self._attachmentChangedCallbacks = {}
	self._destroyed = false

	return self
end

function AnatomySocket.fromDescriptor<SocketT>(
	descriptor: SocketDescriptor<SocketT>,
	attachment: Attachment?
): AnatomySocketOwned<SocketT>
	return AnatomySocket.new(descriptor.name, descriptor.path, attachment, descriptor.metadata)
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
	assert(not self._destroyed, "Cannot subscribe to a destroyed AnatomySocket")
	if runInitially == true then
		callback(self:getAttachment())
	end

	return CallbackSet.bind(self._attachmentChangedCallbacks, callback)
end

function AnatomySocket.deconstruct<SocketT>(self: AnatomySocketImpl<SocketT>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._attachment = nil
	CallbackSet.fire(self._attachmentChangedCallbacks, nil)
	table.clear(self._attachmentChangedCallbacks)
end

return AnatomySocket
