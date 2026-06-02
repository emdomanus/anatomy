--!strict
--!optimize 2
--!native

local AnatomyHostTypes = require(script.Parent.Parent.managers.anatomyHost)
local AnatomyInstanceTypes = require(script.Parent.Parent.components.anatomyInstance)
local AnatomyTemplateTypes = require(script.Parent.Parent.components.anatomyTemplate)
local SocketEndpointTypes = require(script.Parent.Parent.components.socketEndpoint)
local SocketMountTypes = require(script.Parent.Parent.components.socketMount)
local DefTypes = require(script.Parent.Parent.def)

export type AnatomyHost = AnatomyHostTypes.AnatomyHost
export type AnatomyHostOptions = AnatomyHostTypes.AnatomyHostOptions
export type AnatomyInstance = AnatomyInstanceTypes.AnatomyInstance
export type AnatomyTemplate = AnatomyTemplateTypes.AnatomyTemplate
export type RecognizeConfig = DefTypes.RecognizeConfig
export type RecognizeOptions = DefTypes.RecognizeOptions
export type SocketEndpoint = SocketEndpointTypes.SocketEndpoint
export type SocketMount = SocketMountTypes.SocketMount
export type SocketMountOptions = SocketMountTypes.SocketMountOptions

export type AnatomyService = {
	recognize: (root: Instance, config: RecognizeConfig) -> AnatomyTemplate,
	recognizeRig: (root: Instance, options: RecognizeOptions) -> AnatomyTemplate,
	recognizeAddon: (root: Instance, options: RecognizeOptions) -> AnatomyTemplate,
	wrap: (root: Instance, template: AnatomyTemplate) -> AnatomyInstance,
	createHost: (options: AnatomyHostOptions?) -> AnatomyHost,
	mount: (
		from: SocketEndpoint,
		to: SocketEndpoint,
		options: SocketMountOptions?
	) -> SocketMount,
	attach: (
		from: Attachment,
		to: Attachment,
		options: SocketMountOptions?
	) -> SocketMount,
}

export type AnatomyServiceImpl = AnatomyService & {
	_nextHostId: number,
}

return {}
