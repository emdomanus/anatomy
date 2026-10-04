--!strict
--!optimize 2

local AnatomyHostModule = require(script.anatomy.managers.anatomyHost.shared.anatomyHost)
local AnatomyTemplateModule =
	require(script.anatomy.components.anatomyTemplate.shared.anatomyTemplate)
local SocketMountModule = require(script.anatomy.components.socketMount.shared.socketMount)
local AnatomyTypes = require(script.anatomy.types.def.anatomy.shared.anatomy)
local AnatomySourceTypes = require(script.anatomy.types.ports.anatomySource.shared.anatomySource)
local AnatomyHostTypes = require(script.anatomy.types.managers.anatomyHost.shared.anatomyHost)
local AnatomyTemplateTypes =
	require(script.anatomy.types.components.anatomyTemplate.shared.anatomyTemplate)
local AnatomyInstanceTypes =
	require(script.anatomy.types.components.anatomyInstance.shared.anatomyInstance)
local AnatomySocketTypes =
	require(script.anatomy.types.components.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes =
	require(script.anatomy.types.components.anatomyTaggedElement.shared.anatomyTaggedElement)
local SocketWatcherTypes =
	require(script.anatomy.types.components.socketWatcher.shared.socketWatcher)
local SocketMountTypes = require(script.anatomy.types.components.socketMount.shared.socketMount)
local SocketSubscriptionTypes =
	require(script.anatomy.types.ports.managers.anatomyHost.shared.socketSubscription)

export type AnatomyCategory = AnatomyTypes.AnatomyCategory
export type AnatomyPath = AnatomyTypes.AnatomyPath
export type AnatomyPathStep = AnatomyTypes.AnatomyPathStep
export type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
export type InstancePolicy = AnatomyTypes.InstancePolicy
export type NameGuard<TName> = AnatomyTypes.NameGuard<TName>
export type RecognizeOptions<SocketT, TagT> = AnatomyTypes.RecognizeOptions<SocketT, TagT>
export type RecognizeConfig<SocketT, TagT> = AnatomyTypes.RecognizeConfig<SocketT, TagT>
export type AnatomySource<SocketT, TagT> = AnatomySourceTypes.AnatomySource<SocketT, TagT>
export type AnatomyHost<SocketT, TagT> = AnatomyHostTypes.AnatomyHost<SocketT, TagT>
export type AnatomyHostOptions<SocketT, TagT> = AnatomyHostTypes.AnatomyHostOptions<SocketT, TagT>
export type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>
export type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
export type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
export type SocketWatcher<SocketT> = SocketWatcherTypes.SocketWatcher<SocketT>
export type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions
export type SocketChangedCallback<SocketT> = SocketSubscriptionTypes.SocketChangedCallback<SocketT>
return {
	anatomyHost = { new = AnatomyHostModule.new },
	anatomyTemplate = {
		new = AnatomyTemplateModule.new,
	},
	socketMount = { new = SocketMountModule.new },
}
