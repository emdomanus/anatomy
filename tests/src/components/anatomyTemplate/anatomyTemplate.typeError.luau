--!strict
--!optimize 2
-- anatomyTemplate.new rejects a table whose elements lack `authoredAttributes`, and a template's
-- tables cannot be written through its type.
local Anatomy = require("../../../../src/shared")

local _noAttributes =
	Anatomy.anatomyTemplate.new({ { className = "Model" } }, "RigSocket", "RigSurface") -- expect-error: is missing field 'authoredAttributes'
local _noNames = Anatomy.anatomyTemplate.new({ { authoredAttributes = {} } }) -- expect-error: Argument count mismatch

local anatomyTemplate =
	Anatomy.anatomyTemplate.new({ { authoredAttributes = {} } }, "RigSocket", "RigSurface")
anatomyTemplate.socketNames = {} -- expect-error: is read-only
anatomyTemplate.socketElementIndexByName["body.head"] = 1 -- expect-error: is read-only
