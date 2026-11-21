--!strict
--!optimize 2
-- One element of an asset, as the asset's owner indexes it. An element table is an array of these,
-- `elements[elementIndex]`. Anatomy declares this shape and whoever owns the asset supplies it.
-- Anatomy reads this one field and nothing else about an element.
export type AnatomyElement = {
	read authoredAttributes: { read [string]: unknown },
}

return {}
