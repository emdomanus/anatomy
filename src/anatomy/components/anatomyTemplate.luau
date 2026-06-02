--!strict
--!optimize 2
--!native

local AnatomyInstance = require(script.Parent.anatomyInstance)
local Path = require(script.Parent.Parent.utils.path)
local Types = require(script.Parent.Parent.types.components.anatomyTemplate)

export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyId = Types.AnatomyId
export type AnatomyInstance = Types.AnatomyInstance
export type AnatomyRole = Types.AnatomyRole
export type AnatomyTemplate = Types.AnatomyTemplate
export type AnatomyTemplateImpl = Types.AnatomyTemplateImpl
export type DescriptorMetadata = Types.DescriptorMetadata
export type MountSpec = Types.MountSpec
export type PartDescriptor = Types.PartDescriptor
export type PartName = Types.PartName
export type RecognizeConfig = Types.RecognizeConfig
export type SocketDescriptor = Types.SocketDescriptor
export type SocketName = Types.SocketName
export type SurfaceDescriptor = Types.SurfaceDescriptor
export type SurfaceName = Types.SurfaceName

local AnatomyTemplate = {}
AnatomyTemplate.__index = AnatomyTemplate

local function getAttributeName(config: RecognizeConfig, key: string): string?
	local attributeName = (config :: any)[key]
	if attributeName == nil or attributeName == "" then
		return nil
	end

	return attributeName
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

local function readMountAddress(instance: Instance, attributeName: string, descriptorKind: string): { socket: string }?
	local socket = readNamedAttribute(instance, attributeName, descriptorKind)
	if socket == nil then
		return nil
	end

	return {
		socket = socket,
	}
end

function AnatomyTemplate.recognize(root: Instance, config: RecognizeConfig): AnatomyTemplate
	local socketAttribute = getAttributeName(config, "socketAttribute")
	local surfaceAttribute = getAttributeName(config, "surfaceAttribute")
	local partAttribute = getAttributeName(config, "partAttribute")
	local mountNameAttribute = getAttributeName(config, "mountNameAttribute")
	local mountFromAttribute = getAttributeName(config, "mountFromAttribute")
	local mountToAttribute = getAttributeName(config, "mountToAttribute")

	local socketDescriptors: { [SocketName]: SocketDescriptor } = {}
	local surfaceDescriptors: { [SurfaceName]: SurfaceDescriptor } = {}
	local partDescriptors: { [PartName]: PartDescriptor } = {}
	local mountSpecs: { MountSpec } = {}

	for _, instance in makeSearchList(root) do
		if socketAttribute ~= nil then
			local socketName = readNamedAttribute(instance, socketAttribute, "socket")
			if socketName ~= nil then
				if socketDescriptors[socketName] ~= nil then
					error(`Duplicate anatomy socket "{socketName}" in {root:GetFullName()}`, 2)
				end
				if not instance:IsA("Attachment") then
					error(
						`Anatomy socket "{socketName}" is on {instance.ClassName}; socket attributes must be on Attachment instances`,
						2
					)
				end

				socketDescriptors[socketName] = {
					name = socketName,
					path = Path.fromRoot(root, instance),
				}
			end
		end

		if surfaceAttribute ~= nil then
			local surfaceName = readNamedAttribute(instance, surfaceAttribute, "surface")
			if surfaceName ~= nil then
				local descriptor = surfaceDescriptors[surfaceName]
				if descriptor == nil then
					descriptor = {
						name = surfaceName,
						paths = {},
					}
					surfaceDescriptors[surfaceName] = descriptor
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

		if mountFromAttribute ~= nil or mountToAttribute ~= nil then
			local from = if mountFromAttribute ~= nil
				then readMountAddress(instance, mountFromAttribute, "mount from")
				else nil
			local to = if mountToAttribute ~= nil then readMountAddress(instance, mountToAttribute, "mount to") else nil

			if from ~= nil or to ~= nil then
				if from == nil or to == nil then
					error(`Anatomy mount spec on {instance:GetFullName()} must define both from and to`, 2)
				end

				table.insert(mountSpecs, {
					name = if mountNameAttribute ~= nil
						then readNamedAttribute(instance, mountNameAttribute, "mount name")
						else nil,
					from = from,
					to = to,
				})
			end
		end
	end

	return AnatomyTemplate.new(root, config, socketDescriptors, surfaceDescriptors, partDescriptors, mountSpecs)
end

function AnatomyTemplate.new(
	source: Instance,
	config: RecognizeConfig,
	socketDescriptors: { [SocketName]: SocketDescriptor }?,
	surfaceDescriptors: { [SurfaceName]: SurfaceDescriptor }?,
	partDescriptors: { [PartName]: PartDescriptor }?,
	mountSpecs: { MountSpec }?
): AnatomyTemplate
	local self: AnatomyTemplateImpl = setmetatable({}, AnatomyTemplate) :: any

	self._id = config.id
	self._role = config.role
	self._category = config.category
	self._source = source
	self._config = config
	self._metadata = config.metadata
	self._socketDescriptors = socketDescriptors or {}
	self._surfaceDescriptors = surfaceDescriptors or {}
	self._partDescriptors = partDescriptors or {}
	self._mountSpecs = mountSpecs or {}

	return self
end

function AnatomyTemplate.getId(self: AnatomyTemplateImpl): AnatomyId?
	return self._id
end

function AnatomyTemplate.getRole(self: AnatomyTemplateImpl): AnatomyRole
	return self._role
end

function AnatomyTemplate.getCategory(self: AnatomyTemplateImpl): AnatomyCategory?
	return self._category
end

function AnatomyTemplate.getSource(self: AnatomyTemplateImpl): Instance
	return self._source
end

function AnatomyTemplate.getMetadata(self: AnatomyTemplateImpl): DescriptorMetadata?
	return self._metadata
end

function AnatomyTemplate.getSocketDescriptor(
	self: AnatomyTemplateImpl,
	name: SocketName
): SocketDescriptor?
	return self._socketDescriptors[name]
end

function AnatomyTemplate.getSocketDescriptors(
	self: AnatomyTemplateImpl
): { [SocketName]: SocketDescriptor }
	return table.clone(self._socketDescriptors)
end

function AnatomyTemplate.getSurfaceDescriptor(
	self: AnatomyTemplateImpl,
	name: SurfaceName
): SurfaceDescriptor?
	return self._surfaceDescriptors[name]
end

function AnatomyTemplate.getSurfaceDescriptors(
	self: AnatomyTemplateImpl
): { [SurfaceName]: SurfaceDescriptor }
	return table.clone(self._surfaceDescriptors)
end

function AnatomyTemplate.getPartDescriptor(self: AnatomyTemplateImpl, name: PartName): PartDescriptor?
	return self._partDescriptors[name]
end

function AnatomyTemplate.getPartDescriptors(self: AnatomyTemplateImpl): { [PartName]: PartDescriptor }
	return table.clone(self._partDescriptors)
end

function AnatomyTemplate.getMountSpecs(self: AnatomyTemplateImpl): { MountSpec }
	return table.clone(self._mountSpecs)
end

function AnatomyTemplate.instantiate(self: AnatomyTemplateImpl, parent: Instance?): AnatomyInstance
	local root = self._source:Clone()
	root.Parent = parent

	return AnatomyInstance.new(self, root, true)
end

function AnatomyTemplate.wrap(self: AnatomyTemplateImpl, root: Instance): AnatomyInstance
	return AnatomyInstance.new(self, root, false)
end

return AnatomyTemplate
