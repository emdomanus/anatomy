--!strict
--!optimize 2

local AnatomyHostLayerTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyHostLayer.shared.anatomyHostLayer
)
local AnatomyHostLayerCommandsTypes = require(
	script.Parent.Parent.Parent.Parent.types.ports.managers.anatomyHost.shared.anatomyHostLayerCommands
)
local AnatomyInstanceTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyInstance.shared.anatomyInstance
)
local AnatomyTemplateTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate.shared.anatomyTemplate
)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.types.def.anatomy.shared.anatomy)

type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>

type AnatomyHostLayerImpl<SocketT, TagT> = AnatomyHostLayerTypes.AnatomyHostLayerImpl<SocketT, TagT>
type AnatomyHostLayerOwned<SocketT, TagT> = AnatomyHostLayerTypes.AnatomyHostLayerOwned<
	SocketT,
	TagT
>
type AnatomyHostLayerCommands = AnatomyHostLayerCommandsTypes.AnatomyHostLayerCommands
type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
type AnatomyCategory = AnatomyTypes.AnatomyCategory
type LayerId = AnatomyTypes.LayerId
local AnatomyHostLayer = {}
AnatomyHostLayer.__index = AnatomyHostLayer

local function new<SocketT, TagT>(
	host: AnatomyHostLayerCommands,
	id: LayerId,
	instance: AnatomyInstance<SocketT, TagT>,
	priority: number,
	category: AnatomyCategory?,
	allowSocketOverrides: boolean,
	insertOrder: number
): AnatomyHostLayerOwned<SocketT, TagT>
	local self: AnatomyHostLayerImpl<SocketT, TagT> =
		setmetatable({ id = id }, AnatomyHostLayer) :: AnatomyHostLayerImpl<SocketT, TagT>
	-- Identity is initialized once; public handles expose it read-only.
	self._host = host
	self._instance = instance
	self._priority = priority
	self._category = category
	self._allowSocketOverrides = allowSocketOverrides
	self._insertOrder = insertOrder
	self._destroyed = false
	return self
end
function AnatomyHostLayer.getInstance<SocketT, TagT>(
	self: AnatomyHostLayerImpl<SocketT, TagT>
): AnatomyInstance<SocketT, TagT>
	return self._instance
end
function AnatomyHostLayer.getPriority<SocketT, TagT>(self: AnatomyHostLayerImpl<SocketT, TagT>): number
	return self._priority
end
function AnatomyHostLayer.getRegistration<SocketT, TagT>(self: AnatomyHostLayerImpl<SocketT, TagT>): number
	return self._insertOrder
end
function AnatomyHostLayer.allowsSocketOverrides<SocketT, TagT>(self: AnatomyHostLayerImpl<SocketT, TagT>): boolean
	return self._allowSocketOverrides
end
function AnatomyHostLayer.setPriority<SocketT, TagT>(
	self: AnatomyHostLayerImpl<SocketT, TagT>,
	priority: number
): ()
	assert(not self._destroyed, "Cannot reprioritize a retired anatomy layer")
	self._host:setLayerPriority(self.id, self._insertOrder, priority)
end
function AnatomyHostLayer.applyPriority<SocketT, TagT>(
	self: AnatomyHostLayerImpl<SocketT, TagT>,
	priority: number
): ()
	self._priority = priority
end
function AnatomyHostLayer.remove<SocketT, TagT>(self: AnatomyHostLayerImpl<SocketT, TagT>): ()
	if self._destroyed then
		return
	end
	self._host:removeLayer(self.id, self._insertOrder)
end
function AnatomyHostLayer.deconstruct<SocketT, TagT>(self: AnatomyHostLayerImpl<SocketT, TagT>): ()
	self._destroyed = true
end
return { new = new }
