--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.types.components.anatomyPart)

export type AnatomyPart = Types.AnatomyPart
export type AnatomyPartImpl = Types.AnatomyPartImpl
export type AnatomyPath = Types.AnatomyPath
export type DescriptorMetadata = Types.DescriptorMetadata
export type PartName = Types.PartName

local AnatomyPart = {}
AnatomyPart.__index = AnatomyPart

function AnatomyPart.new(
	owner: any,
	name: PartName,
	path: AnatomyPath,
	instance: Instance?,
	metadata: DescriptorMetadata?
): AnatomyPart
	local self: AnatomyPartImpl = setmetatable({}, AnatomyPart) :: any

	self._owner = owner
	self._name = name
	self._path = path
	self._instance = instance
	self._metadata = metadata
	self._destroyed = false

	return self
end

function AnatomyPart.fromDescriptor(
	owner: any,
	descriptor: {
		name: PartName,
		path: AnatomyPath,
		metadata: DescriptorMetadata?,
	},
	instance: Instance?
): AnatomyPart
	return AnatomyPart.new(owner, descriptor.name, descriptor.path, instance, descriptor.metadata)
end

function AnatomyPart.getName(self: AnatomyPartImpl): PartName
	return self._name
end

function AnatomyPart.getInstance(self: AnatomyPartImpl): Instance?
	if self._destroyed then
		return nil
	end

	return self._instance
end

function AnatomyPart.getPath(self: AnatomyPartImpl): AnatomyPath
	return self._path
end

function AnatomyPart.getMetadata(self: AnatomyPartImpl): DescriptorMetadata?
	return self._metadata
end

function AnatomyPart.deconstruct(self: AnatomyPartImpl): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._instance = nil
	self._owner = nil
end

return AnatomyPart
