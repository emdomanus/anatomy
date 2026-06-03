--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.Parent.Parent.types.def)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.anatomySurface)

export type AnatomyPath = Types.AnatomyPath
export type AnatomySurface<TSurfaceName> = Types.AnatomySurface<TSurfaceName>
export type AnatomySurfaceImpl<TSurfaceName> = Types.AnatomySurfaceImpl<TSurfaceName>
export type DescriptorMetadata = Types.DescriptorMetadata
export type SurfaceDescriptor<TSurfaceName> = DefTypes.SurfaceDescriptor<TSurfaceName>

local AnatomySurface = {}
AnatomySurface.__index = AnatomySurface

function AnatomySurface.new<TSurfaceName>(
	owner: any,
	name: TSurfaceName,
	paths: { AnatomyPath },
	instances: { Instance },
	metadata: DescriptorMetadata?
): AnatomySurface<TSurfaceName>
	local self: AnatomySurfaceImpl<TSurfaceName> = setmetatable({}, AnatomySurface) :: any

	self._owner = owner
	self._name = name
	self._paths = paths
	self._instances = instances
	self._metadata = metadata
	self._destroyed = false

	return self
end

function AnatomySurface.fromDescriptor<TSurfaceName>(
	owner: any,
	descriptor: SurfaceDescriptor<TSurfaceName>,
	instances: { Instance }
): AnatomySurface<TSurfaceName>
	return AnatomySurface.new(owner, descriptor.name, descriptor.paths, instances, descriptor.metadata)
end

function AnatomySurface.getName<TSurfaceName>(self: AnatomySurfaceImpl<TSurfaceName>): TSurfaceName
	return self._name
end

function AnatomySurface.getInstances<TSurfaceName>(self: AnatomySurfaceImpl<TSurfaceName>): { Instance }
	if self._destroyed then
		return {}
	end

	return table.clone(self._instances)
end

function AnatomySurface.getPrimaryInstance<TSurfaceName>(self: AnatomySurfaceImpl<TSurfaceName>): Instance?
	if self._destroyed then
		return nil
	end

	return self._instances[1]
end

function AnatomySurface.getPaths<TSurfaceName>(self: AnatomySurfaceImpl<TSurfaceName>): { AnatomyPath }
	return table.clone(self._paths)
end

function AnatomySurface.getMetadata<TSurfaceName>(self: AnatomySurfaceImpl<TSurfaceName>): DescriptorMetadata?
	return self._metadata
end

function AnatomySurface.deconstruct<TSurfaceName>(self: AnatomySurfaceImpl<TSurfaceName>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	table.clear(self._instances)
	table.clear(self._paths)
	self._owner = nil
end

return AnatomySurface
