--!strict
--!optimize 2

local AnatomyTaggedElementTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.types.def.anatomy.shared.anatomy)

type AnatomyPath = AnatomyTypes.AnatomyPath
type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
type AnatomyTaggedElementOwned<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElementOwned<TagT>
type AnatomyTaggedElementImpl<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElementImpl<TagT>
type TagDescriptor<TagT> = AnatomyTypes.TagDescriptor<TagT>

local emptyTags = table.freeze({})

local AnatomyTaggedElement = {}
AnatomyTaggedElement.__index = AnatomyTaggedElement

function AnatomyTaggedElement.new<TagT>(
	path: AnatomyPath,
	tags: { [TagT]: true },
	prefixes: { [string]: true },
	instance: Instance?,
	tagPathDelimiter: string
): AnatomyTaggedElementOwned<TagT>
	local self: AnatomyTaggedElementImpl<TagT> =
		setmetatable({}, AnatomyTaggedElement) :: AnatomyTaggedElementImpl<TagT>

	self._path = path
	self._tags = tags
	self._prefixes = prefixes
	self._instance = instance
	self._tagPathDelimiter = tagPathDelimiter
	self._destroyed = false

	return self
end

function AnatomyTaggedElement.fromDescriptor<TagT>(
	descriptor: TagDescriptor<TagT>,
	instance: Instance?,
	tagPathDelimiter: string
): AnatomyTaggedElementOwned<TagT>
	return AnatomyTaggedElement.new(
		descriptor.path,
		descriptor.tags,
		descriptor.prefixes,
		instance,
		tagPathDelimiter
	)
end

function AnatomyTaggedElement.getInstance<TagT>(self: AnatomyTaggedElementImpl<TagT>): Instance
	return self._instance :: Instance
end

function AnatomyTaggedElement.getTags<TagT>(self: AnatomyTaggedElementImpl<TagT>): { [TagT]: true }
	if self._destroyed then
		return emptyTags :: { [TagT]: true }
	end

	return self._tags
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

		local tagPath = tag :: string
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
end

return AnatomyTaggedElement
