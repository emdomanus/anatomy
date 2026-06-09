--!strict
--!optimize 2
--!native

local AnatomyInstanceTypes = require(script.anatomyInstance)
local AnatomyPartTypes = require(script.anatomyPart)
local AnatomySocketTypes = require(script.anatomySocket)
local AnatomyTaggedElementTypes = require(script.anatomyTaggedElement)
local AnatomyTemplateTypes = require(script.anatomyTemplate)
local SocketBindingTypes = require(script.socketBinding)
local SocketEndpointTypes = require(script.socketEndpoint)
local SocketMountTypes = require(script.socketMount)

export type AnatomySocket<TSocketName> = AnatomySocketTypes.AnatomySocket<TSocketName>
export type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
export type AnatomyPart = AnatomyPartTypes.AnatomyPart
export type AnatomyTemplate<TSocketName, TSurfaceName> = AnatomyTemplateTypes.AnatomyTemplate<TSocketName, TSurfaceName>
export type AnatomyInstance<TSocketName, TSurfaceName> = AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>
export type SocketBinding<TSocketName> = SocketBindingTypes.SocketBinding<TSocketName>
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
export type SocketChangedCallback<TSocketName> = SocketBindingTypes.SocketChangedCallback<TSocketName>
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions

return {}
