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
export type RecognizeConfig<TSocketName, TSurfaceName> = DefTypes.RecognizeConfig<TSocketName, TSurfaceName>
export type SocketDescriptor<TSocketName> = DefTypes.SocketDescriptor<TSocketName>
export type TagDescriptor<TagT> = DefTypes.TagDescriptor<TagT>

export type AnatomyTemplate<TSocketName, TSurfaceName> = {
	getId: (self: AnatomyTemplate<TSocketName, TSurfaceName>) -> AnatomyId?,
	getRole: (self: AnatomyTemplate<TSocketName, TSurfaceName>) -> AnatomyRole,
	getCategory: (self: AnatomyTemplate<TSocketName, TSurfaceName>) -> AnatomyCategory?,
	getSource: (self: AnatomyTemplate<TSocketName, TSurfaceName>) -> Instance,
	getMetadata: (self: AnatomyTemplate<TSocketName, TSurfaceName>) -> DescriptorMetadata?,

	getSocketDescriptor: (
		self: AnatomyTemplate<TSocketName, TSurfaceName>,
		name: TSocketName
	) -> SocketDescriptor<TSocketName>?,
	getSocketDescriptors: (self: AnatomyTemplate<TSocketName, TSurfaceName>) -> { [TSocketName]: SocketDescriptor<TSocketName> },
	getTagDescriptors: (self: AnatomyTemplate<TSocketName, TSurfaceName>) -> { TagDescriptor<TSurfaceName> },
	getPartDescriptor: (self: AnatomyTemplate<TSocketName, TSurfaceName>, name: PartName) -> PartDescriptor?,
	getPartDescriptors: (self: AnatomyTemplate<TSocketName, TSurfaceName>) -> { [PartName]: PartDescriptor },

	instantiate: (
		self: AnatomyTemplate<TSocketName, TSurfaceName>,
		parent: Instance?
	) -> AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>,
	wrap: (
		self: AnatomyTemplate<TSocketName, TSurfaceName>,
		root: Instance
	) -> AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>,
}

export type AnatomyTemplateImpl<TSocketName, TSurfaceName> = AnatomyTemplate<TSocketName, TSurfaceName> & {
	_id: AnatomyId?,
	_role: AnatomyRole,
	_category: AnatomyCategory?,
	_source: Instance,
	_config: RecognizeConfig<TSocketName, TSurfaceName>,
	_metadata: DescriptorMetadata?,

	_socketDescriptors: { [TSocketName]: SocketDescriptor<TSocketName> },
	_tagDescriptors: { TagDescriptor<TSurfaceName> },
	_partDescriptors: { [PartName]: PartDescriptor },
}

return {}
