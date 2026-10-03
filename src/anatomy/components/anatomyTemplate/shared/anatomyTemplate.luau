--!strict
--!optimize 2

local AnatomyInstance = require(script.Parent.Parent.Parent.anatomyInstance.shared.anatomyInstance)
local AnatomyPath = require(script.Parent.Parent.Parent.Parent.utils.anatomyPath.shared.anatomyPath)
local AnatomyInstanceTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyInstance.shared.anatomyInstance
)
local AnatomyTemplateTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate.shared.anatomyTemplate
)

type AnatomyCategory = AnatomyTemplateTypes.AnatomyCategory
type AnatomyId = AnatomyTemplateTypes.AnatomyId
type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>
type AnatomyTemplateImpl<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplateImpl<SocketT, TagT>
type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
type DescriptorMetadata = AnatomyTemplateTypes.DescriptorMetadata
type RecognizeConfig<SocketT, TagT> = AnatomyTemplateTypes.RecognizeConfig<SocketT, TagT>
type SocketDescriptor<SocketT> = AnatomyTemplateTypes.SocketDescriptor<SocketT>
type TagDescriptor<TagT> = AnatomyTemplateTypes.TagDescriptor<TagT>

type AnatomyPath = AnatomyTemplateTypes.AnatomyPath
type InstancePolicy = AnatomyTemplateTypes.InstancePolicy

local function snapshotPath(path: AnatomyPath): AnatomyPath
	local result: AnatomyPath = {}
	for _, step in path do
		table.insert(result, table.freeze(table.clone(step)))
	end
	return table.freeze(result)
end

local function snapshotMetadata(metadata: DescriptorMetadata?): DescriptorMetadata?
	return if metadata == nil then nil else table.freeze(table.clone(metadata))
end

local function snapshotSocketDescriptors<SocketT>(
	descriptors: { [SocketT]: SocketDescriptor<SocketT> }?
): { [SocketT]: SocketDescriptor<SocketT> }
	local result: { [SocketT]: SocketDescriptor<SocketT> } = {}
	if descriptors ~= nil then
		for name, descriptor in descriptors do
			result[name] = table.freeze({
				name = descriptor.name,
				path = snapshotPath(descriptor.path),
				metadata = snapshotMetadata(descriptor.metadata),
			})
		end
	end
	return table.freeze(result)
end

local function snapshotTagDescriptors<TagT>(
	descriptors: { TagDescriptor<TagT> }?
): { TagDescriptor<TagT> }
	local result: { TagDescriptor<TagT> } = {}
	if descriptors ~= nil then
		for _, descriptor in descriptors do
			table.insert(
				result,
				table.freeze({
					path = snapshotPath(descriptor.path),
					tags = table.freeze(table.clone(descriptor.tags)),
					prefixes = table.freeze(table.clone(descriptor.prefixes)),
				})
			)
		end
	end
	return table.freeze(result)
end

local function getAttributeName(attributeName: string?): string?
	return if attributeName == "" then nil else attributeName
end

local function readNamedAttribute(
	instance: Instance,
	attributeName: string,
	descriptorKind: string
): string?
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

local function addTagPrefixes(
	prefixes: { [string]: true },
	tagPath: string,
	tagPathDelimiter: string
): ()
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
	tagGuard: (unknown) -> TagT,
	root: Instance
): ({ [TagT]: true }?, { [string]: true }?)
	local value = instance:GetAttribute(tagsAttribute)
	if value == nil then
		return nil, nil
	end
	if typeof(value) ~= "string" then
		error(
			`Anatomy tag attribute "{tagsAttribute}" on {instance:GetFullName()} must be a string`,
			3
		)
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

		local tag = tagGuard(tagPath)
		if tag ~= tagPath then
			error(`Anatomy tag "{tagPath}" is not allowed in {root:GetFullName()}`, 3)
		end

		tags[tag] = true
		addTagPrefixes(prefixes, tagPath, tagPathDelimiter)
	end

	return tags, prefixes
end

local function hasEntries<K, V>(values: { [K]: V }): boolean
	for _ in values do
		return true
	end

	return false
end

local function makeSearchList(root: Instance): { Instance }
	local list: { Instance } = table.create(#root:GetDescendants() + 1) :: { Instance }
	table.insert(list, root)

	for _, descendant in root:GetDescendants() do
		table.insert(list, descendant)
	end

	return list
end

local AnatomyTemplate = {}
AnatomyTemplate.__index = AnatomyTemplate

function AnatomyTemplate.recognize<SocketT, TagT>(
	root: Instance,
	config: RecognizeConfig<SocketT, TagT>
): AnatomyTemplate<SocketT, TagT>
	local socketAttribute = getAttributeName(config.socketAttribute)
	local tagsAttribute = getAttributeName(config.tagsAttribute)
	local tagDelimiter = if config.tagDelimiter ~= nil and config.tagDelimiter ~= ""
		then config.tagDelimiter
		else ";"
	local tagPathDelimiter = if config.tagPathDelimiter ~= nil
			and config.tagPathDelimiter ~= ""
		then config.tagPathDelimiter
		else "."

	local socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> } = {}
	local tagDescriptors: { TagDescriptor<TagT> } = {}

	for _, instance in makeSearchList(root) do
		if socketAttribute ~= nil then
			local socketName = readNamedAttribute(instance, socketAttribute, "socket")
			if socketName ~= nil then
				local typedSocketName = config.socketNameGuard(socketName)
				assert(typedSocketName == socketName, "Socket guards must preserve identity")
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
					path = AnatomyPath.fromRoot(root, instance),
				}
			end
		end

		if tagsAttribute ~= nil then
			local tags, prefixes = readTagList(
				instance,
				tagsAttribute,
				tagDelimiter,
				tagPathDelimiter,
				config.tagGuard,
				root
			)
			if tags ~= nil and prefixes ~= nil and hasEntries(tags) then
				table.insert(tagDescriptors, {
					path = AnatomyPath.fromRoot(root, instance),
					tags = tags,
					prefixes = prefixes,
				})
			end
		end
	end

	return AnatomyTemplate.new(root, config, socketDescriptors, tagDescriptors)
end

function AnatomyTemplate.new<SocketT, TagT>(
	source: Instance,
	config: RecognizeConfig<SocketT, TagT>,
	socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> }?,
	tagDescriptors: { TagDescriptor<TagT> }?
): AnatomyTemplate<SocketT, TagT>
	local self: AnatomyTemplateImpl<SocketT, TagT> =
		setmetatable({}, AnatomyTemplate) :: AnatomyTemplateImpl<SocketT, TagT>

	self._id = config.id
	self._category = config.category
	self._source = source
	local options: RecognizeConfig<SocketT, TagT> = table.freeze({
		id = config.id,
		category = config.category,
		socketAttribute = config.socketAttribute,
		tagsAttribute = config.tagsAttribute,
		tagDelimiter = config.tagDelimiter,
		tagPathDelimiter = config.tagPathDelimiter,
		socketNameGuard = config.socketNameGuard,
		tagGuard = config.tagGuard,
		metadata = snapshotMetadata(config.metadata),
		instancePolicy = if config.instancePolicy
			then table.freeze(table.clone(config.instancePolicy))
			else nil,
	})
	self._config = options
	self._metadata = options.metadata
	self._socketDescriptors = snapshotSocketDescriptors(socketDescriptors)
	self._tagDescriptors = snapshotTagDescriptors(tagDescriptors)
	for name, descriptor in self._socketDescriptors do
		assert(
			config.socketNameGuard(name) == name and descriptor.name == name,
			"Invalid socket descriptor name"
		)
	end
	for _, descriptor in self._tagDescriptors do
		for tag in descriptor.tags do
			assert(config.tagGuard(tag) == tag, "Tag guards must preserve identity")
		end
	end

	return self
end

function AnatomyTemplate.getId<SocketT, TagT>(self: AnatomyTemplateImpl<SocketT, TagT>): AnatomyId?
	return self._id
end

function AnatomyTemplate.getCategory<SocketT, TagT>(self: AnatomyTemplateImpl<SocketT, TagT>): AnatomyCategory?
	return self._category
end

function AnatomyTemplate.getSource<SocketT, TagT>(self: AnatomyTemplateImpl<SocketT, TagT>): Instance
	return self._source
end

function AnatomyTemplate.getMetadata<SocketT, TagT>(self: AnatomyTemplateImpl<SocketT, TagT>): DescriptorMetadata?
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

function AnatomyTemplate.instantiate<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>,
	parent: Instance?
): AnatomyInstance<SocketT, TagT>
	local root = self._source:Clone()
	root.Parent = parent

	return AnatomyInstance.new(self, root, true, {
		socketDescriptors = self:getSocketDescriptors(),
		tagDescriptors = self:getTagDescriptors(),
		instancePolicy = self._config.instancePolicy,
		tagPathDelimiter = if self._config.tagPathDelimiter == nil
				or self._config.tagPathDelimiter == ""
			then "."
			else self._config.tagPathDelimiter,
	})
end

function AnatomyTemplate.wrap<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>,
	root: Instance
): AnatomyInstance<SocketT, TagT>
	return AnatomyInstance.new(self, root, false, {
		socketDescriptors = self:getSocketDescriptors(),
		tagDescriptors = self:getTagDescriptors(),
		instancePolicy = self._config.instancePolicy,
		tagPathDelimiter = if self._config.tagPathDelimiter == nil
				or self._config.tagPathDelimiter == ""
			then "."
			else self._config.tagPathDelimiter,
	})
end

return AnatomyTemplate
