--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.types.components.anatomySurface)

export type AnatomyPath = Types.AnatomyPath
export type AnatomySurface = Types.AnatomySurface
export type AnatomySurfaceImpl = Types.AnatomySurfaceImpl
export type DescriptorMetadata = Types.DescriptorMetadata
export type SurfaceName = Types.SurfaceName

local AnatomySurface = {}
AnatomySurface.__index = AnatomySurface

function AnatomySurface.new(
	owner: any,
	name: SurfaceName,
	paths: { AnatomyPath },
	instances: { Instance },
	metadata: DescriptorMetadata?
): AnatomySurface
	local self: AnatomySurfaceImpl = setmetatable({}, AnatomySurface) :: any

	self._owner = owner
	self._name = name
	self._paths = paths
	self._instances = instances
	self._metadata = metadata
	self._destroyed = false

	return self
end

function AnatomySurface.fromDescriptor(
	owner: any,
	descriptor: {
		name: SurfaceName,
		paths: { AnatomyPath },
		metadata: DescriptorMetadata?,
	},
	instances: { Instance }
): AnatomySurface
	return AnatomySurface.new(owner, descriptor.name, descriptor.paths, instances, descriptor.metadata)
end

function AnatomySurface.getName(self: AnatomySurfaceImpl): SurfaceName
	return self._name
end

function AnatomySurface.getInstances(self: AnatomySurfaceImpl): { Instance }
	if self._destroyed then
		return {}
	end

	return table.clone(self._instances)
end

function AnatomySurface.getPrimaryInstance(self: AnatomySurfaceImpl): Instance?
	if self._destroyed then
		return nil
	end

	return self._instances[1]
end

function AnatomySurface.getPaths(self: AnatomySurfaceImpl): { AnatomyPath }
	return table.clone(self._paths)
end

function AnatomySurface.getMetadata(self: AnatomySurfaceImpl): DescriptorMetadata?
	return self._metadata
end

function AnatomySurface.deconstruct(self: AnatomySurfaceImpl): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	table.clear(self._instances)
	table.clear(self._paths)
	self._owner = nil
end

return AnatomySurface
