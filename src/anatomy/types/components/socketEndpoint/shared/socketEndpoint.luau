--!strict
--!optimize 2

local SocketEndpointTypes = require(
	script.Parent.Parent.Parent.Parent.ports.components.socketEndpoint.shared.socketEndpoint
)

export type StaticAttachmentEndpointImpl =
	SocketEndpointTypes.SocketEndpoint
	& { _attachment: Attachment? }
return {}
