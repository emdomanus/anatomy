--!strict
--!optimize 2
--!native

export type MountAttachment = Attachment
export type SocketAttachmentChangedCallback = (MountAttachment?) -> ()

export type SocketEndpoint = {
	getAttachment: (self: any) -> MountAttachment?,
	bindAttachmentChanged: (
		self: any,
		callback: SocketAttachmentChangedCallback,
		runInitially: boolean?
	) -> number,
	unbindAttachmentChanged: (self: any, hookId: number) -> boolean,
}

return {}
