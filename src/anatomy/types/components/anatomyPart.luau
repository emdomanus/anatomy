--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.def)

export type AnatomyPath = DefTypes.AnatomyPath
export type DescriptorMetadata = DefTypes.DescriptorMetadata
export type PartName = DefTypes.PartName

export type AnatomyPart = {
	getName: (self: AnatomyPart) -> PartName,
	getInstance: (self: AnatomyPart) -> Instance?,
	getPath: (self: AnatomyPart) -> AnatomyPath,
	getMetadata: (self: AnatomyPart) -> DescriptorMetadata?,
	deconstruct: (self: AnatomyPart) -> (),
}

export type AnatomyPartImpl = AnatomyPart & {
	_owner: any,
	_name: PartName,
	_path: AnatomyPath,
	_instance: Instance?,
	_metadata: DescriptorMetadata?,
	_destroyed: boolean,
}

return {}
