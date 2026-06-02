--!strict
--!optimize 2
--!native

local AnatomyHost = require(script.Parent.Parent.managers.anatomyHost)
local AnatomyTemplate = require(script.Parent.Parent.components.anatomyTemplate)
local SocketEndpoint = require(script.Parent.Parent.components.socketEndpoint)
local SocketMount = require(script.Parent.Parent.components.socketMount)
local Types = require(script.Parent.Parent.types.services.anatomyService)

export type AnatomyHost = Types.AnatomyHost
export type AnatomyHostOptions = Types.AnatomyHostOptions
export type AnatomyInstance = Types.AnatomyInstance
export type AnatomyService = Types.AnatomyService
export type AnatomyServiceImpl = Types.AnatomyServiceImpl
export type AnatomyTemplate = Types.AnatomyTemplate
export type RecognizeConfig = Types.RecognizeConfig
export type RecognizeOptions = Types.RecognizeOptions
export type SocketEndpoint = Types.SocketEndpoint
export type SocketMount = Types.SocketMount
export type SocketMountOptions = Types.SocketMountOptions

local AnatomyService: AnatomyServiceImpl = {
	_templatesBySource = {},
	_nextHostId = 1,
} :: any

local function buildRecognizeConfig(role: "rig" | "addon", options: RecognizeOptions): RecognizeConfig
	local config = table.clone(options) :: any
	config.role = role
	return config :: RecognizeConfig
end

function AnatomyService.recognize(root: Instance, config: RecognizeConfig): AnatomyTemplate
	local template = AnatomyTemplate.recognize(root, config) :: any
	AnatomyService._templatesBySource[root] = template
	return template
end

function AnatomyService.recognizeRig(root: Instance, options: RecognizeOptions): AnatomyTemplate
	return AnatomyService.recognize(root, buildRecognizeConfig("rig", options))
end

function AnatomyService.recognizeAddon(root: Instance, options: RecognizeOptions): AnatomyTemplate
	return AnatomyService.recognize(root, buildRecognizeConfig("addon", options))
end

function AnatomyService.wrap(root: Instance, template: AnatomyTemplate): AnatomyInstance
	return template:wrap(root)
end

function AnatomyService.createHost(options: AnatomyHostOptions?): AnatomyHost
	local hostOptions = if options then table.clone(options) else {}
	if hostOptions.id == nil then
		hostOptions.id = `host_{AnatomyService._nextHostId}`
		AnatomyService._nextHostId += 1
	end

	return AnatomyHost.new(hostOptions)
end

function AnatomyService.mount(
	from: SocketEndpoint,
	to: SocketEndpoint,
	options: SocketMountOptions?
): SocketMount
	return SocketMount.new(from, to, options)
end

function AnatomyService.attach(
	from: Attachment,
	to: Attachment,
	options: SocketMountOptions?
): SocketMount
	return SocketMount.new(SocketEndpoint.fromAttachment(from), SocketEndpoint.fromAttachment(to), options)
end

return AnatomyService
