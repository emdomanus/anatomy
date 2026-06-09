--!strict
--!optimize 2
--!native

local AnatomyInstance = require(script.Parent.Parent.Parent.anatomyInstance.shared.anatomyInstance)
local Path = require(script.Parent.Parent.Parent.Parent.utils.path)
local AnatomyInstanceTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyInstance)
local Types = require(script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate)

export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyId = Types.AnatomyId
export type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<SocketT, TagT>
export type AnatomyRole = Types.AnatomyRole
export type AnatomyTemplate<SocketT, TagT> = Types.AnatomyTemplate<SocketT, TagT>
export type AnatomyTemplateImpl<SocketT, TagT> = Types.AnatomyTemplateImpl<SocketT, TagT>
export type DescriptorMetadata = Types.DescriptorMetadata
export type PartDescriptor = Types.PartDescriptor
export type PartName = Types.PartName
export type RecognizeConfig<SocketT, TagT> = Types.RecognizeConfig<SocketT, TagT>
export type SocketDescriptor<SocketT> = Types.SocketDescriptor<SocketT>
export type TagDescriptor<TagT> = Types.TagDescriptor<TagT>

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

local function trim(value: string): string
	return (string.gsub(value, "^%s*(.-)%s*$", "%1"))
end

local function addTagPrefixes(prefixes: { [string]: true }, tagPath: string, tagPathDelimiter: string): ()
	local segments = string.split(tagPath, tagPathDelimiter)
	local prefix = ""

	for _, segment in segments do
		if segment == "" then
			continue
		end

		prefix = if prefix == "" then segment else `{prefix}{tagPathDelimiter}{segment}`
		prefixes[prefix] = true
	end
end

local function readTagList<TagT>(
	instance: Instance,
	tagsAttribute: string,
	tagDelimiter: string,
	tagPathDelimiter: string,
	tagGuard: ((path: string) -> TagT?)?,
	root: Instance
): ({ [TagT]: true }?, { [string]: true }?)
	local value = instance:GetAttribute(tagsAttribute)
	if value == nil then
		return nil, nil
	end
	if typeof(value) ~= "string" then
		error(`Anatomy tag attribute "{tagsAttribute}" on {instance:GetFullName()} must be a string`, 3)
	end

	local rawTags = value :: string
	if rawTags == "" then
		return nil, nil
	end

	local tags: { [TagT]: true } = {}
	local prefixes: { [string]: true } = {}

	for _, rawTag in string.split(rawTags, tagDelimiter) do
		local tagPath = trim(rawTag)
		if tagPath == "" then
			continue
		end

		local tag = if tagGuard == nil then (tagPath :: any) :: TagT else tagGuard(tagPath)
		if tag == nil then
			error(`Anatomy tag "{tagPath}" is not allowed in {root:GetFullName()}`, 3)
		end

		tags[tag] = true
		addTagPrefixes(prefixes, tagPath, tagPathDelimiter)
	end

	return tags, prefixes
end

local function hasEntries(values: { [any]: any }): boolean
	for _ in values do
		return true
	end

	return false
end

local function makeSearchList(root: Instance): { Instance }
	local list = table.create(#root:GetDescendants() + 1)
	table.insert(list, root)

	for _, descendant in root:GetDescendants() do
		table.insert(list, descendant)
	end

	return list
end

function AnatomyTemplate.recognize<SocketT, TagT>(
	root: Instance,
	config: RecognizeConfig<SocketT, TagT>
): AnatomyTemplate<SocketT, TagT>
	local socketAttribute = getAttributeName(config, "socketAttribute")
	local partAttribute = getAttributeName(config, "partAttribute")
	local tagsAttribute = getAttributeName(config, "tagsAttribute")
	local tagDelimiter = if config.tagDelimiter ~= nil and config.tagDelimiter ~= "" then config.tagDelimiter else ";"
	local tagPathDelimiter = if config.tagPathDelimiter ~= nil and config.tagPathDelimiter ~= "" then config.tagPathDelimiter else "."

	local socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> } = {}
	local tagDescriptors: { TagDescriptor<TagT> } = {}
	local partDescriptors: { [PartName]: PartDescriptor } = {}

	for _, instance in makeSearchList(root) do
		if socketAttribute ~= nil then
			local socketName = readNamedAttribute(instance, socketAttribute, "socket")
			if socketName ~= nil then
				assertNameAllowed(socketName, config.socketNameGuard, "socket", root)
				local typedSocketName = (socketName :: any) :: SocketT
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

		if tagsAttribute ~= nil then
			local tags, prefixes =
				readTagList(instance, tagsAttribute, tagDelimiter, tagPathDelimiter, config.tagGuard, root)
			if tags ~= nil and prefixes ~= nil and hasEntries(tags) then
				table.insert(tagDescriptors, {
					path = Path.fromRoot(root, instance),
					tags = tags,
					prefixes = prefixes,
				})
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

	return AnatomyTemplate.new(root, config, socketDescriptors, partDescriptors, tagDescriptors)
end

function AnatomyTemplate.new<SocketT, TagT>(
	source: Instance,
	config: RecognizeConfig<SocketT, TagT>,
	socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> }?,
	partDescriptors: { [PartName]: PartDescriptor }?,
	tagDescriptors: { TagDescriptor<TagT> }?
): AnatomyTemplate<SocketT, TagT>
	local self: AnatomyTemplateImpl<SocketT, TagT> = setmetatable({}, AnatomyTemplate) :: any

	self._id = config.id
	self._role = config.role
	self._category = config.category
	self._source = source
	self._config = config
	self._metadata = config.metadata
	self._socketDescriptors = socketDescriptors or {}
	self._tagDescriptors = tagDescriptors or {}
	self._partDescriptors = partDescriptors or {}

	return self
end

function AnatomyTemplate.getId<SocketT, TagT>(self: AnatomyTemplateImpl<SocketT, TagT>): AnatomyId?
	return self._id
end

function AnatomyTemplate.getRole<SocketT, TagT>(self: AnatomyTemplateImpl<SocketT, TagT>): AnatomyRole
	return self._role
end

function AnatomyTemplate.getCategory<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>
): AnatomyCategory?
	return self._category
end

function AnatomyTemplate.getSource<SocketT, TagT>(self: AnatomyTemplateImpl<SocketT, TagT>): Instance
	return self._source
end

function AnatomyTemplate.getMetadata<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>
): DescriptorMetadata?
	return self._metadata
end

function AnatomyTemplate.getSocketDescriptor<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>,
	name: SocketT
): SocketDescriptor<SocketT>?
	return self._socketDescriptors[name]
end

function AnatomyTemplate.getSocketDescriptors<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>
): { [SocketT]: SocketDescriptor<SocketT> }
	return table.clone(self._socketDescriptors)
end

function AnatomyTemplate.getTagDescriptors<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>
): { TagDescriptor<TagT> }
	return table.clone(self._tagDescriptors)
end

function AnatomyTemplate.getPartDescriptor<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>,
	name: PartName
): PartDescriptor?
	return self._partDescriptors[name]
end

function AnatomyTemplate.getPartDescriptors<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>
): { [PartName]: PartDescriptor }
	return table.clone(self._partDescriptors)
end

function AnatomyTemplate.instantiate<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>,
	parent: Instance?
): AnatomyInstance<SocketT, TagT>
	local root = self._source:Clone()
	root.Parent = parent

	return AnatomyInstance.new(self, root, true)
end

function AnatomyTemplate.wrap<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>,
	root: Instance
): AnatomyInstance<SocketT, TagT>
	return AnatomyInstance.new(self, root, false)
end

return AnatomyTemplate
