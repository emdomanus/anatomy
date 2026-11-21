--!strict
--!optimize 2
-- The sockets and tagged elements of one element table: frozen data, built once by
-- `anatomyTemplate.new` and shared by every instance of it. It has no method and no private part.
-- `anatomyInstance.new` reads these four tables, and a consumer may read them too, for example to
-- check each socket's element when it loads an asset.
export type AnatomyTemplate = {
	-- Every socket name, in element-index order.
	read socketNames: { read [number]: string },
	-- Socket name -> the element index that carries it.
	read socketElementIndexByName: { read [string]: number },
	-- Every prefix some tag has, each once: the tag "weapon.blade.main" gives "weapon",
	-- "weapon.blade" and "weapon.blade.main". In the order the element table first shows them.
	read taggedPrefixes: { read [number]: string },
	-- Prefix -> the element indexes tagged under it, ascending, each once.
	read taggedElementIndexesByPrefix: { read [string]: { read [number]: number } },
}

return {}
