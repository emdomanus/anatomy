--!strict
--!optimize 2

export type MountAttachment = Attachment
export type SocketAttachmentChangedCallback = (MountAttachment?) -> ()
export type SocketEndpoint = {
	read getAttachment: (self: SocketEndpoint) -> MountAttachment?,
	read bindAttachmentChanged: (
		self: SocketEndpoint,
		callback: SocketAttachmentChangedCallback,
		runInitially: boolean?
	) -> () -> (),
}
return {}
