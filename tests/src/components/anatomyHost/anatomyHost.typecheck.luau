--!strict
--!optimize 2
-- The host's three views and what passes as a source: an instance, and a host under any of its
-- views. Every result and every callback argument is an element index with its instance.
local Anatomy = require("../../../../src/shared")

type AnatomyHost = Anatomy.AnatomyHost
type AnatomyHostOwned = Anatomy.AnatomyHostOwned
type AnatomyInstance = Anatomy.AnatomyInstance
type AnatomySource = Anatomy.AnatomySource

local anatomyTemplate =
	Anatomy.anatomyTemplate.new({ { authoredAttributes = {} } }, "RigSocket", "RigSurface")
local anatomyInstance: AnatomyInstance = Anatomy.anatomyInstance.new(anatomyTemplate)

local owned: AnatomyHostOwned = Anatomy.anatomyHost.new()
-- The owner hands a consumer the reader view of the same object, and a host its source view.
local reader: AnatomyHost = owned
local source: AnatomySource = reader

owned:push(anatomyInstance, 0)
local child: AnatomyHostOwned = Anatomy.anatomyHost.new()
owned:push(child, 5)
owned:setPriority(source, 5)
owned:remove(reader)

local socketElementIndex: number?, socketInstance: AnatomySource? = reader:getSocket("body.head")
local topElementIndex: number?, topInstance: AnatomySource? = reader:getTopTagged("skin")
local elementIndexes: { number } = {}
local anatomyInstances: { AnatomySource } = {}
reader:getTagged("skin", elementIndexes, anatomyInstances)

-- The instance a query returns is a key for the caller's own map.
local nameByInstance: { [AnatomySource]: string } = { [anatomyInstance] = "body" }
local _name: string? = if socketInstance ~= nil then nameByInstance[socketInstance] else nil
local _sum: number = (socketElementIndex or 0) + (topElementIndex or 0)
local _isBody: boolean = topInstance == anatomyInstance

-- The callbacks' parameters are inferred.
local releaseSocket: () -> () = reader:onSocketChanged("body.head", function(elementIndex, instance)
	local _elementIndex: number? = elementIndex
	local _instance: AnatomySource? = instance
end, true)
local releaseTopTagged: () -> () = reader:onTopTaggedChanged(
	"skin",
	function(elementIndex, instance)
		local _elementIndex: number? = elementIndex
		local _instance: AnatomySource? = instance
	end
)
local releaseAmongOthers: () -> () = reader:onSocketAmongOthersChanged(
	"body.head",
	anatomyInstance,
	function(elementIndex, instance)
		local _elementIndex: number? = elementIndex
		local _instance: AnatomySource? = instance
	end,
	true
)
releaseSocket()
releaseTopTagged()
releaseAmongOthers()

local _contains: boolean = source:containsSource(anatomyInstance)
local _socketNames: { read [number]: string } = source.socketNames
owned:deconstruct()
