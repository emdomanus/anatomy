--!strict
--!optimize 2
--!native

local ComponentTypes = require(script.components)
local DefTypes = require(script.def)
local ManagerTypes = require(script.managers)
local ServiceTypes = require(script.services)

--------------------------------------------------------------------------------
-- Definition Types
--------------------------------------------------------------------------------

export type AnatomyRole = DefTypes.AnatomyRole
export type AnatomyCategory = DefTypes.AnatomyCategory
export type AnatomyId = DefTypes.AnatomyId
export type LayerId = DefTypes.LayerId
export type SocketName = DefTypes.SocketName
export type SurfaceName = DefTypes.SurfaceName
export type PartName = DefTypes.PartName
export type MountName = DefTypes.MountName
export type AnatomyPathStep = DefTypes.AnatomyPathStep
export type AnatomyPath = DefTypes.AnatomyPath
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type SocketDescriptor = DefTypes.SocketDescriptor
export type SurfaceDescriptor = DefTypes.SurfaceDescriptor
export type PartDescriptor = DefTypes.PartDescriptor
export type SocketAddress = DefTypes.SocketAddress
export type MountSpec = DefTypes.MountSpec
export type RecognizeOptions = DefTypes.RecognizeOptions
export type RecognizeConfig = DefTypes.RecognizeConfig
export type InstancePolicy = DefTypes.InstancePolicy

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

export type AnatomySocket = ComponentTypes.AnatomySocket
export type AnatomySurface = ComponentTypes.AnatomySurface
export type AnatomyPart = ComponentTypes.AnatomyPart
export type AnatomyTemplate = ComponentTypes.AnatomyTemplate
export type AnatomyInstance = ComponentTypes.AnatomyInstance
export type SocketBinding = ComponentTypes.SocketBinding
export type SocketEndpoint = ComponentTypes.SocketEndpoint
export type MountAttachment = ComponentTypes.MountAttachment
export type SocketAttachmentChangedCallback = ComponentTypes.SocketAttachmentChangedCallback
export type SocketMount = ComponentTypes.SocketMount
export type SocketMountOptions = ComponentTypes.SocketMountOptions

--------------------------------------------------------------------------------
-- Managers
--------------------------------------------------------------------------------

export type AnatomyHost = ManagerTypes.AnatomyHost
export type AnatomyHostOptions = ManagerTypes.AnatomyHostOptions
export type AnatomyHostLayer = ManagerTypes.AnatomyHostLayer
export type AnatomyHostLayerOptions = ManagerTypes.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = ManagerTypes.AnatomyHostSocketQuery
export type AnatomyHostSocketAddress = ManagerTypes.AnatomyHostSocketAddress
export type AnatomyInstanceSocketAddress = ManagerTypes.AnatomyInstanceSocketAddress
export type AnatomyHostMountEndpoint = ManagerTypes.AnatomyHostMountEndpoint
export type AnatomyHostMountConfig = ManagerTypes.AnatomyHostMountConfig

--------------------------------------------------------------------------------
-- Services
--------------------------------------------------------------------------------

export type AnatomyService = ServiceTypes.AnatomyService

return {}
