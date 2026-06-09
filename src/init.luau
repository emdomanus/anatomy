--!strict
--!optimize 2
--!native

local Anatomy = require(script.anatomy)
local Types = require(script.anatomy.types)

export type AnatomyRole = Types.AnatomyRole
export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyId = Types.AnatomyId
export type LayerId = Types.LayerId
export type AnatomyPathStep = Types.AnatomyPathStep
export type AnatomyPath = Types.AnatomyPath
export type MountAttachment = Types.MountAttachment
export type DescriptorMetadata = Types.DescriptorMetadata
export type NameGuard<TName> = Types.NameGuard<TName>
export type SocketDescriptor<SocketT> = Types.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = Types.TagDescriptor<TagT>
export type RecognizeOptions<SocketT, TagT> = Types.RecognizeOptions<SocketT, TagT>
export type RecognizeConfig<SocketT, TagT> = Types.RecognizeConfig<SocketT, TagT>
export type InstancePolicy = Types.InstancePolicy
export type SocketEndpoint = Types.SocketEndpoint
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketChangedCallback<SocketT> = Types.SocketChangedCallback<SocketT>

export type AnatomySocket<SocketT> = Types.AnatomySocket<SocketT>
export type AnatomyTaggedElement<TagT> = Types.AnatomyTaggedElement<TagT>
export type AnatomyTemplate<SocketT, TagT> = Types.AnatomyTemplate<SocketT, TagT>
export type AnatomyInstance<SocketT, TagT> = Types.AnatomyInstance<SocketT, TagT>
export type SocketBinding<SocketT> = Types.SocketBinding<SocketT>
export type SocketMount = Types.SocketMount
export type SocketMountOptions = Types.SocketMountOptions

export type AnatomyHost<SocketT, TagT> = Types.AnatomyHost<SocketT, TagT>
export type AnatomyHostOptions<SocketT> = Types.AnatomyHostOptions<SocketT>
export type AnatomyHostLayer<SocketT, TagT> = Types.AnatomyHostLayer<SocketT, TagT>
export type AnatomyHostLayerOptions = Types.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = Types.AnatomyHostSocketQuery
export type AnatomyHostTagQuery = Types.AnatomyHostTagQuery
export type AnatomyHostSocketAddress<SocketT> = Types.AnatomyHostSocketAddress<SocketT>
export type AnatomyInstanceSocketAddress<SocketT> = Types.AnatomyInstanceSocketAddress<SocketT>
export type AnatomyHostMountEndpoint<SocketT> = Types.AnatomyHostMountEndpoint<SocketT>
export type AnatomyHostMountConfig<SocketT> = Types.AnatomyHostMountConfig<SocketT>
export type TagChangedCallback<TagT> = Types.TagChangedCallback<TagT>

return Anatomy
