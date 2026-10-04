--!strict
--!optimize 2

local Guard = require(script.Parent.Parent.Parent.Parent.Parent.Parent.Parent.roblox_packages.guard)

--------------------------------------------------------------------------------
-- Names
--------------------------------------------------------------------------------

export type AnatomyCategory = string

--------------------------------------------------------------------------------
-- Paths
--------------------------------------------------------------------------------

export type AnatomyPathStep = {
	read name: string,
	read className: string?,
	read ordinal: number?,
}

export type AnatomyPath = { AnatomyPathStep }

--------------------------------------------------------------------------------
-- Recognition
--------------------------------------------------------------------------------

export type DescriptorMetadata = { [string]: unknown }

export type NameGuard<TName> = Guard.GuardFn<TName>

export type SocketDescriptor<SocketT> = {
	read name: SocketT,
	read path: AnatomyPath,
	read metadata: DescriptorMetadata?,
}

export type TagDescriptor<TagT> = {
	read path: AnatomyPath,
	read tags: { [TagT]: true },
	read prefixes: { [string]: true },
}

export type InstancePolicy = {
	read canCollide: boolean?,
	read canQuery: boolean?,
	read canTouch: boolean?,
	read audioCanCollide: boolean?,
	read castShadow: boolean?,
	read enableFluidForces: boolean?,
	read massless: boolean?,
	read anchored: boolean?,
}

export type RecognizeOptions<SocketT, TagT> = {
	read category: AnatomyCategory?,

	read socketAttribute: string?,
	read tagsAttribute: string?,
	read tagDelimiter: string?,
	read tagPathDelimiter: string?,
	read socketNameGuard: NameGuard<SocketT>,
	read tagGuard: NameGuard<TagT>,

	read instancePolicy: InstancePolicy?,

	read metadata: DescriptorMetadata?,
}

return {}
