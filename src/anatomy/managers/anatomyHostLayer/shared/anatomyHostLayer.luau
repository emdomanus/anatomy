--!strict
--!optimize 2
--!native

local Types = require(script.Parent.Parent.Parent.Parent.types.managers.anatomyHost)
local AnatomyInstanceTypes = require(script.Parent.Parent.Parent.Parent.types.components.anatomyInstance)

export type AnatomyCategory = Types.AnatomyCategory
export type AnatomyHostImpl<TSocketName, TSurfaceName> = Types.AnatomyHostImpl<TSocketName, TSurfaceName>
export type AnatomyHostLayer<TSocketName, TSurfaceName> = Types.AnatomyHostLayer<TSocketName, TSurfaceName>
export type AnatomyHostLayerImpl<TSocketName, TSurfaceName> = Types.AnatomyHostLayerImpl<TSocketName, TSurfaceName>
export type AnatomyInstance<TSocketName, TSurfaceName> = AnatomyInstanceTypes.AnatomyInstance<TSocketName, TSurfaceName>
export type LayerId = Types.LayerId

local AnatomyHostLayer = {}
AnatomyHostLayer.__index = AnatomyHostLayer

local function sortLayers<TSocketName, TSurfaceName>(
	layerOrder: { AnatomyHostLayerImpl<TSocketName, TSurfaceName> }
): ()
	table.sort(layerOrder, function(left, right)
		if left._priority == right._priority then
			return left._insertOrder < right._insertOrder
		end

		return left._priority < right._priority
	end)
end

local function new<TSocketName, TSurfaceName>(
	host: AnatomyHostImpl<TSocketName, TSurfaceName>,
	id: LayerId,
	instance: AnatomyInstance<TSocketName, TSurfaceName>,
	priority: number,
	category: AnatomyCategory?,
	allowSocketOverrides: boolean,
	insertOrder: number
): AnatomyHostLayerImpl<TSocketName, TSurfaceName>
	local self = setmetatable({} :: AnatomyHostLayerImpl<TSocketName, TSurfaceName>, AnatomyHostLayer)

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

function AnatomyHostLayer.getInstance<TSocketName, TSurfaceName>(
	self: AnatomyHostLayerImpl<TSocketName, TSurfaceName>
): AnatomyInstance<TSocketName, TSurfaceName>
	return self._instance
end

function AnatomyHostLayer.getPriority<TSocketName, TSurfaceName>(
	self: AnatomyHostLayerImpl<TSocketName, TSurfaceName>
): number
	return self._priority
end

function AnatomyHostLayer.setPriority<TSocketName, TSurfaceName>(
	self: AnatomyHostLayerImpl<TSocketName, TSurfaceName>,
	priority: number
): ()
	if self._destroyed or self._priority == priority then
		return
	end

	self._priority = priority
	sortLayers(self._host._layerOrder)
	self._host:_refreshAllSockets()
	self._host:_refreshAllSurfaces()
end

function AnatomyHostLayer.remove<TSocketName, TSurfaceName>(self: AnatomyHostLayerImpl<TSocketName, TSurfaceName>): ()
	if self._destroyed then
		return
	end

	self._host:remove(self.id)
end

return {
	new = new,
}
