--!strict
--!optimize 2
--!native

local AnatomyPart = require(script.Parent.Parent.Parent.anatomyPart.shared.anatomyPart)
local AnatomySocket = require(script.Parent.Parent.Parent.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElement = require(script.Parent.Parent.Parent.anatomyTaggedElement.shared.anatomyTaggedElement)
local Path = require(script.Parent.Parent.Parent.Parent.utils.path)
local AnatomySocketTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket)
local AnatomyTaggedElementTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyTaggedElement)
local AnatomyTemplateTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate)
local DefTypes = require(script.Parent.Parent.Parent.Parent.types.def)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.anatomyInstance)

export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyId = Types.AnatomyId
export type AnatomyInstance<SocketT, TagT> = Types.AnatomyInstance<SocketT, TagT>
export type AnatomyInstanceImpl<SocketT, TagT> = Types.AnatomyInstanceImpl<SocketT, TagT>
export type AnatomyPart = Types.AnatomyPart
export type AnatomyRole = Types.AnatomyRole
export type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
export type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
export type DescriptorMetadata = Types.DescriptorMetadata
export type InstancePolicy = Types.InstancePolicy
export type PartName = Types.PartName
export type PartDescriptor = Types.PartDescriptor
export type SocketDescriptor<SocketT> = Types.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = Types.TagDescriptor<TagT>
export type AnatomyPath = DefTypes.AnatomyPath
export type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>

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

local function addTaggedElementToIndex<TagT>(
	tagPrefixIndex: { [string]: { AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TagT> } },
	element: AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TagT>,
	prefixes: { [string]: true }
): ()
	for prefix in prefixes do
		local elements = tagPrefixIndex[prefix]
		if elements == nil then
			elements = {}
			tagPrefixIndex[prefix] = elements
		end

		table.insert(elements, element)
	end
end

function AnatomyInstance.new<SocketT, TagT>(
	template: AnatomyTemplate<SocketT, TagT>,
	root: Instance,
	ownsRoot: boolean?
): AnatomyInstance<SocketT, TagT>
	local self: AnatomyInstanceImpl<SocketT, TagT> = setmetatable({}, AnatomyInstance) :: any

	self._template = template
	self._root = root
	self._id = getTemplateField(template, "_id", "getId")
	self._role = getTemplateField(template, "_role", "getRole")
	self._category = getTemplateField(template, "_category", "getCategory")
	self._metadata = getTemplateField(template, "_metadata", "getMetadata")
	self._ownsRoot = ownsRoot == true

	self._sockets = {}
	self._parts = {}
	self._taggedElements = {}
	self._tagPrefixIndex = {}
	self._destroyed = false

	for name, descriptor in template:getSocketDescriptors() do
		self._sockets[name] = self:_buildSocket(descriptor)
	end

	for name, descriptor in template:getPartDescriptors() do
		self._parts[name] = self:_buildPart(descriptor)
	end

	for _, descriptor in template:getTagDescriptors() do
		local element = self:_buildTaggedElement(descriptor)
		table.insert(self._taggedElements, element)
		addTaggedElementToIndex(self._tagPrefixIndex, element, descriptor.prefixes)
	end

	local config = (template :: any)._config
	if config and config.instancePolicy then
		self:applyInstancePolicy(config.instancePolicy)
	end

	return self
end

function AnatomyInstance.getId<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): AnatomyId?
	return self._id
end

function AnatomyInstance.getRole<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): AnatomyRole
	return self._role
end

function AnatomyInstance.getCategory<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>
): AnatomyCategory?
	return self._category
end

function AnatomyInstance.getRoot<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): Instance
	return self._root
end

function AnatomyInstance.getTemplate<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): any
	return self._template
end

function AnatomyInstance.getMetadata<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>
): DescriptorMetadata?
	return self._metadata
end

function AnatomyInstance.getSocket<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	name: SocketT
): AnatomySocket<SocketT>?
	return self._sockets[name]
end

function AnatomyInstance.getSockets<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>
): { [SocketT]: AnatomySocket<SocketT> }
	return table.clone(self._sockets) :: any
end

function AnatomyInstance.getPart<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	name: PartName
): AnatomyPart?
	return self._parts[name]
end

function AnatomyInstance.getParts<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>
): { [PartName]: AnatomyPart }
	return table.clone(self._parts) :: any
end

function AnatomyInstance.getByTag<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	prefix: string
): { AnatomyTaggedElement<TagT> }
	local elements = self._tagPrefixIndex[prefix]
	if elements == nil then
		return {}
	end

	return table.clone(elements) :: any
end

function AnatomyInstance.setParent<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	parent: Instance?
): ()
	self._root.Parent = parent
end

function AnatomyInstance.applyInstancePolicy<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
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

function AnatomyInstance._resolvePath<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	path: AnatomyPath
): Instance?
	return Path.resolve(self._root, path)
end

function AnatomyInstance._buildSocket<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	descriptor: SocketDescriptor<SocketT>
): AnatomySocketTypes.AnatomySocketImpl<SocketT>
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

function AnatomyInstance._buildTaggedElement<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	descriptor: TagDescriptor<TagT>
): AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TagT>
	local instance = self:_resolvePath(descriptor.path)
	if instance == nil then
		error(`Anatomy tag path did not resolve under {self._root:GetFullName()}`, 2)
	end

	return AnatomyTaggedElement.fromDescriptor(self, descriptor, instance) :: any
end

function AnatomyInstance.deconstruct<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	for name, socket in self._sockets do
		socket:deconstruct()
		self._sockets[name] = nil
	end
	for name, part in self._parts do
		part:deconstruct()
		self._parts[name] = nil
	end
	for index, element in self._taggedElements do
		element:deconstruct()
		self._taggedElements[index] = nil
	end
	table.clear(self._tagPrefixIndex)

	if self._ownsRoot then
		self._root:Destroy()
	end

	self._template = nil
	self._root = nil :: any
end

return AnatomyInstance
