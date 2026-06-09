--!strict
--!optimize 2
--!native


local Types = require(script.types)

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
export type RecognizeOptions<SocketT, TagT> = Types.RecognizeOptions<
	SocketT,
	TagT
>
export type RecognizeConfig<SocketT, TagT> = Types.RecognizeConfig<
	SocketT,
	TagT
>
export type InstancePolicy = Types.InstancePolicy
export type SocketEndpoint = Types.SocketEndpoint
export type SocketAttachmentChangedCallback = Types.SocketAttachmentChangedCallback
export type SocketChangedCallback<SocketT> = Types.SocketChangedCallback<SocketT>

export type AnatomySocket<SocketT> = Types.AnatomySocket<SocketT>
export type AnatomyTaggedElement<TagT> = Types.AnatomyTaggedElement<TagT>
export type AnatomyTemplate<SocketT, TagT> = Types.AnatomyTemplate<
	SocketT,
	TagT
>
export type AnatomyInstance<SocketT, TagT> = Types.AnatomyInstance<
	SocketT,
	TagT
>
export type SocketBinding<SocketT> = Types.SocketBinding<SocketT>
export type SocketMount = Types.SocketMount
export type SocketMountOptions = Types.SocketMountOptions

export type AnatomyHost<SocketT, TagT> = Types.AnatomyHost<SocketT, TagT>
export type AnatomyHostOptions<SocketT> = Types.AnatomyHostOptions<SocketT>
export type AnatomyHostLayer<SocketT, TagT> = Types.AnatomyHostLayer<
	SocketT,
	TagT
>
export type AnatomyHostLayerOptions = Types.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = Types.AnatomyHostSocketQuery
export type AnatomyHostTagQuery = Types.AnatomyHostTagQuery
export type AnatomyHostSocketAddress<SocketT> = Types.AnatomyHostSocketAddress<SocketT>
export type AnatomyInstanceSocketAddress<SocketT, TagT> = Types.AnatomyInstanceSocketAddress<SocketT, TagT>
export type AnatomyHostMountEndpoint<SocketT, TagT> = Types.AnatomyHostMountEndpoint<SocketT, TagT>
export type AnatomyHostMountConfig<SocketT, TagT> = Types.AnatomyHostMountConfig<SocketT, TagT>
export type TagChangedCallback<TagT> = Types.TagChangedCallback<TagT>

local AnatomyHostModule = require(script.managers.anatomyHost.shared.anatomyHost)
local AnatomyTemplateModule = require(script.components.anatomyTemplate.shared.anatomyTemplate)
local SocketEndpointModule = require(script.components.socketEndpoint.shared.socketEndpoint)
local SocketMountModule = require(script.components.socketMount.shared.socketMount)

return {
	anatomyHost = {
		new = AnatomyHostModule.new,
	},
	anatomyTemplate = {
		new = AnatomyTemplateModule.new,
		recognize = AnatomyTemplateModule.recognize,
	},
	socketEndpoint = {
		fromAttachment = SocketEndpointModule.fromAttachment,
	},
	socketMount = {
		new = SocketMountModule.new,
	},
}
