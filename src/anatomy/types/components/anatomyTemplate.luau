--!strict
--!optimize 2
--!native

local AnatomyInstanceTypes = require(script.Parent.anatomyInstance)
local DefTypes = require(script.Parent.Parent.def)

export type AnatomyCategory = DefTypes.AnatomyCategory
export type AnatomyId = DefTypes.AnatomyId
export type AnatomyRole = DefTypes.AnatomyRole
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type PartDescriptor = DefTypes.PartDescriptor
export type PartName = DefTypes.PartName
export type RecognizeConfig<SocketT, TagT> = DefTypes.RecognizeConfig<SocketT, TagT>
export type SocketDescriptor<SocketT> = DefTypes.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = DefTypes.TagDescriptor<TagT>

export type AnatomyTemplate<SocketT, TagT> = {
	getId: (self: AnatomyTemplate<SocketT, TagT>) -> AnatomyId?,
	getRole: (self: AnatomyTemplate<SocketT, TagT>) -> AnatomyRole,
	getCategory: (self: AnatomyTemplate<SocketT, TagT>) -> AnatomyCategory?,
	getSource: (self: AnatomyTemplate<SocketT, TagT>) -> Instance,
	getMetadata: (self: AnatomyTemplate<SocketT, TagT>) -> DescriptorMetadata?,

	getSocketDescriptor: (
		self: AnatomyTemplate<SocketT, TagT>,
		name: SocketT
	) -> SocketDescriptor<SocketT>?,
	getSocketDescriptors: (self: AnatomyTemplate<SocketT, TagT>) -> { [SocketT]: SocketDescriptor<SocketT> },
	getTagDescriptors: (self: AnatomyTemplate<SocketT, TagT>) -> { TagDescriptor<TagT> },
	getPartDescriptor: (self: AnatomyTemplate<SocketT, TagT>, name: PartName) -> PartDescriptor?,
	getPartDescriptors: (self: AnatomyTemplate<SocketT, TagT>) -> { [PartName]: PartDescriptor },

	instantiate: (
		self: AnatomyTemplate<SocketT, TagT>,
		parent: Instance?
	) -> AnatomyInstanceTypes.AnatomyInstance<SocketT, TagT>,
	wrap: (
		self: AnatomyTemplate<SocketT, TagT>,
		root: Instance
	) -> AnatomyInstanceTypes.AnatomyInstance<SocketT, TagT>,
}

export type AnatomyTemplateImpl<SocketT, TagT> = AnatomyTemplate<SocketT, TagT> & {
	_id: AnatomyId?,
	_role: AnatomyRole,
	_category: AnatomyCategory?,
	_source: Instance,
	_config: RecognizeConfig<SocketT, TagT>,
	_metadata: DescriptorMetadata?,

	_socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> },
	_tagDescriptors: { TagDescriptor<TagT> },
	_partDescriptors: { [PartName]: PartDescriptor },
}

return {}
