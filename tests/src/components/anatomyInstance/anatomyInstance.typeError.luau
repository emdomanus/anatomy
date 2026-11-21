--!strict
--!optimize 2
-- anatomyInstance.new takes an AnatomyTemplate and nothing that only resembles one. The template's
-- four tables are on its public type so that the checker can tell.
local Anatomy = require("../../../../src/shared")

local _fromNothing = Anatomy.anatomyInstance.new({}) -- expect-error: is missing fields
local _fromElements = Anatomy.anatomyInstance.new({ { authoredAttributes = {} } }) -- expect-error: is missing fields
local _fromHost = Anatomy.anatomyInstance.new(Anatomy.anatomyHost.new()) -- expect-error: Expected this to be
