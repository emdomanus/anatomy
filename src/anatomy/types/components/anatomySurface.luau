--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.def)

export type AnatomyPath = DefTypes.AnatomyPath
export type DescriptorMetadata = DefTypes.DescriptorMetadata

export type AnatomySurface<TSurfaceName> = {
	getName: (self: AnatomySurface<TSurfaceName>) -> TSurfaceName,
	getInstances: (self: AnatomySurface<TSurfaceName>) -> { Instance },
	getPrimaryInstance: (self: AnatomySurface<TSurfaceName>) -> Instance?,
	getPaths: (self: AnatomySurface<TSurfaceName>) -> { AnatomyPath },
	getMetadata: (self: AnatomySurface<TSurfaceName>) -> DescriptorMetadata?,
	deconstruct: (self: AnatomySurface<TSurfaceName>) -> (),
}

export type AnatomySurfaceImpl<TSurfaceName> = AnatomySurface<TSurfaceName> & {
	_owner: any,
	_name: TSurfaceName,
	_paths: { AnatomyPath },
	_instances: { Instance },
	_metadata: DescriptorMetadata?,
	_destroyed: boolean,
}

return {}
