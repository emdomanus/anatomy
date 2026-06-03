--!strict
--!optimize 2
--!native

local AnatomyInstance = require(script.Parent.Parent.Parent.anatomyInstance.shared.anatomyInstance)
local Path = require(script.Parent.Parent.Parent.Parent.utils.path)
local AnatomyInstanceTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyInstance)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate)

export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyId = Types.AnatomyId
export type AnatomyInstance<TSocketName, TSurfaceName> = AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>
export type AnatomyRole = Types.AnatomyRole
export type AnatomyTemplate<TSocketName, TSurfaceName> = Types.AnatomyTemplate<TSocketName, TSurfaceName>
export type AnatomyTemplateImpl<TSocketName, TSurfaceName> = Types.AnatomyTemplateImpl<TSocketName, TSurfaceName>
export type DescriptorMetadata = Types.DescriptorMetadata
export type PartDescriptor = Types.PartDescriptor
export type PartName = Types.PartName
export type RecognizeConfig<TSocketName, TSurfaceName> = Types.RecognizeConfig<TSocketName, TSurfaceName>
export type SocketDescriptor<TSocketName> = Types.SocketDescriptor<TSocketName>
export type SurfaceDescriptor<TSurfaceName> = Types.SurfaceDescriptor<TSurfaceName>

local AnatomyTemplate = {}
AnatomyTemplate.__index = AnatomyTemplate

local function getAttributeName(config: any, key: string): string?
	local attributeName = (config :: any)[key]
	if attributeName == nil or attributeName == "" then
		return nil
	end

	return attributeName
end

local function assertNameAllowed(
	name: string,
	guard: ((string) -> boolean)?,
	descriptorKind: string,
	root: Instance
): ()
	if guard ~= nil and not guard(name) then
		error(`Anatomy {descriptorKind} "{name}" is not allowed in {root:GetFullName()}`, 3)
	end
end

local function readNamedAttribute(instance: Instance, attributeName: string, descriptorKind: string): string?
	local value = instance:GetAttribute(attributeName)
	if value == nil then
		return nil
	end
	if typeof(value) ~= "string" or value == "" then
		error(
			`Anatomy {descriptorKind} attribute "{attributeName}" on {instance:GetFullName()} must be a non-empty string`,
			3
		)
	end

	return value :: string
end

local function makeSearchList(root: Instance): { Instance }
	local list = table.create(#root:GetDescendants() + 1)
	table.insert(list, root)

	for _, descendant in root:GetDescendants() do
		table.insert(list, descendant)
	end

	return list
end

function AnatomyTemplate.recognize<TSocketName, TSurfaceName>(
	root: Instance,
	config: RecognizeConfig<TSocketName, TSurfaceName>
): AnatomyTemplate<TSocketName, TSurfaceName>
	local socketAttribute = getAttributeName(config, "socketAttribute")
	local surfaceAttribute = getAttributeName(config, "surfaceAttribute")
	local partAttribute = getAttributeName(config, "partAttribute")

	local socketDescriptors: { [TSocketName]: SocketDescriptor<TSocketName> } = {}
	local surfaceDescriptors: { [TSurfaceName]: SurfaceDescriptor<TSurfaceName> } = {}
	local partDescriptors: { [PartName]: PartDescriptor } = {}

	for _, instance in makeSearchList(root) do
		if socketAttribute ~= nil then
			local socketName = readNamedAttribute(instance, socketAttribute, "socket")
			if socketName ~= nil then
				assertNameAllowed(socketName, config.socketNameGuard, "socket", root)
				local typedSocketName = (socketName :: any) :: TSocketName
				if socketDescriptors[typedSocketName] ~= nil then
					error(`Duplicate anatomy socket "{socketName}" in {root:GetFullName()}`, 2)
				end
				if not instance:IsA("Attachment") then
					error(
						`Anatomy socket "{socketName}" is on {instance.ClassName}; socket attributes must be on Attachment instances`,
						2
					)
				end

				socketDescriptors[typedSocketName] = {
					name = typedSocketName,
					path = Path.fromRoot(root, instance),
				}
			end
		end

		if surfaceAttribute ~= nil then
			local surfaceName = readNamedAttribute(instance, surfaceAttribute, "surface")
			if surfaceName ~= nil then
				assertNameAllowed(surfaceName, config.surfaceNameGuard, "surface", root)
				local typedSurfaceName = (surfaceName :: any) :: TSurfaceName
				local descriptor = surfaceDescriptors[typedSurfaceName]
				if descriptor == nil then
					descriptor = {
						name = typedSurfaceName,
						paths = {},
					}
					surfaceDescriptors[typedSurfaceName] = descriptor
				end

				table.insert(descriptor.paths, Path.fromRoot(root, instance))
			end
		end

		if partAttribute ~= nil then
			local partName = readNamedAttribute(instance, partAttribute, "part")
			if partName ~= nil then
				if partDescriptors[partName] ~= nil then
					error(`Duplicate anatomy part "{partName}" in {root:GetFullName()}`, 2)
				end

				partDescriptors[partName] = {
					name = partName,
					path = Path.fromRoot(root, instance),
				}
			end
		end
	end

	return AnatomyTemplate.new(root, config, socketDescriptors, surfaceDescriptors, partDescriptors)
end

function AnatomyTemplate.new<TSocketName, TSurfaceName>(
	source: Instance,
	config: RecognizeConfig<TSocketName, TSurfaceName>,
	socketDescriptors: { [TSocketName]: SocketDescriptor<TSocketName> }?,
	surfaceDescriptors: { [TSurfaceName]: SurfaceDescriptor<TSurfaceName> }?,
	partDescriptors: { [PartName]: PartDescriptor }?
): AnatomyTemplate<TSocketName, TSurfaceName>
	local self: AnatomyTemplateImpl<TSocketName, TSurfaceName> = setmetatable({}, AnatomyTemplate) :: any

	self._id = config.id
	self._role = config.role
	self._category = config.category
	self._source = source
	self._config = config
	self._metadata = config.metadata
	self._socketDescriptors = socketDescriptors or {}
	self._surfaceDescriptors = surfaceDescriptors or {}
	self._partDescriptors = partDescriptors or {}

	return self
end

function AnatomyTemplate.getId<TSocketName, TSurfaceName>(self: AnatomyTemplateImpl<TSocketName, TSurfaceName>): AnatomyId?
	return self._id
end

function AnatomyTemplate.getRole<TSocketName, TSurfaceName>(self: AnatomyTemplateImpl<TSocketName, TSurfaceName>): AnatomyRole
	return self._role
end

function AnatomyTemplate.getCategory<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>
): AnatomyCategory?
	return self._category
end

function AnatomyTemplate.getSource<TSocketName, TSurfaceName>(self: AnatomyTemplateImpl<TSocketName, TSurfaceName>): Instance
	return self._source
end

function AnatomyTemplate.getMetadata<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>
): DescriptorMetadata?
	return self._metadata
end

function AnatomyTemplate.getSocketDescriptor<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>,
	name: TSocketName
): SocketDescriptor<TSocketName>?
	return self._socketDescriptors[name]
end

function AnatomyTemplate.getSocketDescriptors<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>
): { [TSocketName]: SocketDescriptor<TSocketName> }
	return table.clone(self._socketDescriptors)
end

function AnatomyTemplate.getSurfaceDescriptor<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>,
	name: TSurfaceName
): SurfaceDescriptor<TSurfaceName>?
	return self._surfaceDescriptors[name]
end

function AnatomyTemplate.getSurfaceDescriptors<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>
): { [TSurfaceName]: SurfaceDescriptor<TSurfaceName> }
	return table.clone(self._surfaceDescriptors)
end

function AnatomyTemplate.getPartDescriptor<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>,
	name: PartName
): PartDescriptor?
	return self._partDescriptors[name]
end

function AnatomyTemplate.getPartDescriptors<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>
): { [PartName]: PartDescriptor }
	return table.clone(self._partDescriptors)
end

function AnatomyTemplate.instantiate<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>,
	parent: Instance?
): AnatomyInstance<TSocketName, TSurfaceName>
	local root = self._source:Clone()
	root.Parent = parent

	return AnatomyInstance.new(self, root, true)
end

function AnatomyTemplate.wrap<TSocketName, TSurfaceName>(
	self: AnatomyTemplateImpl<TSocketName, TSurfaceName>,
	root: Instance
): AnatomyInstance<TSocketName, TSurfaceName>
	return AnatomyInstance.new(self, root, false)
end

return AnatomyTemplate
