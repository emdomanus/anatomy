--!strict
--!optimize 2
local AnatomySourceTypes = require("../../../def/anatomy/anatomySource/public")

-- One clone's identity inside Anatomy. It is the capability and nothing more: no setter, no
-- subscription that ever fires and no teardown. Two instances of one template answer every query
-- with the same element indexes and differ only in being two tables, which is what a query returns
-- beside an element index. Whoever holds the clone keeps the map from the instance to the clone.
export type AnatomyInstance = AnatomySourceTypes.AnatomySource

return {}
