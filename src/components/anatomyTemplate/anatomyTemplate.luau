--!strict
--!optimize 2
-- Builds an anatomy template from an element table: which element carries each socket name, and
-- which elements are tagged under each tag prefix. It reads `authoredAttributes` of each element, in
-- element-index order, once, and returns frozen data. It reads no model and calls no engine.
local AnatomyTemplateTypes =
	require("../../types/components/anatomyTemplate/anatomyTemplate/public")

type AnatomyElement = AnatomyTemplateTypes.AnatomyElement
type AnatomyTemplate = AnatomyTemplateTypes.AnatomyTemplate
export type AnatomyTemplateModule = {
	-- An element whose `socketAttribute` attribute is set is a socket named by that string; a name
	-- may appear once per table. An element whose `tagsAttribute` attribute is set is a tagged
	-- element: the string is a list of tags separated by ";", each trimmed of surrounding spaces,
	-- an empty entry skipped. A socket name and a tag are each one or more segments of letters,
	-- digits and "_" joined by "."; an element is found under every prefix of each of its tags.
	-- Raises, naming the element index, for an attribute that is not a string, a name that is not
	-- of that form, and a socket name a lower element index already carries.
	read new: (
		elements: { read [number]: AnatomyElement },
		socketAttribute: string,
		tagsAttribute: string
	) -> AnatomyTemplate,
}

-- Between the tags of one attribute, and between the segments of one name.
local TAG_DELIMITER = ";"
local SEGMENT_DELIMITER = "."
local SEGMENT_PATTERN = "^[%w_]+$"

local function isDottedName(name: string): boolean
	for _, segment in string.split(name, SEGMENT_DELIMITER) do
		if string.match(segment, SEGMENT_PATTERN) == nil then
			return false
		end
	end
	return true
end

local function new(
	elements: { read [number]: AnatomyElement },
	socketAttribute: string,
	tagsAttribute: string
): AnatomyTemplate
	local socketNames: { string } = {}
	local socketElementIndexByName: { [string]: number } = {}
	local taggedPrefixes: { string } = {}
	local taggedElementIndexesByPrefix: { [string]: { number } } = {}

	for elementIndex = 1, #elements do
		local authoredAttributes = elements[elementIndex].authoredAttributes

		local socketName = authoredAttributes[socketAttribute]
		if socketName ~= nil then
			if type(socketName) ~= "string" or not isDottedName(socketName) then
				error(
					`Anatomy element {elementIndex}: attribute "{socketAttribute}" must be a socket name, segments of letters, digits and "_" joined by ".", got {tostring(
						socketName
					)}`,
					2
				)
			end
			local otherElementIndex = socketElementIndexByName[socketName]
			if otherElementIndex ~= nil then
				error(
					`Anatomy element {elementIndex}: socket "{socketName}" is already on element {otherElementIndex}`,
					2
				)
			end
			table.insert(socketNames, socketName)
			socketElementIndexByName[socketName] = elementIndex
		end

		local tags = authoredAttributes[tagsAttribute]
		if tags ~= nil then
			if type(tags) ~= "string" then
				error(
					`Anatomy element {elementIndex}: attribute "{tagsAttribute}" must be a string, got {tostring(
						tags
					)}`,
					2
				)
			end
			for _, entry in string.split(tags, TAG_DELIMITER) do
				local tag = string.match(entry, "^%s*(.-)%s*$") :: string
				if tag ~= "" then
					if not isDottedName(tag) then
						error(
							`Anatomy element {elementIndex}: tag "{tag}" must be segments of letters, digits and "_" joined by "."`,
							2
						)
					end
					local prefix = ""
					for _, segment in string.split(tag, SEGMENT_DELIMITER) do
						prefix = if prefix == ""
							then segment
							else prefix .. SEGMENT_DELIMITER .. segment
						local elementIndexes = taggedElementIndexesByPrefix[prefix]
						if elementIndexes == nil then
							elementIndexes = {}
							taggedElementIndexesByPrefix[prefix] = elementIndexes
							table.insert(taggedPrefixes, prefix)
						end
						-- Elements are read in ascending order, so an element two of whose tags share
						-- this prefix is already the last entry.
						if elementIndexes[#elementIndexes] ~= elementIndex then
							table.insert(elementIndexes, elementIndex)
						end
					end
				end
			end
		end
	end

	for _, elementIndexes in taggedElementIndexesByPrefix do
		table.freeze(elementIndexes)
	end
	local anatomyTemplate: AnatomyTemplate = table.freeze({
		socketNames = table.freeze(socketNames),
		socketElementIndexByName = table.freeze(socketElementIndexByName),
		taggedPrefixes = table.freeze(taggedPrefixes),
		taggedElementIndexesByPrefix = table.freeze(taggedElementIndexesByPrefix),
	})
	return anatomyTemplate
end

local module: AnatomyTemplateModule = table.freeze({ new = new })
return module
