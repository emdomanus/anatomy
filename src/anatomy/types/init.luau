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
export type AnatomyPathStep = DefTypes.AnatomyPathStep
export type AnatomyPath = DefTypes.AnatomyPath
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type NameGuard<TName> = DefTypes.NameGuard<TName>
export type SocketDescriptor<SocketT> = DefTypes.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = DefTypes.TagDescriptor<TagT>
export type RecognizeOptions<SocketT, TagT> = DefTypes.RecognizeOptions<SocketT, TagT>
export type RecognizeConfig<SocketT, TagT> = DefTypes.RecognizeConfig<SocketT, TagT>
export type InstancePolicy = DefTypes.InstancePolicy

--------------------------------------------------------------------------------
-- Components
--------------------------------------------------------------------------------

export type AnatomySocket<SocketT> = ComponentTypes.AnatomySocket<SocketT>
export type AnatomyTaggedElement<TagT> = ComponentTypes.AnatomyTaggedElement<TagT>
export type AnatomyTemplate<SocketT, TagT> = ComponentTypes.AnatomyTemplate<SocketT, TagT>
export type AnatomyInstance<SocketT, TagT> = ComponentTypes.AnatomyInstance<SocketT, TagT>
export type SocketBinding<SocketT> = ComponentTypes.SocketBinding<SocketT>
export type SocketEndpoint = ComponentTypes.SocketEndpoint
export type MountAttachment = ComponentTypes.MountAttachment
export type SocketAttachmentChangedCallback = ComponentTypes.SocketAttachmentChangedCallback
export type SocketChangedCallback<SocketT> = ComponentTypes.SocketChangedCallback<SocketT>
export type SocketMount = ComponentTypes.SocketMount
export type SocketMountOptions = ComponentTypes.SocketMountOptions

--------------------------------------------------------------------------------
-- Managers
--------------------------------------------------------------------------------

export type AnatomyHost<SocketT, TagT> = ManagerTypes.AnatomyHost<SocketT, TagT>
export type AnatomyHostOptions<SocketT> = ManagerTypes.AnatomyHostOptions<SocketT>
export type AnatomyHostLayer<SocketT, TagT> = ManagerTypes.AnatomyHostLayer<SocketT, TagT>
export type AnatomyHostLayerOptions = ManagerTypes.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = ManagerTypes.AnatomyHostSocketQuery
export type AnatomyHostTagQuery = ManagerTypes.AnatomyHostTagQuery
export type AnatomyHostSocketAddress<SocketT> = ManagerTypes.AnatomyHostSocketAddress<SocketT>
export type AnatomyInstanceSocketAddress<SocketT> = ManagerTypes.AnatomyInstanceSocketAddress<SocketT>
export type AnatomyHostMountEndpoint<SocketT> = ManagerTypes.AnatomyHostMountEndpoint<SocketT>
export type AnatomyHostMountConfig<SocketT> = ManagerTypes.AnatomyHostMountConfig<SocketT>
export type TagChangedCallback<TagT> = ManagerTypes.TagChangedCallback<TagT>

return {}
