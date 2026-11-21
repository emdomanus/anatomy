--!strict
--!optimize 2
-- anatomyInstance through the package entry: two instances of one template answer alike and differ
-- only as tables, and the capability's answers for an instance, which never changes.
local Anatomy = require("../../../../src/shared")

type AnatomyElement = Anatomy.AnatomyElement
type AnatomySource = Anatomy.AnatomySource

local function case(name: string, body: () -> ()): ()
	body()
	print("PASS " .. name)
end

local ELEMENTS: { AnatomyElement } = {
	{ authoredAttributes = {} },
	{ authoredAttributes = { Socket = "body.head", Tags = "skin;body.head" } },
	{ authoredAttributes = { Socket = "body.hand", Tags = "skin" } },
}

case("two instances of one template return the same element indexes and themselves", function()
	local anatomyTemplate = Anatomy.anatomyTemplate.new(ELEMENTS, "Socket", "Tags")
	local first = Anatomy.anatomyInstance.new(anatomyTemplate)
	local second = Anatomy.anatomyInstance.new(anatomyTemplate)
	assert(first ~= second, "each call returns a new instance")
	assert(table.isfrozen(first), "an instance is frozen")
	-- The capability's two lists are the template's own tables, shared by every instance.
	assert(
		first.socketNames == anatomyTemplate.socketNames and second.socketNames == first.socketNames,
		"socketNames"
	)
	assert(first.taggedPrefixes == anatomyTemplate.taggedPrefixes, "taggedPrefixes")

	for _, anatomyInstance in { first, second } do
		local socketElementIndex, socketInstance = anatomyInstance:getSocket("body.hand")
		assert(socketElementIndex == 3 and socketInstance == anatomyInstance, "getSocket")
		-- The top element is the last one under the prefix in element-index order.
		local topElementIndex, topInstance = anatomyInstance:getTopTagged("skin")
		assert(topElementIndex == 3 and topInstance == anatomyInstance, "getTopTagged")
		local missingElementIndex, missingInstance = anatomyInstance:getSocket("body.foot")
		assert(
			missingElementIndex == nil and missingInstance == nil,
			"an unknown socket is nil, nil"
		)
		local missingTopElementIndex, missingTopInstance = anatomyInstance:getTopTagged("armor")
		assert(
			missingTopElementIndex == nil and missingTopInstance == nil,
			"an unknown prefix is nil, nil"
		)
	end
end)

case("getTagged appends each element index with the instance at the same position", function()
	local anatomyInstance =
		Anatomy.anatomyInstance.new(Anatomy.anatomyTemplate.new(ELEMENTS, "Socket", "Tags"))
	local elementIndexes: { number } = { 99 }
	local anatomyInstances: { AnatomySource } = { anatomyInstance }
	anatomyInstance:getTagged("skin", elementIndexes, anatomyInstances)
	anatomyInstance:getTagged("armor", elementIndexes, anatomyInstances)
	assert(
		table.concat(elementIndexes, ",") == "99,2,3",
		"appended after what was there, in element-index order"
	)
	assert(#anatomyInstances == 3, "one instance per element index")
	assert(
		anatomyInstances[2] == anatomyInstance and anatomyInstances[3] == anatomyInstance,
		"the instance itself"
	)
end)

case(
	"an instance never changes: its subscriptions keep nothing, and it contains only itself",
	function()
		local anatomyTemplate = Anatomy.anatomyTemplate.new(ELEMENTS, "Socket", "Tags")
		local anatomyInstance = Anatomy.anatomyInstance.new(anatomyTemplate)
		local other = Anatomy.anatomyInstance.new(anatomyTemplate)
		local called = false
		local function callback(): ()
			called = true
		end
		local releaseSocket = anatomyInstance:onAnySocketChanged(callback)
		local releaseTagged = anatomyInstance:onAnyTopTaggedChanged(callback)
		releaseSocket()
		releaseSocket()
		releaseTagged()
		assert(not called, "the callback is never called")
		assert(anatomyInstance:containsSource(anatomyInstance), "itself")
		assert(not anatomyInstance:containsSource(other), "not another instance of its template")
	end
)
