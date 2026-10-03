--!strict
--!optimize 2

local AnatomyInstanceTypes =
	require(script.Parent.Parent.Parent.anatomyInstance.shared.anatomyInstance)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)

type AnatomyInstance<TemplateT, SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	TemplateT,
	SocketT,
	TagT
>

export type AnatomyPath = AnatomyTypes.AnatomyPath
export type InstancePolicy = AnatomyTypes.InstancePolicy

export type AnatomyCategory = AnatomyTypes.AnatomyCategory
export type AnatomyId = AnatomyTypes.AnatomyId
export type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
export type RecognizeConfig<SocketT, TagT> = AnatomyTypes.RecognizeConfig<SocketT, TagT>
export type SocketDescriptor<SocketT> = AnatomyTypes.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = AnatomyTypes.TagDescriptor<TagT>

export type AnatomyTemplate<SocketT, TagT> = {
	read getId: (self: AnatomyTemplate<SocketT, TagT>) -> AnatomyId?,
	read getCategory: (self: AnatomyTemplate<SocketT, TagT>) -> AnatomyCategory?,
	read getSource: (self: AnatomyTemplate<SocketT, TagT>) -> Instance,
	read getMetadata: (self: AnatomyTemplate<SocketT, TagT>) -> DescriptorMetadata?,

	read getSocketDescriptor: (
		self: AnatomyTemplate<SocketT, TagT>,
		name: SocketT
	) -> SocketDescriptor<SocketT>?,
	read getSocketDescriptors: (
		self: AnatomyTemplate<SocketT, TagT>
	) -> { [SocketT]: SocketDescriptor<SocketT> },
	read getTagDescriptors: (self: AnatomyTemplate<SocketT, TagT>) -> { TagDescriptor<TagT> },

	read instantiate: (
		self: AnatomyTemplate<SocketT, TagT>,
		parent: Instance?
	) -> AnatomyInstance<AnatomyTemplate<SocketT, TagT>, SocketT, TagT>,
	read wrap: (
		self: AnatomyTemplate<SocketT, TagT>,
		root: Instance
	) -> AnatomyInstance<AnatomyTemplate<SocketT, TagT>, SocketT, TagT>,
}

export type AnatomyTemplateImpl<SocketT, TagT> = AnatomyTemplate<SocketT, TagT> & {
	_id: AnatomyId?,
	_category: AnatomyCategory?,
	_source: Instance,
	_config: RecognizeConfig<SocketT, TagT>,
	_instanceOptions: AnatomyInstanceTypes.AnatomyInstanceOptions<SocketT, TagT>,
	_metadata: DescriptorMetadata?,

	_socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> },
	_tagDescriptors: { TagDescriptor<TagT> },
}

return {}
