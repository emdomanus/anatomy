--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.def)

export type AnatomyPath = DefTypes.AnatomyPath
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type SurfaceName = DefTypes.SurfaceName

export type AnatomySurface = {
	getName: (self: AnatomySurface) -> SurfaceName,
	getInstances: (self: AnatomySurface) -> { Instance },
	getPrimaryInstance: (self: AnatomySurface) -> Instance?,
	getPaths: (self: AnatomySurface) -> { AnatomyPath },
	getMetadata: (self: AnatomySurface) -> DescriptorMetadata?,
	deconstruct: (self: AnatomySurface) -> (),
}

export type AnatomySurfaceImpl = AnatomySurface & {
	_owner: any,
	_name: SurfaceName,
	_paths: { AnatomyPath },
	_instances: { Instance },
	_metadata: DescriptorMetadata?,
	_destroyed: boolean,
}

return {}
