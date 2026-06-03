--!strict
--!optimize 2
--!native

local Anatomy = require(script.anatomy)
local Types = require(script.anatomy.types)

export type AnatomyRole = Types.AnatomyRole
export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyId = Types.AnatomyId
export type LayerId = Types.LayerId
export type PartName = Types.PartName
export type AnatomyPathStep = Types.AnatomyPathStep
export type AnatomyPath = Types.AnatomyPath
export type MountAttachment = Types.MountAttachment
export type DescriptorMetadata = Types.DescriptorMetadata
export type NameGuard<TName> = Types.NameGuard<TName>
export type SocketDescriptor<TSocketName> = Types.SocketDescriptor<TSocketName>
export type SurfaceDescriptor<TSurfaceName> = Types.SurfaceDescriptor<TSurfaceName>
export type PartDescriptor = Types.PartDescriptor
export type RecognizeOptions<TSocketName, TSurfaceName> = Types.RecognizeOptions<TSocketName, TSurfaceName>
export type RecognizeConfig<TSocketName, TSurfaceName> = Types.RecognizeConfig<TSocketName, TSurfaceName>
export type InstancePolicy = Types.InstancePolicy
export type SocketEndpoint = Types.SocketEndpoint
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketChangedCallback<TSocketName> = Types.SocketChangedCallback<TSocketName>

export type AnatomySocket<TSocketName> = Types.AnatomySocket<TSocketName>
export type AnatomySurface<TSurfaceName> = Types.AnatomySurface<TSurfaceName>
export type AnatomyPart = Types.AnatomyPart
export type AnatomyTemplate<TSocketName, TSurfaceName> = Types.AnatomyTemplate<TSocketName, TSurfaceName>
export type AnatomyInstance<TSocketName, TSurfaceName> = Types.AnatomyInstance<TSocketName, TSurfaceName>
export type SocketBinding<TSocketName> = Types.SocketBinding<TSocketName>
export type SocketMount = Types.SocketMount
export type SocketMountOptions = Types.SocketMountOptions

export type AnatomyHost<TSocketName, TSurfaceName> = Types.AnatomyHost<TSocketName, TSurfaceName>
export type AnatomyHostOptions<TSocketName, TSurfaceName> = Types.AnatomyHostOptions<TSocketName, TSurfaceName>
export type AnatomyHostLayer<TSocketName, TSurfaceName> = Types.AnatomyHostLayer<TSocketName, TSurfaceName>
export type AnatomyHostLayerOptions = Types.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = Types.AnatomyHostSocketQuery
export type AnatomyHostSurfaceQuery = Types.AnatomyHostSurfaceQuery
export type AnatomyHostSocketAddress<TSocketName> = Types.AnatomyHostSocketAddress<TSocketName>
export type AnatomyInstanceSocketAddress<TSocketName, TSurfaceName> =
	Types.AnatomyInstanceSocketAddress<TSocketName, TSurfaceName>
export type AnatomyHostMountEndpoint<TSocketName, TSurfaceName> =
	Types.AnatomyHostMountEndpoint<TSocketName, TSurfaceName>
export type AnatomyHostMountConfig<TSocketName, TSurfaceName> = Types.AnatomyHostMountConfig<TSocketName, TSurfaceName>
export type SurfaceChangedCallback<TSurfaceName> = Types.SurfaceChangedCallback<TSurfaceName>
export type SurfaceAddedCallback<TSocketName, TSurfaceName> = Types.SurfaceAddedCallback<TSocketName, TSurfaceName>
export type SurfaceRemovedCallback<TSocketName, TSurfaceName> =
	Types.SurfaceRemovedCallback<TSocketName, TSurfaceName>

return Anatomy
