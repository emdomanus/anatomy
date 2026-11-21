--!strict
--!optimize 2
local AnatomyInstanceTypes = require("./public")

type AnatomyInstance = AnatomyInstanceTypes.AnatomyInstance

-- The instance's own table, frozen by `new`. Its four fields are its template's four tables:
-- `socketNames` and `taggedPrefixes` are the capability's two fields, and the two maps answer
-- `getSocket`, `getTopTagged` and `getTagged`.
export type AnatomyInstanceImpl = AnatomyInstance & {
	read _socketElementIndexByName: { read [string]: number },
	read _taggedElementIndexesByPrefix: { read [string]: { read [number]: number } },
}

return {}
