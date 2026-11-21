--!strict
--!optimize 2
-- An element table typed as Foundry types it passes to anatomyTemplate.new as it is, though Anatomy
-- does not require Foundry. The record below is VoxelMMO's AssetTemplateElement, all seven fields,
-- copied from src/shared/libraries/foundry/types/def/asset/shared/assetTemplate/assetTemplateData/public.luau.
local Anatomy = require("../../../../src/shared")

type AnatomyTemplate = Anatomy.AnatomyTemplate

-- Raw GetAttributes() snapshot; interpreter-specific meanings are narrowed by the reader.
type AuthoredAttributes = { read [string]: unknown }

-- Raw GetTags() snapshot in ascending order; interpreters read meanings such as effect kinds.
type AuthoredTags = { read [number]: string }

type AssetTemplateElement = {
	read index: number,
	-- The element index of this element's parent; 0 for the root.
	read parentIndex: number,
	read className: string,
	read authoredAttributes: AuthoredAttributes,
	read authoredTags: AuthoredTags,
	-- Writable property name -> its slot in propertySlots.
	-- Read-only observations receive no slots/defaults.
	-- Aliased writes (an Attachment's worldCFrame) must map to the same restore slot.
	read propertySlotsByName: { read [string]: number },
	-- Property name -> the engine's name for it, e.g. cframe -> CFrame, for every property of the
	-- element's family. One frozen table per family, shared by every element of it; empty for an
	-- element without a supported family.
	read nativePropertyNames: { read [string]: string },
}

-- AssetTemplateData.elements has this type.
local function buildFromFoundryElements(
	elements: { read [number]: AssetTemplateElement }
): AnatomyTemplate
	return Anatomy.anatomyTemplate.new(elements, "RigSocket", "RigSurface")
end

local foundryElements: { read [number]: AssetTemplateElement } = {}
local fromFoundry: AnatomyTemplate = buildFromFoundryElements(foundryElements)

-- A table written by hand passes too: an element needs `authoredAttributes` and nothing else.
local byHand: AnatomyTemplate = Anatomy.anatomyTemplate.new({
	{ authoredAttributes = {} },
	{ authoredAttributes = { RigSocket = "body.head", RigSurface = "body.head;skin" } },
}, "RigSocket", "RigSurface")

-- The template's four tables are readable, and read-only.
local _socketNames: { read [number]: string } = fromFoundry.socketNames
local _socketElementIndex: number? = byHand.socketElementIndexByName["body.head"]
local _taggedPrefixes: { read [number]: string } = byHand.taggedPrefixes
local _taggedElementIndexes: { read [number]: number }? =
	byHand.taggedElementIndexesByPrefix["skin"]
