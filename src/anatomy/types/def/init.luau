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

export type SocketName = string
export type SurfaceName = string
export type PartName = string
export type MountName = string

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

export type SocketDescriptor = {
	name: SocketName,
	path: AnatomyPath,
	metadata: DescriptorMetadata?,
}

export type SurfaceDescriptor = {
	name: SurfaceName,
	paths: { AnatomyPath },
	metadata: DescriptorMetadata?,
}

export type PartDescriptor = {
	name: PartName,
	path: AnatomyPath,
	metadata: DescriptorMetadata?,
}

export type SocketAddress = {
	socket: SocketName,
	layerId: LayerId?,
	includeOverrides: boolean?,
}

export type MountSpec = {
	name: MountName?,
	from: SocketAddress,
	to: SocketAddress,
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

export type RecognizeOptions = {
	id: AnatomyId?,
	category: AnatomyCategory?,

	socketAttribute: string?,
	surfaceAttribute: string?,
	partAttribute: string?,
	mountNameAttribute: string?,
	mountFromAttribute: string?,
	mountToAttribute: string?,
	socketOverrideAttribute: string?,

	instancePolicy: InstancePolicy?,

	metadata: DescriptorMetadata?,
}

export type RecognizeConfig = RecognizeOptions & {
	role: AnatomyRole,
}

return {}
