--!strict
--!optimize 2
--!native

local AnatomyPart = require(script.Parent.Parent.Parent.anatomyPart.shared.anatomyPart)
local AnatomySocket = require(script.Parent.Parent.Parent.anatomySocket.shared.anatomySocket)
local AnatomySurface = require(script.Parent.Parent.Parent.anatomySurface.shared.anatomySurface)
local Path = require(script.Parent.Parent.Parent.Parent.utils.path)
local AnatomySocketTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket)
local AnatomySurfaceTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomySurface)
local AnatomyTemplateTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate)
local DefTypes = require(script.Parent.Parent.Parent.Parent.types.def)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.anatomyInstance)

export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyId = Types.AnatomyId
export type AnatomyInstance<TSocketName, TSurfaceName> = Types.AnatomyInstance<TSocketName, TSurfaceName>
export type AnatomyInstanceImpl<TSocketName, TSurfaceName> = Types.AnatomyInstanceImpl<TSocketName, TSurfaceName>
export type AnatomyPart = Types.AnatomyPart
export type AnatomyRole = Types.AnatomyRole
export type AnatomySocket<TSocketName> = AnatomySocketTypes.AnatomySocket<TSocketName>
export type AnatomySurface<TSurfaceName> = AnatomySurfaceTypes.AnatomySurface<TSurfaceName>
export type DescriptorMetadata = Types.DescriptorMetadata
export type InstancePolicy = Types.InstancePolicy
export type PartName = Types.PartName
export type PartDescriptor = Types.PartDescriptor
export type SocketDescriptor<TSocketName> = Types.SocketDescriptor<TSocketName>
export type SurfaceDescriptor<TSurfaceName> = Types.SurfaceDescriptor<TSurfaceName>
export type AnatomyPath = DefTypes.AnatomyPath
export type AnatomyTemplate<TSocketName, TSurfaceName> = AnatomyTemplateTypes.AnatomyTemplate<TSocketName, TSurfaceName>

local AnatomyInstance = {}
AnatomyInstance.__index = AnatomyInstance

local function getTemplateField(template: any, fieldName: string, methodName: string): any
	local method = template[methodName]
	if method ~= nil then
		return method(template)
	end

	return template[fieldName]
end

local function forRootAndDescendants(root: Instance, callback: (Instance) -> ()): ()
	callback(root)
	for _, descendant in root:GetDescendants() do
		callback(descendant)
	end
end

function AnatomyInstance.new<TSocketName, TSurfaceName>(
	template: AnatomyTemplate<TSocketName, TSurfaceName>,
	root: Instance,
	ownsRoot: boolean?
): AnatomyInstance<TSocketName, TSurfaceName>
	local self: AnatomyInstanceImpl<TSocketName, TSurfaceName> = setmetatable({}, AnatomyInstance) :: any

	self._template = template
	self._root = root
	self._id = getTemplateField(template, "_id", "getId")
	self._role = getTemplateField(template, "_role", "getRole")
	self._category = getTemplateField(template, "_category", "getCategory")
	self._metadata = getTemplateField(template, "_metadata", "getMetadata")
	self._ownsRoot = ownsRoot == true

	self._sockets = {}
	self._surfaces = {}
	self._parts = {}
	self._destroyed = false

	for name, descriptor in template:getSocketDescriptors() do
		self._sockets[name] = self:_buildSocket(descriptor)
	end

	for name, descriptor in template:getSurfaceDescriptors() do
		self._surfaces[name] = self:_buildSurface(descriptor)
	end

	for name, descriptor in template:getPartDescriptors() do
		self._parts[name] = self:_buildPart(descriptor)
	end

	local config = (template :: any)._config
	if config and config.instancePolicy then
		self:applyInstancePolicy(config.instancePolicy)
	end

	return self
end

function AnatomyInstance.getId<TSocketName, TSurfaceName>(self: AnatomyInstanceImpl<TSocketName, TSurfaceName>): AnatomyId?
	return self._id
end

function AnatomyInstance.getRole<TSocketName, TSurfaceName>(self: AnatomyInstanceImpl<TSocketName, TSurfaceName>): AnatomyRole
	return self._role
end

function AnatomyInstance.getCategory<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>
): AnatomyCategory?
	return self._category
end

function AnatomyInstance.getRoot<TSocketName, TSurfaceName>(self: AnatomyInstanceImpl<TSocketName, TSurfaceName>): Instance
	return self._root
end

function AnatomyInstance.getTemplate<TSocketName, TSurfaceName>(self: AnatomyInstanceImpl<TSocketName, TSurfaceName>): any
	return self._template
end

function AnatomyInstance.getMetadata<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>
): DescriptorMetadata?
	return self._metadata
end

function AnatomyInstance.getSocket<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
	name: TSocketName
): AnatomySocket<TSocketName>?
	return self._sockets[name]
end

function AnatomyInstance.getSockets<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>
): { [TSocketName]: AnatomySocket<TSocketName> }
	return table.clone(self._sockets) :: any
end

function AnatomyInstance.getSurface<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName
): AnatomySurface<TSurfaceName>?
	return self._surfaces[name]
end

function AnatomyInstance.getSurfaces<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>
): { [TSurfaceName]: AnatomySurface<TSurfaceName> }
	return table.clone(self._surfaces) :: any
end

function AnatomyInstance.getPart<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
	name: PartName
): AnatomyPart?
	return self._parts[name]
end

function AnatomyInstance.getParts<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>
): { [PartName]: AnatomyPart }
	return table.clone(self._parts) :: any
end

function AnatomyInstance.setParent<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
	parent: Instance?
): ()
	self._root.Parent = parent
end

function AnatomyInstance.applyInstancePolicy<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
	policy: InstancePolicy
): ()
	forRootAndDescendants(self._root, function(instance: Instance)
		if not instance:IsA("BasePart") then
			return
		end

		local part = instance :: BasePart
		if policy.canCollide ~= nil then
			part.CanCollide = policy.canCollide
		end
		if policy.canQuery ~= nil then
			part.CanQuery = policy.canQuery
		end
		if policy.canTouch ~= nil then
			part.CanTouch = policy.canTouch
		end
		if policy.audioCanCollide ~= nil then
			(part :: any).AudioCanCollide = policy.audioCanCollide
		end
		if policy.castShadow ~= nil then
			part.CastShadow = policy.castShadow
		end
		if policy.enableFluidForces ~= nil then
			part.EnableFluidForces = policy.enableFluidForces
		end
		if policy.massless ~= nil then
			part.Massless = policy.massless
		end
		if policy.anchored ~= nil then
			part.Anchored = policy.anchored
		end
	end)
end

function AnatomyInstance._resolvePath<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
	path: AnatomyPath
): Instance?
	return Path.resolve(self._root, path)
end

function AnatomyInstance._buildSocket<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
	descriptor: SocketDescriptor<TSocketName>
): AnatomySocketTypes.AnatomySocketImpl<TSocketName>
	local target = self:_resolvePath(descriptor.path)
	if target == nil then
		error(`Anatomy socket "{descriptor.name}" path did not resolve under {self._root:GetFullName()}`, 2)
	end
	if not target:IsA("Attachment") then
		error(
			`Anatomy socket "{descriptor.name}" resolved to {target.ClassName}; sockets must resolve to Attachment`,
			2
		)
	end

	return AnatomySocket.fromDescriptor(self, descriptor, target :: Attachment) :: any
end

function AnatomyInstance._buildSurface<TSocketName, TSurfaceName>(
	self: AnatomyInstanceImpl<TSocketName, TSurfaceName>,
	descriptor: SurfaceDescriptor<TSurfaceName>
): AnatomySurfaceTypes.AnatomySurfaceImpl<TSurfaceName>
	local instances = table.create(#descriptor.paths)
	for _, path in descriptor.paths do
		local instance = self:_resolvePath(path)
		if instance == nil then
			error(`Anatomy surface "{descriptor.name}" path did not resolve under {self._root:GetFullName()}`, 2)
		end
		table.insert(instances, instance)
	end

	return AnatomySurface.fromDescriptor(self, descriptor, instances) :: any
end

function AnatomyInstance._buildPart(
	self: AnatomyInstanceImpl<any, any>,
	descriptor: PartDescriptor
): Types.AnatomyPartImpl
	local instance = self:_resolvePath(descriptor.path)
	if instance == nil then
		error(`Anatomy part "{descriptor.name}" path did not resolve under {self._root:GetFullName()}`, 2)
	end

	return AnatomyPart.fromDescriptor(self, descriptor, instance) :: any
end

function AnatomyInstance.deconstruct<TSocketName, TSurfaceName>(self: AnatomyInstanceImpl<TSocketName, TSurfaceName>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	for name, socket in self._sockets do
		socket:deconstruct()
		self._sockets[name] = nil
	end
	for name, surface in self._surfaces do
		surface:deconstruct()
		self._surfaces[name] = nil
	end
	for name, part in self._parts do
		part:deconstruct()
		self._parts[name] = nil
	end

	if self._ownsRoot then
		self._root:Destroy()
	end

	self._template = nil
	self._root = nil :: any
end

return AnatomyInstance
