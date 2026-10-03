--!strict
--!optimize 2

local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.types.def.anatomy.shared.anatomy)
local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket.shared.anatomySocket)

type AnatomyPath = AnatomyTypes.AnatomyPath
type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type AnatomySocketOwned<SocketT> = AnatomySocketTypes.AnatomySocketOwned<SocketT>
type AnatomySocketImpl<SocketT> = AnatomySocketTypes.AnatomySocketImpl<SocketT>
type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
type SocketDescriptor<SocketT> = AnatomyTypes.SocketDescriptor<SocketT>

local AnatomySocket = {}
AnatomySocket.__index = AnatomySocket

function AnatomySocket.new<SocketT>(
	name: SocketT,
	path: AnatomyPath,
	attachment: Attachment,
	metadata: DescriptorMetadata?
): AnatomySocketOwned<SocketT>
	local self: AnatomySocketImpl<SocketT> =
		setmetatable({}, AnatomySocket) :: AnatomySocketImpl<SocketT>

	self._name = name
	self._path = path
	self._attachment = attachment
	self._metadata = metadata
	self._destroyed = false

	return self
end

function AnatomySocket.fromDescriptor<SocketT>(
	descriptor: SocketDescriptor<SocketT>,
	attachment: Attachment
): AnatomySocketOwned<SocketT>
	return AnatomySocket.new(descriptor.name, descriptor.path, attachment, descriptor.metadata)
end

function AnatomySocket.getName<SocketT>(self: AnatomySocketImpl<SocketT>): SocketT
	return self._name
end

function AnatomySocket.getAttachment<SocketT>(self: AnatomySocketImpl<SocketT>): Attachment
	assert(not self._destroyed, "Cannot use a destroyed AnatomySocket")
	return self._attachment
end

function AnatomySocket.getPath<SocketT>(self: AnatomySocketImpl<SocketT>): AnatomyPath
	return self._path
end

function AnatomySocket.getMetadata<SocketT>(self: AnatomySocketImpl<SocketT>): DescriptorMetadata?
	return self._metadata
end

function AnatomySocket.deconstruct<SocketT>(self: AnatomySocketImpl<SocketT>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
end

return AnatomySocket
