--!strict
--!optimize 2
--!native

local Types = require(script.types)
local AnatomyService = require(script.services.anatomyService)

export type AnatomyRole = Types.AnatomyRole
export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyId = Types.AnatomyId
export type LayerId = Types.LayerId
export type SocketName = Types.SocketName
export type SurfaceName = Types.SurfaceName
export type PartName = Types.PartName
export type MountName = Types.MountName
export type AnatomyPathStep = Types.AnatomyPathStep
export type AnatomyPath = Types.AnatomyPath
export type MountAttachment = Types.MountAttachment
export type DescriptorMetadata = Types.DescriptorMetadata
export type SocketDescriptor = Types.SocketDescriptor
export type SurfaceDescriptor = Types.SurfaceDescriptor
export type PartDescriptor = Types.PartDescriptor
export type SocketAddress = Types.SocketAddress
export type MountSpec = Types.MountSpec
export type RecognizeOptions = Types.RecognizeOptions
export type RecognizeConfig = Types.RecognizeConfig
export type InstancePolicy = Types.InstancePolicy
export type SocketEndpoint = Types.SocketEndpoint
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback

export type AnatomySocket = Types.AnatomySocket
export type AnatomySurface = Types.AnatomySurface
export type AnatomyPart = Types.AnatomyPart
export type AnatomyTemplate = Types.AnatomyTemplate
export type AnatomyInstance = Types.AnatomyInstance
export type SocketBinding = Types.SocketBinding
export type SocketMount = Types.SocketMount
export type SocketMountOptions = Types.SocketMountOptions

export type AnatomyHost = Types.AnatomyHost
export type AnatomyHostOptions = Types.AnatomyHostOptions
export type AnatomyHostLayer = Types.AnatomyHostLayer
export type AnatomyHostLayerOptions = Types.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = Types.AnatomyHostSocketQuery
export type AnatomyHostSocketAddress = Types.AnatomyHostSocketAddress
export type AnatomyInstanceSocketAddress = Types.AnatomyInstanceSocketAddress
export type AnatomyHostMountEndpoint = Types.AnatomyHostMountEndpoint
export type AnatomyHostMountConfig = Types.AnatomyHostMountConfig

export type AnatomyService = Types.AnatomyService

return AnatomyService
