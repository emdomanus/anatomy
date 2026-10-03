--!strict
--!optimize 2

local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)

type AnatomyPath = AnatomyTypes.AnatomyPath
export type AnatomyTaggedElement<TagT> = {
	read getInstance: (self: AnatomyTaggedElement<TagT>) -> Instance,
	read getTags: (self: AnatomyTaggedElement<TagT>) -> { [TagT]: true },
	read hasTag: (self: AnatomyTaggedElement<TagT>, prefix: string) -> boolean,
	read getLeafUnder: (self: AnatomyTaggedElement<TagT>, prefix: string) -> string?,
}
export type AnatomyTaggedElementOwned<TagT> = AnatomyTaggedElement<TagT> & {
	read deconstruct: (self: AnatomyTaggedElementOwned<TagT>) -> (),
}
export type AnatomyTaggedElementImpl<TagT> = AnatomyTaggedElementOwned<TagT> & {
	_path: AnatomyPath,
	_instance: Instance?,
	_tags: { [TagT]: true },
	_prefixes: { [string]: true },
	_tagPathDelimiter: string,
	_destroyed: boolean,
}
return {}
