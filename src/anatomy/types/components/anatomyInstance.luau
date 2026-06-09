--!strict
--!optimize 2
--!native

local AnatomySocketTypes = require(script.Parent.anatomySocket)
local AnatomyTaggedElementTypes = require(script.Parent.anatomyTaggedElement)
local DefTypes = require(script.Parent.Parent.def)

export type AnatomyCategory = DefTypes.AnatomyCategory
export type AnatomyId = DefTypes.AnatomyId
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type InstancePolicy = DefTypes.InstancePolicy
export type SocketDescriptor<SocketT> = DefTypes.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = DefTypes.TagDescriptor<TagT>

export type AnatomyInstance<TemplateT, SocketT, TagT> = {
	getId: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> AnatomyId?,
	getCategory: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> AnatomyCategory?,
	getRoot: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> Instance,
	getTemplate: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> TemplateT,
	getMetadata: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> DescriptorMetadata?,

	getSocket: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		name: SocketT
	) -> AnatomySocketTypes.AnatomySocket<SocketT>?,
	getSockets: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>
	) -> { [SocketT]: AnatomySocketTypes.AnatomySocket<SocketT> },
	getByTag: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		prefix: string
	) -> { AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT> },

	setParent: (self: AnatomyInstance<TemplateT, SocketT, TagT>, parent: Instance?) -> (),
	applyInstancePolicy: (self: AnatomyInstance<TemplateT, SocketT, TagT>, policy: InstancePolicy) -> (),
	deconstruct: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> (),
}

export type AnatomyInstanceImpl<TemplateT, SocketT, TagT> = AnatomyInstance<TemplateT, SocketT, TagT> & {
	_template: TemplateT,
	_root: Instance,
	_id: AnatomyId?,
	_category: AnatomyCategory?,
	_metadata: DescriptorMetadata?,
	_ownsRoot: boolean,

	_sockets: { [SocketT]: AnatomySocketTypes.AnatomySocketImpl<AnatomyInstanceImpl<TemplateT, SocketT, TagT>, SocketT> },
	_taggedElements: { AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<AnatomyInstanceImpl<TemplateT, SocketT, TagT>, TagT> },
	_tagPrefixIndex: { [string]: { AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<AnatomyInstanceImpl<TemplateT, SocketT, TagT>, TagT> } },
	_destroyed: boolean,

	_resolvePath: (self: AnatomyInstanceImpl<TemplateT, SocketT, TagT>, path: DefTypes.AnatomyPath) -> Instance?,
	_buildSocket: (
		self: AnatomyInstanceImpl<TemplateT, SocketT, TagT>,
		descriptor: DefTypes.SocketDescriptor<SocketT>
	) -> AnatomySocketTypes.AnatomySocketImpl<AnatomyInstanceImpl<TemplateT, SocketT, TagT>, SocketT>,
	_buildTaggedElement: (
		self: AnatomyInstanceImpl<TemplateT, SocketT, TagT>,
		descriptor: DefTypes.TagDescriptor<TagT>
	) -> AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<AnatomyInstanceImpl<TemplateT, SocketT, TagT>, TagT>,
}

return {}
