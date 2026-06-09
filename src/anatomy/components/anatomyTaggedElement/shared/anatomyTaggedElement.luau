--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Parent.Parent.types.components.anatomyTaggedElement)

export type AnatomyPath = Types.AnatomyPath
export type AnatomyTaggedElement<TagT> = Types.AnatomyTaggedElement<TagT>
export type AnatomyTaggedElementImpl<TagT> = Types.AnatomyTaggedElementImpl<TagT>
export type TagDescriptor<TagT> = Types.TagDescriptor<TagT>

local AnatomyTaggedElement = {}
AnatomyTaggedElement.__index = AnatomyTaggedElement

local function getTagPathDelimiter(owner: any): string
	local template = if owner.getTemplate ~= nil then owner:getTemplate() else owner._template
	local config = if template ~= nil then (template :: any)._config else nil
	local delimiter = if config ~= nil then config.tagPathDelimiter else nil

	if delimiter == nil or delimiter == "" then
		return "."
	end

	return delimiter
end

function AnatomyTaggedElement.new<TagT>(
	owner: any,
	path: AnatomyPath,
	tags: { [TagT]: true },
	prefixes: { [string]: true },
	instance: Instance?,
	tagPathDelimiter: string
): AnatomyTaggedElement<TagT>
	local self: AnatomyTaggedElementImpl<TagT> = setmetatable({}, AnatomyTaggedElement) :: any

	self._owner = owner
	self._path = path
	self._tags = tags
	self._prefixes = prefixes
	self._instance = instance
	self._tagPathDelimiter = tagPathDelimiter
	self._destroyed = false

	return self
end

function AnatomyTaggedElement.fromDescriptor<TagT>(
	owner: any,
	descriptor: TagDescriptor<TagT>,
	instance: Instance?
): AnatomyTaggedElement<TagT>
	return AnatomyTaggedElement.new(owner, descriptor.path, descriptor.tags, descriptor.prefixes, instance, getTagPathDelimiter(owner))
end

function AnatomyTaggedElement.getInstance<TagT>(self: AnatomyTaggedElementImpl<TagT>): Instance
	return self._instance :: Instance
end

function AnatomyTaggedElement.getTags<TagT>(self: AnatomyTaggedElementImpl<TagT>): { [TagT]: true }
	if self._destroyed then
		return {}
	end

	return table.clone(self._tags)
end

function AnatomyTaggedElement.hasTag<TagT>(self: AnatomyTaggedElementImpl<TagT>, prefix: string): boolean
	if self._destroyed then
		return false
	end

	return self._prefixes[prefix] == true
end

function AnatomyTaggedElement.getLeafUnder<TagT>(
	self: AnatomyTaggedElementImpl<TagT>,
	prefix: string
): string?
	if self._destroyed then
		return nil
	end

	local needle = `{prefix}{self._tagPathDelimiter}`
	local needleLength = #needle

	for tag in self._tags do
		if typeof(tag) ~= "string" then
			continue
		end

		local tagPath = (tag :: any) :: string
		if string.sub(tagPath, 1, needleLength) == needle then
			return string.sub(tagPath, needleLength + 1)
		end
	end

	return nil
end

function AnatomyTaggedElement.deconstruct<TagT>(self: AnatomyTaggedElementImpl<TagT>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true
	self._instance = nil
	self._owner = nil
end

return AnatomyTaggedElement
