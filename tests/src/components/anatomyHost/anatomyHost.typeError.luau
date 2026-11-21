--!strict
--!optimize 2
-- The reader view cannot change or end the host, a template is not a source, and a callback
-- receives an element index, not an engine object.
local Anatomy = require("../../../../src/shared")

type AnatomyHost = Anatomy.AnatomyHost

local anatomyTemplate =
	Anatomy.anatomyTemplate.new({ { authoredAttributes = {} } }, "RigSocket", "RigSurface")
local anatomyInstance = Anatomy.anatomyInstance.new(anatomyTemplate)
local owned = Anatomy.anatomyHost.new()
local reader: AnatomyHost = owned

reader:push(anatomyInstance, 0) -- expect-error: does not have key 'push'
reader:deconstruct() -- expect-error: does not have key 'deconstruct'
owned:push(anatomyTemplate, 0) -- expect-error: Expected this to be
owned:push(anatomyInstance) -- expect-error: Argument count mismatch
reader:onSocketChanged("body.head", function(_attachment: string): () end) -- expect-error: Expected this to be
reader:onSocketAmongOthersChanged("body.head", function(): () end) -- expect-error: Argument count mismatch
