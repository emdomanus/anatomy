--!strict
--!optimize 2

local SocketEndpointTypes = require(
	script.Parent.Parent.Parent.Parent.types.ports.components.socketEndpoint.shared.socketEndpoint
)
local StaticAttachmentEndpointTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.socketEndpoint.shared.socketEndpoint
)

type MountAttachment = SocketEndpointTypes.MountAttachment
type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
type SocketEndpoint = SocketEndpointTypes.SocketEndpoint

type StaticAttachmentEndpoint = StaticAttachmentEndpointTypes.StaticAttachmentEndpointImpl

local StaticAttachmentEndpoint = {}
StaticAttachmentEndpoint.__index = StaticAttachmentEndpoint

function StaticAttachmentEndpoint.getAttachment(self: StaticAttachmentEndpoint): Attachment?
	return self._attachment
end

function StaticAttachmentEndpoint.bindAttachmentChanged(
	self: StaticAttachmentEndpoint,
	callback: SocketAttachmentChangedCallback,
	runInitially: boolean?
): () -> ()
	if runInitially == true then
		callback(self._attachment)
	end

	return function() end
end

local SocketEndpoint = {}

function SocketEndpoint.fromAttachment(attachment: Attachment?): SocketEndpoint
	return setmetatable({
		_attachment = attachment,
	}, StaticAttachmentEndpoint) :: StaticAttachmentEndpoint
end

return SocketEndpoint
