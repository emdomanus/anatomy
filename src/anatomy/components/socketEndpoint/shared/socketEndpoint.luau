--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Parent.Parent.types.components.socketEndpoint)

export type MountAttachment = Types.MountAttachment
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketEndpoint = Types.SocketEndpoint

type StaticAttachmentEndpoint = SocketEndpoint & {
	_attachment: Attachment?,
}

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
	}, StaticAttachmentEndpoint) :: any
end

return SocketEndpoint
