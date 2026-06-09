--!strict
--!optimize 2
--!native

local ComponentTypes = require(script.components)
local DefTypes = require(script.def)
local ManagerTypes = require(script.managers)

--------------------------------------------------------------------------------
-- Definition Types
--------------------------------------------------------------------------------

export type AnatomyRole = DefTypes.AnatomyRole
export type AnatomyCategory = DefTypes.AnatomyCategory
export type AnatomyId = DefTypes.AnatomyId
export type LayerId = DefTypes.LayerId
export type PartName = DefTypes.PartName
export type AnatomyPathStep = DefTypes.AnatomyPathStep
export type AnatomyPath = DefTypes.AnatomyPath
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type NameGuard<TName> = DefTypes.NameGuard<TName>
export type SocketDescriptor<TSocketName> = DefTypes.SocketDescriptor<TSocketName>
export type TagDescriptor<TagT> = DefTypes.TagDescriptor<TagT>
export type PartDescriptor = DefTypes.PartDescriptor
export type RecognizeOptions<TSocketName, TSurfaceName> = DefTypes.RecognizeOptions<TSocketName, TSurfaceName>
export type RecognizeConfig<TSocketName, TSurfaceName> = DefTypes.RecognizeConfig<TSocketName, TSurfaceName>
export type InstancePolicy = DefTypes.InstancePolicy

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

export type AnatomySocket<TSocketName> = ComponentTypes.AnatomySocket<TSocketName>
export type AnatomyTaggedElement<TagT> = ComponentTypes.AnatomyTaggedElement<TagT>
export type AnatomyPart = ComponentTypes.AnatomyPart
export type AnatomyTemplate<TSocketName, TSurfaceName> = ComponentTypes.AnatomyTemplate<TSocketName, TSurfaceName>
export type AnatomyInstance<TSocketName, TSurfaceName> = ComponentTypes.AnatomyInstance<TSocketName, TSurfaceName>
export type SocketBinding<TSocketName> = ComponentTypes.SocketBinding<TSocketName>
export type SocketEndpoint = ComponentTypes.SocketEndpoint
export type MountAttachment = ComponentTypes.MountAttachment
export type SocketAttachmentChangedCallback = ComponentTypes.SocketAttachmentChangedCallback
export type SocketChangedCallback<TSocketName> = ComponentTypes.SocketChangedCallback<TSocketName>
export type SocketMount = ComponentTypes.SocketMount
export type SocketMountOptions = ComponentTypes.SocketMountOptions

--------------------------------------------------------------------------------
-- Managers
--------------------------------------------------------------------------------

export type AnatomyHost<TSocketName, TSurfaceName> = ManagerTypes.AnatomyHost<TSocketName, TSurfaceName>
export type AnatomyHostOptions<TSocketName, TSurfaceName> = ManagerTypes.AnatomyHostOptions<TSocketName, TSurfaceName>
export type AnatomyHostLayer<TSocketName, TSurfaceName> = ManagerTypes.AnatomyHostLayer<TSocketName, TSurfaceName>
export type AnatomyHostLayerOptions = ManagerTypes.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = ManagerTypes.AnatomyHostSocketQuery
export type AnatomyHostTagQuery = ManagerTypes.AnatomyHostTagQuery
export type AnatomyHostSocketAddress<TSocketName> = ManagerTypes.AnatomyHostSocketAddress<TSocketName>
export type AnatomyInstanceSocketAddress<TSocketName, TSurfaceName> =
	ManagerTypes.AnatomyInstanceSocketAddress<TSocketName, TSurfaceName>
export type AnatomyHostMountEndpoint<TSocketName, TSurfaceName> =
	ManagerTypes.AnatomyHostMountEndpoint<TSocketName, TSurfaceName>
export type AnatomyHostMountConfig<TSocketName, TSurfaceName> =
	ManagerTypes.AnatomyHostMountConfig<TSocketName, TSurfaceName>
export type TagChangedCallback<TagT> = ManagerTypes.TagChangedCallback<TagT>

return {}
