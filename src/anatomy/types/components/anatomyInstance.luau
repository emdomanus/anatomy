--!strict
--!optimize 2
--!native

local AnatomyPartTypes = require(script.Parent.anatomyPart)
local AnatomySocketTypes = require(script.Parent.anatomySocket)
local AnatomySurfaceTypes = require(script.Parent.anatomySurface)
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
export type SurfaceDescriptor<TSurfaceName> = DefTypes.SurfaceDescriptor<TSurfaceName>

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
	getSurface: (
		self: AnatomyInstance<TSocketName, TSurfaceName>,
		name: TSurfaceName
	) -> AnatomySurfaceTypes.AnatomySurface<TSurfaceName>?,
	getSurfaces: (
		self: AnatomyInstance<TSocketName, TSurfaceName>
	) -> { [TSurfaceName]: AnatomySurfaceTypes.AnatomySurface<TSurfaceName> },
	getPart: (self: AnatomyInstance<TSocketName, TSurfaceName>, name: PartName) -> AnatomyPart?,
	getParts: (self: AnatomyInstance<TSocketName, TSurfaceName>) -> { [PartName]: AnatomyPart },

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
	_surfaces: { [TSurfaceName]: AnatomySurfaceTypes.AnatomySurfaceImpl<TSurfaceName> },
	_parts: { [PartName]: AnatomyPartImpl },
	_destroyed: boolean,

	_resolvePath: (self: AnatomyInstanceImpl<TSocketName, TSurfaceName>, path: DefTypes.AnatomyPath) -> Instance?,
	_buildSocket: (
		self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
		descriptor: DefTypes.SocketDescriptor<TSocketName>
	) -> AnatomySocketTypes.AnatomySocketImpl<TSocketName>,
	_buildSurface: (
		self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
		descriptor: DefTypes.SurfaceDescriptor<TSurfaceName>
	) -> AnatomySurfaceTypes.AnatomySurfaceImpl<TSurfaceName>,
	_buildPart: (self: AnatomyInstanceImpl<TSocketName, TSurfaceName>, descriptor: DefTypes.PartDescriptor) -> AnatomyPartImpl,
}

return {}
