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
export type AnatomySocket = AnatomySocketTypes.AnatomySocket
export type AnatomySocketImpl = AnatomySocketTypes.AnatomySocketImpl
export type AnatomySurface = AnatomySurfaceTypes.AnatomySurface
export type AnatomySurfaceImpl = AnatomySurfaceTypes.AnatomySurfaceImpl
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type InstancePolicy = DefTypes.InstancePolicy
export type PartName = DefTypes.PartName
export type SocketName = DefTypes.SocketName
export type SurfaceName = DefTypes.SurfaceName

export type AnatomyInstance = {
	getId: (self: AnatomyInstance) -> AnatomyId?,
	getRole: (self: AnatomyInstance) -> AnatomyRole,
	getCategory: (self: AnatomyInstance) -> AnatomyCategory?,
	getRoot: (self: AnatomyInstance) -> Instance,
	getTemplate: (self: AnatomyInstance) -> any,
	getMetadata: (self: AnatomyInstance) -> DescriptorMetadata?,

	getSocket: (self: AnatomyInstance, name: SocketName) -> AnatomySocket?,
	getSockets: (self: AnatomyInstance) -> { [SocketName]: AnatomySocket },
	getSurface: (self: AnatomyInstance, name: SurfaceName) -> AnatomySurface?,
	getSurfaces: (self: AnatomyInstance) -> { [SurfaceName]: AnatomySurface },
	getPart: (self: AnatomyInstance, name: PartName) -> AnatomyPart?,
	getParts: (self: AnatomyInstance) -> { [PartName]: AnatomyPart },

	setParent: (self: AnatomyInstance, parent: Instance?) -> (),
	applyInstancePolicy: (self: AnatomyInstance, policy: InstancePolicy) -> (),
	deconstruct: (self: AnatomyInstance) -> (),
}

export type AnatomyInstanceImpl = AnatomyInstance & {
	_template: any,
	_root: Instance,
	_id: AnatomyId?,
	_role: AnatomyRole,
	_category: AnatomyCategory?,
	_metadata: DescriptorMetadata?,
	_ownsRoot: boolean,

	_sockets: { [SocketName]: AnatomySocketImpl },
	_surfaces: { [SurfaceName]: AnatomySurfaceImpl },
	_parts: { [PartName]: AnatomyPartImpl },
	_destroyed: boolean,

	_resolvePath: (self: AnatomyInstanceImpl, path: DefTypes.AnatomyPath) -> Instance?,
	_buildSocket: (self: AnatomyInstanceImpl, descriptor: DefTypes.SocketDescriptor) -> AnatomySocketImpl?,
	_buildSurface: (self: AnatomyInstanceImpl, descriptor: DefTypes.SurfaceDescriptor) -> AnatomySurfaceImpl?,
	_buildPart: (self: AnatomyInstanceImpl, descriptor: DefTypes.PartDescriptor) -> AnatomyPartImpl?,
}

return {}
