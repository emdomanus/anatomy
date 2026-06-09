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
export type SocketDescriptor<TSocketName> = DefTypes.SocketDescriptor<TSocketName>
export type TagDescriptor<TagT> = DefTypes.TagDescriptor<TagT>

export type AnatomyInstance<TSocketName, TSurfaceName> = {
	getId: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> AnatomyId?,
	getRole: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> AnatomyRole,
	getCategory: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> AnatomyCategory?,
	getRoot: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> Instance,
	getTemplate: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> any,
	getMetadata: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> DescriptorMetadata?,

	getSocket: (
		self: AnatomyInstance<TSocketName, TSurfaceName>,
		name: TSocketName
	) -> AnatomySocketTypes.AnatomySocket<TSocketName>?,
	getSockets: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> { [TSocketName]: AnatomySocketTypes.AnatomySocket<TSocketName> },
	getPart: (self: AnatomyInstance<TSocketName, TSurfaceName>, name: PartName) -> AnatomyPart?,
	getParts: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> { [PartName]: AnatomyPart },
	getByTag: (
		self: AnatomyInstance<TSocketName, TSurfaceName>,
		prefix: string
	) -> { AnatomyTaggedElementTypes.AnatomyTaggedElement<TSurfaceName> },

	setParent: (self: AnatomyInstance<TSocketName, TSurfaceName>, parent: Instance?) -> (),
	applyInstancePolicy: (self: AnatomyInstance<TSocketName, TSurfaceName>, policy: InstancePolicy) -> (),
	deconstruct: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> (),
}

export type AnatomyInstanceImpl<TSocketName, TSurfaceName> = AnatomyInstance<TSocketName, TSurfaceName> & {
	_template: any,
	_root: Instance,
	_id: AnatomyId?,
	_role: AnatomyRole,
	_category: AnatomyCategory?,
	_metadata: DescriptorMetadata?,
	_ownsRoot: boolean,

	_sockets: { [TSocketName]: AnatomySocketTypes.AnatomySocketImpl<TSocketName> },
	_parts: { [PartName]: AnatomyPartImpl },
	_taggedElements: { AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TSurfaceName> },
	_tagPrefixIndex: { [string]: { AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TSurfaceName> } },
	_destroyed: boolean,

	_resolvePath: (self: AnatomyInstanceImpl<TSocketName, TSurfaceName>, path: DefTypes.AnatomyPath) -> Instance?,
	_buildSocket: (
		self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
		descriptor: DefTypes.SocketDescriptor<TSocketName>
	) -> AnatomySocketTypes.AnatomySocketImpl<TSocketName>,
	_buildPart: (self: AnatomyInstanceImpl<TSocketName, TSurfaceName>, descriptor: DefTypes.PartDescriptor) -> AnatomyPartImpl,
	_buildTaggedElement: (
		self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
		descriptor: DefTypes.TagDescriptor<TSurfaceName>
	) -> AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TSurfaceName>,
}

return {}
