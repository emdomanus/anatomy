--!strict
--!optimize 2
--!native

--------------------------------------------------------------------------------
-- Names / Roles
--------------------------------------------------------------------------------

export type AnatomyRole = "rig" | "addon"
export type AnatomyCategory = string
export type AnatomyId = string
export type LayerId = string

export type PartName = string

--------------------------------------------------------------------------------
-- Paths
--------------------------------------------------------------------------------

export type AnatomyPathStep = {
	name: string,
	className: string?,
	ordinal: number?,
}

export type AnatomyPath = { AnatomyPathStep }

--------------------------------------------------------------------------------
-- Recognition
--------------------------------------------------------------------------------

export type DescriptorMetadata = { [string]: any }

export type NameGuard<TName> = (name: string) -> boolean

export type SocketDescriptor<TSocketName> = {
	name: TSocketName,
	path: AnatomyPath,
	metadata: DescriptorMetadata?,
}

export type TagDescriptor<TagT> = {
	path: AnatomyPath,
	tags: { [TagT]: true },
	prefixes: { [string]: true },
}

export type PartDescriptor = {
	name: PartName,
	path: AnatomyPath,
	metadata: DescriptorMetadata?,
}

export type InstancePolicy = {
	canCollide: boolean?,
	canQuery: boolean?,
	canTouch: boolean?,
	audioCanCollide: boolean?,
	castShadow: boolean?,
	enableFluidForces: boolean?,
	massless: boolean?,
	anchored: boolean?,
}

export type RecognizeOptions<TSocketName, TSurfaceName> = {
	id: AnatomyId?,
	category: AnatomyCategory?,

	socketAttribute: string?,
	partAttribute: string?,
	tagsAttribute: string?,
	tagDelimiter: string?,
	tagPathDelimiter: string?,
	socketNameGuard: NameGuard<TSocketName>?,
	tagGuard: ((path: string) -> TSurfaceName?)?,

	instancePolicy: InstancePolicy?,

	metadata: DescriptorMetadata?,
}

export type RecognizeConfig<TSocketName, TSurfaceName> = RecognizeOptions<TSocketName, TSurfaceName> & {
	role: AnatomyRole,
}

return {}
