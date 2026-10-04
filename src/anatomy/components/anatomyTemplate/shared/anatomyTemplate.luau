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

local function snapshotMetadata(metadata: DescriptorMetadata?): DescriptorMetadata?
	return if metadata == nil then nil else table.freeze(table.clone(metadata))
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

local AnatomyTemplate = {}
AnatomyTemplate.__index = AnatomyTemplate

local function freezePath(path: AnatomyPath): AnatomyPath
	for _, step in path do
		table.freeze(step)
	end
	return table.freeze(path)
end

local function createTemplate<SocketT, TagT>(
	source: Instance,
	config: RecognizeConfig<SocketT, TagT>,
	socketDescriptors: { [SocketT]: SocketDescriptor<SocketT> },
	tagDescriptors: { TagDescriptor<TagT> }
): AnatomyTemplate<SocketT, TagT>
	local self: AnatomyTemplateImpl<SocketT, TagT> =
		setmetatable({}, AnatomyTemplate) :: AnatomyTemplateImpl<SocketT, TagT>

	self._category = config.category
	self._source = source
	local options: RecognizeConfig<SocketT, TagT> = table.freeze({
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
	self._socketDescriptors = socketDescriptors
	self._tagDescriptors = tagDescriptors
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

	self._instanceOptions = table.freeze({
		socketDescriptors = self._socketDescriptors,
		tagDescriptors = self._tagDescriptors,
		instancePolicy = options.instancePolicy,
		tagPathDelimiter = if options.tagPathDelimiter == nil
				or options.tagPathDelimiter == ""
			then "."
			else options.tagPathDelimiter,
	})

	return self
end

function AnatomyTemplate.new<SocketT, TagT>(
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

	local descendants = root:GetDescendants()
	-- Visit the root first without allocating a second search array.
	for index = 1, #descendants + 1 do
		local instance = if index == 1 then root else descendants[index - 1]
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

				socketDescriptors[typedSocketName] = table.freeze({
					name = typedSocketName,
					path = freezePath(AnatomyPath.fromRoot(root, instance)),
				})
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
				table.insert(
					tagDescriptors,
					table.freeze({
						path = freezePath(AnatomyPath.fromRoot(root, instance)),
						tags = table.freeze(tags),
						prefixes = table.freeze(prefixes),
					})
				)
			end
		end
	end

	return createTemplate(
		root,
		config,
		table.freeze(socketDescriptors),
		table.freeze(tagDescriptors)
	)
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

function AnatomyTemplate.instantiate<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>,
	parent: Instance?
): AnatomyInstance<SocketT, TagT>
	local root = self._source:Clone()
	root.Parent = parent

	return AnatomyInstance.new(self, root, true, self._instanceOptions)
end

function AnatomyTemplate.wrap<SocketT, TagT>(
	self: AnatomyTemplateImpl<SocketT, TagT>,
	root: Instance
): AnatomyInstance<SocketT, TagT>
	return AnatomyInstance.new(self, root, false, self._instanceOptions)
end

return AnatomyTemplate
