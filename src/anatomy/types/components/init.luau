--!strict
--!optimize 2
--!native

local AnatomyInstanceTypes = require(script.anatomyInstance)
local AnatomyPartTypes = require(script.anatomyPart)
local AnatomySocketTypes = require(script.anatomySocket)
local AnatomySurfaceTypes = require(script.anatomySurface)
local AnatomyTemplateTypes = require(script.anatomyTemplate)
local SocketBindingTypes = require(script.socketBinding)
local SocketEndpointTypes = require(script.socketEndpoint)
local SocketMountTypes = require(script.socketMount)

export type AnatomySocket = AnatomySocketTypes.AnatomySocket
export type AnatomySurface = AnatomySurfaceTypes.AnatomySurface
export type AnatomyPart = AnatomyPartTypes.AnatomyPart
export type AnatomyTemplate = AnatomyTemplateTypes.AnatomyTemplate
export type AnatomyInstance = AnatomyInstanceTypes.AnatomyInstance
export type SocketBinding = SocketBindingTypes.SocketBinding
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions

return {}
