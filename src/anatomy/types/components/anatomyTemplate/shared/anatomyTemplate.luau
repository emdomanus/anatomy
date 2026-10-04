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

type AnatomyInstanceOptions<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstanceOptions<
	SocketT,
	TagT
>

export type AnatomyPath = AnatomyTypes.AnatomyPath
export type InstancePolicy = AnatomyTypes.InstancePolicy

export type AnatomyCategory = AnatomyTypes.AnatomyCategory
export type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
export type RecognizeOptions<SocketT, TagT> = AnatomyTypes.RecognizeOptions<SocketT, TagT>
export type SocketDescriptor<SocketT> = AnatomyTypes.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = AnatomyTypes.TagDescriptor<TagT>

export type AnatomyTemplate<SocketT, TagT> = {
	read getCategory: (self: AnatomyTemplate<SocketT, TagT>) -> AnatomyCategory?,
	read getSource: (self: AnatomyTemplate<SocketT, TagT>) -> Instance,
	read getMetadata: (self: AnatomyTemplate<SocketT, TagT>) -> DescriptorMetadata?,

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
	_category: AnatomyCategory?,
	_source: Instance,
	_options: RecognizeOptions<SocketT, TagT>,
	_instanceOptions: AnatomyInstanceOptions<SocketT, TagT>,
	_metadata: DescriptorMetadata?,

	_socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> },
	_tagDescriptors: { TagDescriptor<TagT> },
}

return {}
