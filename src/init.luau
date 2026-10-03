--!strict
--!optimize 2

local AnatomyHostModule = require(script.anatomy.managers.anatomyHost.shared.anatomyHost)
local AnatomyTemplateModule =
	require(script.anatomy.components.anatomyTemplate.shared.anatomyTemplate)
local SocketEndpointModule = require(script.anatomy.components.socketEndpoint.shared.socketEndpoint)
local SocketMountModule = require(script.anatomy.components.socketMount.shared.socketMount)
local AnatomyTypes = require(script.anatomy.types.def.anatomy.shared.anatomy)
local AnatomyHostTypes = require(script.anatomy.types.managers.anatomyHost.shared.anatomyHost)
local AnatomyHostLayerTypes =
	require(script.anatomy.types.components.anatomyHostLayer.shared.anatomyHostLayer)
local SocketEndpointTypes =
	require(script.anatomy.types.ports.components.socketEndpoint.shared.socketEndpoint)
local AnatomyTemplateTypes =
	require(script.anatomy.types.components.anatomyTemplate.shared.anatomyTemplate)
local AnatomyInstanceTypes =
	require(script.anatomy.types.components.anatomyInstance.shared.anatomyInstance)
local AnatomySocketTypes =
	require(script.anatomy.types.components.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes =
	require(script.anatomy.types.components.anatomyTaggedElement.shared.anatomyTaggedElement)
local SocketBindingTypes =
	require(script.anatomy.types.components.socketBinding.shared.socketBinding)
local SocketMountTypes = require(script.anatomy.types.components.socketMount.shared.socketMount)
local SocketSubscriptionTypes =
	require(script.anatomy.types.ports.managers.anatomyHost.shared.socketSubscription)
local AnatomySocketLookupTypes =
	require(script.anatomy.types.ports.components.anatomyInstance.shared.anatomySocketLookup)

export type AnatomyCategory = AnatomyTypes.AnatomyCategory
export type AnatomyId = AnatomyTypes.AnatomyId
export type LayerId = AnatomyTypes.LayerId
export type AnatomyPathStep = AnatomyTypes.AnatomyPathStep
export type AnatomyPath = AnatomyTypes.AnatomyPath
export type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
export type InstancePolicy = AnatomyTypes.InstancePolicy
export type NameGuard<TName> = AnatomyTypes.NameGuard<TName>
export type SocketDescriptor<SocketT> = AnatomyTypes.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = AnatomyTypes.TagDescriptor<TagT>
export type RecognizeOptions<SocketT, TagT> = AnatomyTypes.RecognizeOptions<SocketT, TagT>
export type RecognizeConfig<SocketT, TagT> = AnatomyTypes.RecognizeConfig<SocketT, TagT>
export type AnatomyHost<SocketT, TagT> = AnatomyHostTypes.AnatomyHost<SocketT, TagT>
export type AnatomyHostOptions<SocketT, TagT> = AnatomyHostTypes.AnatomyHostOptions<SocketT, TagT>
export type AnatomyHostSocketAddress<SocketT> = AnatomyHostTypes.AnatomyHostSocketAddress<SocketT>
export type AnatomyInstanceSocketAddress<SocketT, TagT> =
	AnatomyHostTypes.AnatomyInstanceSocketAddress<SocketT, TagT>
export type AnatomyHostMountEndpoint<SocketT, TagT> = AnatomyHostTypes.AnatomyHostMountEndpoint<
	SocketT,
	TagT
>
export type AnatomyHostMountConfig<SocketT, TagT> = AnatomyHostTypes.AnatomyHostMountConfig<
	SocketT,
	TagT
>
export type TagChangedCallback<TagT> = AnatomyHostTypes.TagChangedCallback<TagT>
export type AnatomyHostSocketQuery = AnatomyHostTypes.AnatomyHostSocketQuery
export type AnatomyHostTagQuery = AnatomyHostTypes.AnatomyHostTagQuery
export type AnatomyHostLayer<SocketT, TagT> = AnatomyHostLayerTypes.AnatomyHostLayer<SocketT, TagT>
export type AnatomyHostLayerOptions = AnatomyHostLayerTypes.AnatomyHostLayerOptions
export type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>
export type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
export type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
export type SocketBinding<SocketT> = SocketBindingTypes.SocketBinding<SocketT>
export type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
export type MountAttachment = SocketEndpointTypes.MountAttachment
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type SocketAttachmentChangedCallback = SocketEndpointTypes.SocketAttachmentChangedCallback
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions
export type SocketChangedCallback<SocketT> = SocketSubscriptionTypes.SocketChangedCallback<SocketT>
export type SocketSubscription<SocketT> = SocketSubscriptionTypes.SocketSubscription<SocketT>
export type AnatomySocketLookup<SocketT> = AnatomySocketLookupTypes.AnatomySocketLookup<SocketT>
return {
	anatomyHost = { new = AnatomyHostModule.new },
	anatomyTemplate = {
		new = AnatomyTemplateModule.new,
		recognize = AnatomyTemplateModule.recognize,
	},
	socketEndpoint = { fromAttachment = SocketEndpointModule.fromAttachment },
	socketMount = { new = SocketMountModule.new },
}
