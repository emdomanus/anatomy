--!strict
--!optimize 2
--!native

local AnatomyPartTypes = require(script.Parent.anatomyPart)
local AnatomySocketTypes = require(script.Parent.anatomySocket)
local AnatomyTaggedElementTypes = require(script.Parent.anatomyTaggedElement)
local DefTypes = require(script.Parent.Parent.def)

export type AnatomyCategory = DefTypes.AnatomyCategory
export type AnatomyId = DefTypes.AnatomyId
export type AnatomyPart = AnatomyPartTypes.AnatomyPart
export type AnatomyPartImpl = AnatomyPartTypes.AnatomyPartImpl
export type AnatomyRole = DefTypes.AnatomyRole
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type InstancePolicy = DefTypes.InstancePolicy
export type PartName = DefTypes.PartName
export type PartDescriptor = DefTypes.PartDescriptor
export type SocketDescriptor<SocketT> = DefTypes.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = DefTypes.TagDescriptor<TagT>

export type AnatomyInstance<SocketT, TagT> = {
	getId: (self: AnatomyInstance<SocketT, TagT>) -> AnatomyId?,
	getRole: (self: AnatomyInstance<SocketT, TagT>) -> AnatomyRole,
	getCategory: (self: AnatomyInstance<SocketT, TagT>) -> AnatomyCategory?,
	getRoot: (self: AnatomyInstance<SocketT, TagT>) -> Instance,
	getTemplate: (self: AnatomyInstance<SocketT, TagT>) -> any,
	getMetadata: (self: AnatomyInstance<SocketT, TagT>) -> DescriptorMetadata?,

	getSocket: (
		self: AnatomyInstance<SocketT, TagT>,
		name: SocketT
	) -> AnatomySocketTypes.AnatomySocket<SocketT>?,
	getSockets: (self: AnatomyInstance<SocketT, TagT>) -> { [SocketT]: AnatomySocketTypes.AnatomySocket<SocketT> },
	getPart: (self: AnatomyInstance<SocketT, TagT>, name: PartName) -> AnatomyPart?,
	getParts: (self: AnatomyInstance<SocketT, TagT>) -> { [PartName]: AnatomyPart },
	getByTag: (
		self: AnatomyInstance<SocketT, TagT>,
		prefix: string
	) -> { AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT> },

	setParent: (self: AnatomyInstance<SocketT, TagT>, parent: Instance?) -> (),
	applyInstancePolicy: (self: AnatomyInstance<SocketT, TagT>, policy: InstancePolicy) -> (),
	deconstruct: (self: AnatomyInstance<SocketT, TagT>) -> (),
}

export type AnatomyInstanceImpl<SocketT, TagT> = AnatomyInstance<SocketT, TagT> & {
	_template: any,
	_root: Instance,
	_id: AnatomyId?,
	_role: AnatomyRole,
	_category: AnatomyCategory?,
	_metadata: DescriptorMetadata?,
	_ownsRoot: boolean,

	_sockets: { [SocketT]: AnatomySocketTypes.AnatomySocketImpl<SocketT> },
	_parts: { [PartName]: AnatomyPartImpl },
	_taggedElements: { AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TagT> },
	_tagPrefixIndex: { [string]: { AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TagT> } },
	_destroyed: boolean,

	_resolvePath: (self: AnatomyInstanceImpl<SocketT, TagT>, path: DefTypes.AnatomyPath) -> Instance?,
	_buildSocket: (
		self: AnatomyInstanceImpl<SocketT, TagT>,
		descriptor: DefTypes.SocketDescriptor<SocketT>
	) -> AnatomySocketTypes.AnatomySocketImpl<SocketT>,
	_buildPart: (self: AnatomyInstanceImpl<SocketT, TagT>, descriptor: DefTypes.PartDescriptor) -> AnatomyPartImpl,
	_buildTaggedElement: (
		self: AnatomyInstanceImpl<SocketT, TagT>,
		descriptor: DefTypes.TagDescriptor<TagT>
	) -> AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TagT>,
}

return {}
