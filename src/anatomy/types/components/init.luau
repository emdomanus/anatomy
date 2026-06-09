--!strict
--!optimize 2
--!native

local AnatomyInstanceTypes = require(script.anatomyInstance)
local AnatomySocketTypes = require(script.anatomySocket)
local AnatomyTaggedElementTypes = require(script.anatomyTaggedElement)
local AnatomyTemplateTypes = require(script.anatomyTemplate)
local SocketBindingTypes = require(script.socketBinding)
local SocketEndpointTypes = require(script.socketEndpoint)
local SocketMountTypes = require(script.socketMount)

export type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
export type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
export type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>
export type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<SocketT, TagT>
export type SocketBinding<SocketT> = SocketBindingTypes.SocketBinding<SocketT>
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
export type SocketChangedCallback<SocketT> = SocketBindingTypes.SocketChangedCallback<SocketT>
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions

return {}
