--!strict
--!optimize 2

local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)

type LayerId = AnatomyTypes.LayerId
export type AnatomyHostLayerCommands = {
	read setLayerPriority: (
		self: AnatomyHostLayerCommands,
		layerId: LayerId,
		registration: number,
		priority: number
	) -> (),
	read removeLayer: (
		self: AnatomyHostLayerCommands,
		layerId: LayerId,
		registration: number
	) -> (),
}
return {}
