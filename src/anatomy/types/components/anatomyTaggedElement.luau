--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.def)

export type AnatomyPath = DefTypes.AnatomyPath
export type TagDescriptor<TagT> = DefTypes.TagDescriptor<TagT>

export type AnatomyTaggedElement<TagT> = {
	getInstance: (self: AnatomyTaggedElement<TagT>) -> Instance,
	getTags: (self: AnatomyTaggedElement<TagT>) -> { [TagT]: true },
	hasTag: (self: AnatomyTaggedElement<TagT>, prefix: string) -> boolean,
	getLeafUnder: (self: AnatomyTaggedElement<TagT>, prefix: string) -> string?,
	deconstruct: (self: AnatomyTaggedElement<TagT>) -> (),
}

export type AnatomyTaggedElementImpl<TagT> = AnatomyTaggedElement<TagT> & {
	_owner: any,
	_path: AnatomyPath,
	_instance: Instance?,
	_tags: { [TagT]: true },
	_prefixes: { [string]: true },
	_tagPathDelimiter: string,
	_destroyed: boolean,
}

return {}
