--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Parent.Parent.types.managers.anatomyHost)
local AnatomyInstanceTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyInstance)
local AnatomyTemplateTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate)

export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyHostImpl<SocketT, TagT> = Types.AnatomyHostImpl<SocketT, TagT>
export type AnatomyHostLayer<SocketT, TagT> = Types.AnatomyHostLayer<SocketT, TagT>
export type AnatomyHostLayerImpl<SocketT, TagT> = Types.AnatomyHostLayerImpl<SocketT, TagT>
export type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
export type LayerId = Types.LayerId

local AnatomyHostLayer = {}
AnatomyHostLayer.__index = AnatomyHostLayer

local function sortLayers<SocketT, TagT>(
	layerOrder: { AnatomyHostLayerImpl<SocketT, TagT> }
): ()
	table.sort(layerOrder, function(left, right)
		if left._priority == right._priority then
			return left._insertOrder < right._insertOrder
		end

		return left._priority < right._priority
	end)
end

local function new<SocketT, TagT>(
	host: AnatomyHostImpl<SocketT, TagT>,
	id: LayerId,
	instance: AnatomyInstance<SocketT, TagT>,
	priority: number,
	category: AnatomyCategory?,
	allowSocketOverrides: boolean,
	insertOrder: number
): AnatomyHostLayerImpl<SocketT, TagT>
	local self = setmetatable({} :: AnatomyHostLayerImpl<SocketT, TagT>, AnatomyHostLayer)

	self.id = id
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

function AnatomyHostLayer.getPriority<SocketT, TagT>(
	self: AnatomyHostLayerImpl<SocketT, TagT>
): number
	return self._priority
end

function AnatomyHostLayer.setPriority<SocketT, TagT>(
	self: AnatomyHostLayerImpl<SocketT, TagT>,
	priority: number
): ()
	if self._destroyed or self._priority == priority then
		return
	end

	self._priority = priority
	sortLayers(self._host._layerOrder)
	self._host:_refreshAllSockets()
	self._host:_refreshAllWatchedPrefixes()
end

function AnatomyHostLayer.remove<SocketT, TagT>(self: AnatomyHostLayerImpl<SocketT, TagT>): ()
	if self._destroyed then
		return
	end

	self._host:remove(self.id)
end

return {
	new = new,
}
