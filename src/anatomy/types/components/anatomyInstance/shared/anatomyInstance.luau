--!strict
--!optimize 2

local AnatomySocketTypes = require(script.Parent.Parent.Parent.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes =
	require(script.Parent.Parent.Parent.anatomyTaggedElement.shared.anatomyTaggedElement)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)

type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
type AnatomySocketOwned<SocketT> = AnatomySocketTypes.AnatomySocketOwned<SocketT>
type AnatomyTaggedElementOwned<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElementOwned<TagT>
type AnatomyPath = AnatomyTypes.AnatomyPath

export type AnatomyCategory = AnatomyTypes.AnatomyCategory
export type AnatomyId = AnatomyTypes.AnatomyId
export type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
export type InstancePolicy = AnatomyTypes.InstancePolicy
export type SocketDescriptor<SocketT> = AnatomyTypes.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = AnatomyTypes.TagDescriptor<TagT>

export type AnatomyInstance<TemplateT, SocketT, TagT> = {
	read getSocket: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		name: SocketT
	) -> AnatomySocket<SocketT>?,
	read getId: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> AnatomyId?,
	read getCategory: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> AnatomyCategory?,
	read getRoot: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> Instance,
	read getTemplate: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> TemplateT,
	read getMetadata: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> DescriptorMetadata?,

	read forEachSocket: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		callback: (SocketT, AnatomySocket<SocketT>) -> ()
	) -> (),
	read forEachTaggedElement: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		callback: (AnatomyTaggedElement<TagT>) -> ()
	) -> (),
	read forEachByTag: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		prefix: string,
		callback: (AnatomyTaggedElement<TagT>) -> ()
	) -> (),
	read getFirstByTag: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		prefix: string
	) -> AnatomyTaggedElement<TagT>?,
	read getLastByTag: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		prefix: string
	) -> AnatomyTaggedElement<TagT>?,
	read getSockets: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>
	) -> { [SocketT]: AnatomySocket<SocketT> },
	read getByTag: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		prefix: string
	) -> { AnatomyTaggedElement<TagT> },

	read getTaggedElements: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>
	) -> { AnatomyTaggedElement<TagT> },

	read setParent: (self: AnatomyInstance<TemplateT, SocketT, TagT>, parent: Instance?) -> (),
	read applyInstancePolicy: (
		self: AnatomyInstance<TemplateT, SocketT, TagT>,
		policy: InstancePolicy
	) -> (),
	read deconstruct: (self: AnatomyInstance<TemplateT, SocketT, TagT>) -> (),
}

export type AnatomyInstanceImpl<TemplateT, SocketT, TagT> = AnatomyInstance<
	TemplateT,
	SocketT,
	TagT
> & {
	_template: TemplateT,
	_root: Instance,
	_id: AnatomyId?,
	_category: AnatomyCategory?,
	_metadata: DescriptorMetadata?,
	_ownsRoot: boolean,

	_sockets: { [SocketT]: AnatomySocketOwned<SocketT> },
	_taggedElements: { AnatomyTaggedElementOwned<TagT> },
	_tagPrefixIndex: { [string]: { AnatomyTaggedElementOwned<TagT> } },
	_tagPathDelimiter: string,
	_destroyed: boolean,

	_resolvePath: (
		self: AnatomyInstanceImpl<TemplateT, SocketT, TagT>,
		path: AnatomyPath
	) -> Instance?,
	_buildSocket: (
		self: AnatomyInstanceImpl<TemplateT, SocketT, TagT>,
		descriptor: SocketDescriptor<SocketT>
	) -> AnatomySocketOwned<SocketT>,
	_buildTaggedElement: (
		self: AnatomyInstanceImpl<TemplateT, SocketT, TagT>,
		descriptor: TagDescriptor<TagT>
	) -> AnatomyTaggedElementOwned<TagT>,
}

export type AnatomyInstanceOptions<SocketT, TagT> = {
	read socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> },
	read tagDescriptors: { TagDescriptor<TagT> },
	read instancePolicy: InstancePolicy?,
	read tagPathDelimiter: string,
}
return {}
