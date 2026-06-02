--!strict
--!optimize 2
--!native

local AnatomyInstanceTypes = require(script.Parent.anatomyInstance)
local DefTypes = require(script.Parent.Parent.def)

export type AnatomyCategory = DefTypes.AnatomyCategory
export type AnatomyId = DefTypes.AnatomyId
export type AnatomyInstance = AnatomyInstanceTypes.AnatomyInstance
export type AnatomyRole = DefTypes.AnatomyRole
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type PartDescriptor = DefTypes.PartDescriptor
export type PartName = DefTypes.PartName
export type RecognizeConfig = DefTypes.RecognizeConfig
export type SocketDescriptor = DefTypes.SocketDescriptor
export type SocketName = DefTypes.SocketName
export type SurfaceDescriptor = DefTypes.SurfaceDescriptor
export type SurfaceName = DefTypes.SurfaceName

export type AnatomyTemplate = {
	getId: (self: AnatomyTemplate) -> AnatomyId?,
	getRole: (self: AnatomyTemplate) -> AnatomyRole,
	getCategory: (self: AnatomyTemplate) -> AnatomyCategory?,
	getSource: (self: AnatomyTemplate) -> Instance,
	getMetadata: (self: AnatomyTemplate) -> DescriptorMetadata?,

	getSocketDescriptor: (self: AnatomyTemplate, name: SocketName) -> SocketDescriptor?,
	getSocketDescriptors: (self: AnatomyTemplate) -> { [SocketName]: SocketDescriptor },
	getSurfaceDescriptor: (self: AnatomyTemplate, name: SurfaceName) -> SurfaceDescriptor?,
	getSurfaceDescriptors: (self: AnatomyTemplate) -> { [SurfaceName]: SurfaceDescriptor },
	getPartDescriptor: (self: AnatomyTemplate, name: PartName) -> PartDescriptor?,
	getPartDescriptors: (self: AnatomyTemplate) -> { [PartName]: PartDescriptor },

	instantiate: (self: AnatomyTemplate, parent: Instance?) -> AnatomyInstance,
	wrap: (self: AnatomyTemplate, root: Instance) -> AnatomyInstance,
}

export type AnatomyTemplateImpl = AnatomyTemplate & {
	_id: AnatomyId?,
	_role: AnatomyRole,
	_category: AnatomyCategory?,
	_source: Instance,
	_config: RecognizeConfig,
	_metadata: DescriptorMetadata?,

	_socketDescriptors: { [SocketName]: SocketDescriptor },
	_surfaceDescriptors: { [SurfaceName]: SurfaceDescriptor },
	_partDescriptors: { [PartName]: PartDescriptor },
}

return {}
