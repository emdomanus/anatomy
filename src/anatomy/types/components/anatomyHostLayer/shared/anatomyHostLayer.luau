--!strict
--!optimize 2

local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)
local AnatomyInstanceTypes =
	require(script.Parent.Parent.Parent.anatomyInstance.shared.anatomyInstance)
local AnatomyTemplateTypes =
	require(script.Parent.Parent.Parent.anatomyTemplate.shared.anatomyTemplate)
local AnatomyHostLayerCommandsTypes = require(
	script.Parent.Parent.Parent.Parent.ports.managers.anatomyHost.shared.anatomyHostLayerCommands
)

type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>

type LayerId = AnatomyTypes.LayerId
type AnatomyCategory = AnatomyTypes.AnatomyCategory
type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
type AnatomyHostLayerCommands = AnatomyHostLayerCommandsTypes.AnatomyHostLayerCommands
export type AnatomyHostLayerOptions = {
	id: LayerId?,
	priority: number?,
	category: AnatomyCategory?,
	allowSocketOverrides: boolean?,
}
export type AnatomyHostLayer<SocketT, TagT> = {
	read id: LayerId,
	read getInstance: (self: AnatomyHostLayer<SocketT, TagT>) -> AnatomyInstance<SocketT, TagT>,
	read getPriority: (self: AnatomyHostLayer<SocketT, TagT>) -> number,
	read setPriority: (self: AnatomyHostLayer<SocketT, TagT>, priority: number) -> (),
	read remove: (self: AnatomyHostLayer<SocketT, TagT>) -> (),
}
export type AnatomyHostLayerOwned<SocketT, TagT> = AnatomyHostLayer<SocketT, TagT> & {
	read getRegistration: (self: AnatomyHostLayerOwned<SocketT, TagT>) -> number,
	read allowsSocketOverrides: (self: AnatomyHostLayerOwned<SocketT, TagT>) -> boolean,
	read applyPriority: (self: AnatomyHostLayerOwned<SocketT, TagT>, priority: number) -> (),
	read deconstruct: (self: AnatomyHostLayerOwned<SocketT, TagT>) -> (),
}
export type AnatomyHostLayerImpl<SocketT, TagT> = AnatomyHostLayerOwned<SocketT, TagT> & {
	_host: AnatomyHostLayerCommands,
	_instance: AnatomyInstance<SocketT, TagT>,
	_priority: number,
	_category: AnatomyCategory?,
	_allowSocketOverrides: boolean,
	_insertOrder: number,
	_destroyed: boolean,
}
return {}
