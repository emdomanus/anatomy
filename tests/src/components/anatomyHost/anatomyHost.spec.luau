--!strict
--!optimize 2
-- anatomyHost through the package entry: precedence, a host inside a host and the refusal of a
-- cycle, what a query returns when a callback runs, what a callback that changes the composition or
-- raises leaves behind, the subscription rules, the socket among the other sources, deconstruct, and
-- what the per-frame and per-change paths allocate.
local Anatomy = require("../../../../src/shared")

type AnatomyElement = Anatomy.AnatomyElement
type AnatomyHostOwned = Anatomy.AnatomyHostOwned
type AnatomyInstance = Anatomy.AnatomyInstance
type AnatomySource = Anatomy.AnatomySource

local function case(name: string, body: () -> ()): ()
	body()
	print("PASS " .. name)
end

-- The name each instance was made under, so a result reads "helm:1": instance name, element index.
local names: { [AnatomySource]: string } = {}

-- An instance over an element table that has `sockets[elementIndex]` as element elementIndex's
-- socket name and `tags[elementIndex]` as its tag list.
local function newInstance(
	name: string,
	sockets: { [number]: string },
	tags: { [number]: string }?
): AnatomyInstance
	local count = 0
	for elementIndex in sockets do
		count = math.max(count, elementIndex)
	end
	if tags ~= nil then
		for elementIndex in tags do
			count = math.max(count, elementIndex)
		end
	end
	local elements: { AnatomyElement } = {}
	for elementIndex = 1, count do
		elements[elementIndex] = {
			authoredAttributes = {
				Socket = sockets[elementIndex],
				Tags = if tags ~= nil then tags[elementIndex] else nil,
			},
		}
	end
	local anatomyInstance =
		Anatomy.anatomyInstance.new(Anatomy.anatomyTemplate.new(elements, "Socket", "Tags"))
	names[anatomyInstance] = name
	return anatomyInstance
end

local function describe(elementIndex: number?, anatomyInstance: AnatomySource?): string
	if elementIndex == nil or anatomyInstance == nil then
		assert(elementIndex == nil and anatomyInstance == nil, "one result came without the other")
		return "nil"
	end
	return names[anatomyInstance] .. ":" .. elementIndex
end

local function expectSocket(anatomySource: AnatomySource, socketName: string, expected: string): ()
	local actual = describe(anatomySource:getSocket(socketName))
	assert(actual == expected, `getSocket("{socketName}") expected {expected}, got {actual}`)
end

local function expectTopTagged(anatomySource: AnatomySource, prefix: string, expected: string): ()
	local actual = describe(anatomySource:getTopTagged(prefix))
	assert(actual == expected, `getTopTagged("{prefix}") expected {expected}, got {actual}`)
end

-- A record of calls, compared as one string and emptied.
local function expectLog(log: { string }, expected: string): ()
	local actual = table.concat(log, ",")
	assert(actual == expected, `expected the calls\n  {expected}\ngot\n  {actual}`)
	table.clear(log)
end

-- A subscriber that records "label=instance:elementIndex".
local function logger(
	log: { string },
	label: string
): (elementIndex: number?, anatomyInstance: AnatomySource?) -> ()
	return function(elementIndex: number?, anatomyInstance: AnatomySource?): ()
		table.insert(log, label .. "=" .. describe(elementIndex, anatomyInstance))
	end
end

local function expectRaise(body: () -> (), fragment: string): ()
	local ok, failure = pcall(function(): unknown
		body()
		return nil
	end)
	assert(not ok, `expected a failure containing "{fragment}", but the call returned`)
	assert(
		string.find(tostring(failure), fragment, 1, true) ~= nil,
		`expected a failure containing "{fragment}", got: {tostring(failure)}`
	)
end

case(
	"the higher priority supplies a socket; among equals the later push; setPriority counts as a push",
	function()
		local host = Anatomy.anatomyHost.new()
		local body = newInstance("body", { [2] = "body.head" })
		local helm = newInstance("helm", { [1] = "body.head" })
		local hat = newInstance("hat", { [3] = "body.head" })
		local sock = newInstance("sock", { [1] = "body.head" })

		expectSocket(host, "body.head", "nil")
		host:push(body, 0)
		expectSocket(host, "body.head", "body:2")
		host:push(sock, -5)
		expectSocket(host, "body.head", "body:2")
		host:push(helm, 10)
		expectSocket(host, "body.head", "helm:1")
		host:push(hat, 10)
		expectSocket(host, "body.head", "hat:3")

		-- An unchanged priority does nothing: helm stays below hat.
		host:setPriority(helm, 10)
		expectSocket(host, "body.head", "hat:3")
		host:setPriority(helm, 20)
		expectSocket(host, "body.head", "helm:1")
		-- hat arrives at 20 after helm did, so it is above helm.
		host:setPriority(hat, 20)
		expectSocket(host, "body.head", "hat:3")
		host:setPriority(helm, 5)
		host:setPriority(helm, 20)
		expectSocket(host, "body.head", "helm:1")

		host:remove(helm)
		expectSocket(host, "body.head", "hat:3")
		host:remove(hat)
		expectSocket(host, "body.head", "body:2")
		host:remove(hat)
		expectSocket(host, "body.head", "body:2")
		host:remove(body)
		expectSocket(host, "body.head", "sock:1")
		host:remove(sock)
		expectSocket(host, "body.head", "nil")

		expectRaise(function()
			host:setPriority(body, 1)
		end, "not pushed")
		host:push(body, 0)
		expectRaise(function()
			host:push(body, 5)
		end, "already pushed")
		expectSocket(host, "body.head", "body:2")
	end
)

case(
	"an instance is pushed, removed and pushed to another host; a source can be in two hosts at once",
	function()
		local first = Anatomy.anatomyHost.new()
		local second = Anatomy.anatomyHost.new()
		local sword = newInstance("sword", { [4] = "weapon.tip" })

		first:push(sword, 0)
		expectSocket(first, "weapon.tip", "sword:4")
		first:remove(sword)
		expectSocket(first, "weapon.tip", "nil")
		second:push(sword, 3)
		expectSocket(second, "weapon.tip", "sword:4")
		expectSocket(first, "weapon.tip", "nil")
		second:remove(sword)
		first:push(sword, 1)
		expectSocket(first, "weapon.tip", "sword:4")

		-- In both at once, an instance and then a host.
		second:push(sword, 0)
		expectSocket(second, "weapon.tip", "sword:4")
		first:remove(sword)
		expectSocket(first, "weapon.tip", "nil")
		expectSocket(second, "weapon.tip", "sword:4")

		local group = Anatomy.anatomyHost.new()
		local log: { string } = {}
		first:onSocketChanged("weapon.grip", logger(log, "first"))
		second:onSocketChanged("weapon.grip", logger(log, "second"))
		first:push(group, 0)
		second:push(group, 0)
		local dagger = newInstance("dagger", { [1] = "weapon.grip" })
		group:push(dagger, 0)
		expectLog(log, "first=dagger:1,second=dagger:1")
	end
)

case("a host pushed into a host is one source, at the priority its parent gave it", function()
	local entity = Anatomy.anatomyHost.new()
	local gear = Anatomy.anatomyHost.new()
	local body = newInstance("body", { [2] = "body.head" })
	local helm = newInstance("helm", { [1] = "body.head" })

	entity:push(body, 0)
	gear:push(helm, 100)
	entity:push(gear, -5)
	-- helm's 100 is its priority inside gear. gear itself is at -5 in entity, below body.
	expectSocket(gear, "body.head", "helm:1")
	expectSocket(entity, "body.head", "body:2")
	entity:setPriority(gear, 5)
	expectSocket(entity, "body.head", "helm:1")
end)

case(
	"containsSource follows pushed sources, and push refuses a cycle before anything changes",
	function()
		local top = Anatomy.anatomyHost.new()
		local middle = Anatomy.anatomyHost.new()
		local bottom = Anatomy.anatomyHost.new()
		local sword = newInstance("sword", { [1] = "weapon.tip" })
		local shield = newInstance("shield", { [1] = "weapon.tip" })

		assert(sword:containsSource(sword), "an instance contains itself")
		assert(not sword:containsSource(shield), "an instance contains no other source")
		assert(top:containsSource(top), "a host contains itself")

		top:push(middle, 0)
		middle:push(bottom, 0)
		bottom:push(sword, 0)
		assert(
			top:containsSource(middle) and top:containsSource(bottom) and top:containsSource(sword),
			"reachable below"
		)
		assert(
			not bottom:containsSource(top) and not middle:containsSource(top),
			"not reachable upward"
		)
		assert(not top:containsSource(shield), "a source pushed nowhere is not contained")

		local log: { string } = {}
		bottom:onSocketChanged("weapon.tip", logger(log, "bottom"))
		expectRaise(function()
			top:push(top, 0)
		end, "contains it")
		expectRaise(function()
			middle:push(top, 0)
		end, "contains it")
		expectRaise(function()
			bottom:push(top, 9)
		end, "contains it")
		-- The refused pushes changed nothing and reported nothing.
		expectSocket(top, "weapon.tip", "sword:1")
		expectLog(log, "")
		assert(not bottom:containsSource(top), "a refused push left nothing behind")

		-- Once the link is gone the same push is accepted.
		top:remove(middle)
		bottom:push(top, 9)
		assert(bottom:containsSource(top), "pushed after the cycle was removed")
	end
)

case("every query on the host is already correct when the first callback of a push runs", function()
	local host = Anatomy.anatomyHost.new()
	local pair = newInstance("pair", { [1] = "first", [2] = "second" }, { [2] = "mark" })
	local seen: { string } = {}
	host:onSocketChanged("first", function(): ()
		table.insert(seen, describe(host:getSocket("second")))
		table.insert(seen, describe(host:getTopTagged("mark")))
	end)
	host:push(pair, 0)
	expectLog(seen, "pair:2,pair:2")
	host:onSocketChanged("first", function(): ()
		table.insert(seen, describe(host:getSocket("second")))
	end)
	host:remove(pair)
	expectLog(seen, "nil,nil,nil")
end)

case("a nested host reports a changed winner to its parent, and remove ends that", function()
	local top = Anatomy.anatomyHost.new()
	local middle = Anatomy.anatomyHost.new()
	local bottom = Anatomy.anatomyHost.new()
	local body = newInstance("body", { [3] = "weapon.tip" }, { [3] = "weapon.blade" })
	local sword = newInstance("sword", { [1] = "weapon.tip" }, { [2] = "weapon.blade" })
	local log: { string } = {}

	top:push(body, -1)
	top:push(middle, 0)
	middle:push(bottom, 0)
	top:onSocketChanged("weapon.tip", logger(log, "socket"))
	top:onTopTaggedChanged("weapon", logger(log, "tagged"))

	bottom:push(sword, 0)
	expectSocket(top, "weapon.tip", "sword:1")
	expectTopTagged(top, "weapon.blade", "sword:2")
	expectLog(log, "socket=sword:1,tagged=sword:2")

	bottom:remove(sword)
	expectLog(log, "socket=body:3,tagged=body:3")

	-- A change below that does not change the parent's own winner is not reported.
	top:setPriority(body, 5)
	bottom:push(sword, 0)
	expectSocket(middle, "weapon.tip", "sword:1")
	expectSocket(top, "weapon.tip", "body:3")
	expectLog(log, "")
	top:setPriority(body, -1)
	expectLog(log, "socket=sword:1,tagged=sword:2")

	-- After remove the parent no longer hears the child.
	top:remove(middle)
	expectLog(log, "socket=body:3,tagged=body:3")
	bottom:remove(sword)
	bottom:push(sword, 0)
	expectSocket(top, "weapon.tip", "body:3")
	expectLog(log, "")
end)

case("a parent learns the names of one push into a child one at a time", function()
	local parent = Anatomy.anatomyHost.new()
	local child = Anatomy.anatomyHost.new()
	local pair = newInstance("pair", { [1] = "first", [2] = "second" })
	local seen: { string } = {}
	parent:push(child, 0)
	parent:onSocketChanged("first", function(): ()
		table.insert(seen, "child " .. describe(child:getSocket("second")))
		table.insert(seen, "parent " .. describe(parent:getSocket("second")))
	end)
	child:push(pair, 0)
	expectLog(seen, "child pair:2,parent nil")
	expectSocket(parent, "second", "pair:2")
end)

case(
	"a callback that changes the composition: every subscriber's last call carries the current winner",
	function()
		local host = Anatomy.anatomyHost.new()
		local body = newInstance("body", { [2] = "body.head" })
		local helm = newInstance("helm", { [1] = "body.head" })
		local log: { string } = {}
		host:push(body, 0)

		local logFirst = logger(log, "a")
		host:onSocketChanged(
			"body.head",
			function(elementIndex: number?, anatomyInstance: AnatomySource?): ()
				logFirst(elementIndex, anatomyInstance)
				if anatomyInstance == helm then
					host:remove(helm)
				end
			end
		)
		host:onSocketChanged("body.head", logger(log, "b"))
		host:onSocketChanged("body.head", logger(log, "c"))

		host:push(helm, 10)
		-- a is told helm and removes it. That remove reports body to a, b and c. The push's fire then
		-- still calls b and c with helm, and the host fires body again.
		expectLog(
			log,
			"a=helm:1,a=body:2,b=body:2,c=body:2,b=helm:1,c=helm:1,a=body:2,b=body:2,c=body:2"
		)
		expectSocket(host, "body.head", "body:2")
	end
)

case(
	"a callback that raises: the queries are correct and the names not reached are reported later",
	function()
		local host = Anatomy.anatomyHost.new()
		local pair = newInstance("pair", { [1] = "first", [2] = "second" })
		local other = newInstance("other", { [1] = "second" })
		local log: { string } = {}
		local raising = true
		local logRaiser = logger(log, "raiser")
		host:onSocketChanged(
			"first",
			function(elementIndex: number?, anatomyInstance: AnatomySource?): ()
				logRaiser(elementIndex, anatomyInstance)
				if raising then
					error("intentional failure")
				end
			end
		)
		host:onSocketChanged("first", logger(log, "afterRaiser"))
		host:onSocketChanged("second", logger(log, "second"))

		expectRaise(function()
			host:push(pair, 0)
		end, "intentional failure")
		expectLog(log, "raiser=pair:1")
		expectSocket(host, "first", "pair:1")
		expectSocket(host, "second", "pair:2")

		-- "second" was not reached. The next operation that involves it reports it, though its winner
		-- does not change in that operation.
		raising = false
		host:push(other, -1)
		expectLog(log, "second=pair:2")

		-- "first" was being reported when the callback raised: the subscriber after the raiser is called
		-- again when that name's winner next changes.
		host:remove(pair)
		expectLog(log, "raiser=nil,afterRaiser=nil,second=other:1")
	end
)

case("initially: the callback is added, then called once with the current results", function()
	local host = Anatomy.anatomyHost.new()
	local body = newInstance("body", { [2] = "body.head" }, { [2] = "body" })
	local helm = newInstance("helm", { [1] = "body.head" })
	local log: { string } = {}

	host:onSocketChanged("body.head", logger(log, "quiet"))
	host:onSocketChanged("body.head", logger(log, "empty"), true)
	expectLog(log, "empty=nil")
	host:push(body, 0)
	expectLog(log, "quiet=body:2,empty=body:2")
	host:onSocketChanged("body.head", logger(log, "socket"), true)
	host:onTopTaggedChanged("body", logger(log, "tagged"), true)
	expectLog(log, "socket=body:2,tagged=body:2")

	-- Added before its first call: a change it makes inside that call reaches it.
	local pushed = false
	local logPusher = logger(log, "pusher")
	host:onSocketChanged(
		"body.head",
		function(elementIndex: number?, anatomyInstance: AnatomySource?): ()
			logPusher(elementIndex, anatomyInstance)
			if not pushed then
				pushed = true
				host:push(helm, 10)
			end
		end,
		true
	)
	expectLog(log, "pusher=body:2,quiet=helm:1,empty=helm:1,socket=helm:1,pusher=helm:1")

	-- An initial call that raises leaves the subscription in place.
	local raising = true
	local logRaiser = logger(log, "raiser")
	expectRaise(function()
		host:onSocketChanged(
			"body.head",
			function(elementIndex: number?, anatomyInstance: AnatomySource?): ()
				logRaiser(elementIndex, anatomyInstance)
				if raising then
					error("intentional failure")
				end
			end,
			true
		)
	end, "intentional failure")
	raising = false
	table.clear(log)
	host:remove(helm)
	expectLog(log, "quiet=body:2,empty=body:2,socket=body:2,pusher=body:2,raiser=body:2")
end)

case(
	"one function subscribed twice is two entries; releases and additions during a report",
	function()
		local host = Anatomy.anatomyHost.new()
		local body = newInstance("body", { [2] = "body.head" })
		local helm = newInstance("helm", { [1] = "body.head" })
		local log: { string } = {}

		local twice = logger(log, "twice")
		local releaseFirst = host:onSocketChanged("body.head", twice)
		local releaseSecond = host:onSocketChanged("body.head", twice)
		host:push(body, 0)
		expectLog(log, "twice=body:2,twice=body:2")
		releaseFirst()
		host:push(helm, 10)
		expectLog(log, "twice=helm:1")
		-- A release called twice does nothing, and leaves the other entry of the same function.
		releaseFirst()
		host:remove(helm)
		expectLog(log, "twice=body:2")
		releaseSecond()
		host:push(helm, 10)
		expectLog(log, "")

		-- A subscriber released during a report, before its turn, is not called. One added during a
		-- report waits for the next.
		local releaseLate: () -> ()
		local added = false
		local logEarly = logger(log, "early")
		host:onSocketChanged(
			"body.head",
			function(elementIndex: number?, anatomyInstance: AnatomySource?): ()
				logEarly(elementIndex, anatomyInstance)
				releaseLate()
				if not added then
					added = true
					host:onSocketChanged("body.head", logger(log, "added"))
				end
			end
		)
		host:onSocketChanged("body.head", logger(log, "middle"))
		releaseLate = host:onSocketChanged("body.head", logger(log, "late"))
		host:remove(helm)
		expectLog(log, "early=body:2,middle=body:2")
		host:push(helm, 10)
		expectLog(log, "early=helm:1,middle=helm:1,added=helm:1")
	end
)

case("a name's subscribers can all leave and a later subscriber is still reported to", function()
	local host = Anatomy.anatomyHost.new()
	local body = newInstance("body", { [2] = "body.head" }, { [2] = "body" })
	local log: { string } = {}
	host:onSocketChanged("body.head", logger(log, "gone"))()
	host:onTopTaggedChanged("body", logger(log, "gone"))()
	host:onSocketChanged("body.head", logger(log, "socket"))
	host:onTopTaggedChanged("body", logger(log, "tagged"))
	host:push(body, 0)
	expectLog(log, "socket=body:2,tagged=body:2")
end)

case(
	"tagged queries return element indexes with their instances, lowest precedence first",
	function()
		local host = Anatomy.anatomyHost.new()
		local group = Anatomy.anatomyHost.new()
		local body = newInstance(
			"body",
			{},
			{ [2] = "body.arm.left;skin", [3] = "body.arm.right;skin" }
		)
		local ears = newInstance("ears", {}, { [1] = "skin" })
		local tail = newInstance("tail", {}, { [4] = "skin" })
		local elementIndexes: { number } = {}
		local anatomyInstances: { AnatomySource } = {}
		local function expectTagged(prefix: string, expected: string): ()
			table.clear(elementIndexes)
			table.clear(anatomyInstances)
			host:getTagged(prefix, elementIndexes, anatomyInstances)
			assert(#elementIndexes == #anatomyInstances, "the two arrays differ in length")
			local pairs: { string } = {}
			for position, elementIndex in elementIndexes do
				pairs[position] = describe(elementIndex, anatomyInstances[position])
			end
			local actual = table.concat(pairs, ",")
			assert(actual == expected, `getTagged("{prefix}") expected {expected}, got {actual}`)
		end

		host:push(body, 0)
		host:push(group, 5)
		group:push(ears, 0)
		host:push(tail, 5)
		expectTagged("skin", "body:2,body:3,ears:1,tail:4")
		-- The last pair is what getTopTagged returns.
		expectTopTagged(host, "skin", "tail:4")
		expectTagged("body.arm", "body:2,body:3")
		expectTagged("body", "body:2,body:3")
		expectTopTagged(host, "body.arm", "body:3")
		expectTagged("body.arm.left", "body:2")
		expectTagged("nothing", "")
		expectTopTagged(host, "nothing", "nil")
		-- A prefix is whole segments: "body.ar" is not a prefix of "body.arm".
		expectTagged("body.ar", "")

		-- getTagged appends: it does not empty what it is given.
		host:getTagged("body.arm.left", elementIndexes, anatomyInstances)
		assert(
			#elementIndexes == 1 and #anatomyInstances == 1,
			"appended to the empty arrays of the last query"
		)
		host:getTagged("body.arm.left", elementIndexes, anatomyInstances)
		assert(#elementIndexes == 2 and #anatomyInstances == 2, "appended after what was there")

		local log: { string } = {}
		host:onTopTaggedChanged("skin", logger(log, "top"))
		host:remove(tail)
		expectLog(log, "top=ears:1")
		group:remove(ears)
		expectLog(log, "top=body:3")
		-- body's top element under "skin" does not change when a lower source is added.
		host:push(tail, -1)
		expectLog(log, "")
		expectTagged("skin", "tail:4,body:2,body:3")
	end
)

case("onSocketAmongOthersChanged: the winner among the sources other than one", function()
	local host = Anatomy.anatomyHost.new()
	local body = newInstance("body", { [5] = "hand" })
	local glove = newInstance("glove", { [2] = "hand" })
	local sword = newInstance("sword", { [1] = "hand" })
	local log: { string } = {}
	host:push(body, 0)
	host:push(glove, 5)
	host:push(sword, 10)

	host:onSocketChanged("hand", logger(log, "all"))
	host:onSocketAmongOthersChanged("hand", sword, logger(log, "quiet"))
	expectLog(log, "")
	local release = host:onSocketAmongOthersChanged("hand", sword, logger(log, "others"), true)
	expectLog(log, "others=glove:2")

	-- The winner among the others changes while the overall winner, sword, does not.
	host:remove(glove)
	expectSocket(host, "hand", "sword:1")
	expectLog(log, "quiet=body:5,others=body:5")
	-- A change that leaves the winner among the others alone is not reported to them.
	host:setPriority(sword, 20)
	expectLog(log, "")
	host:remove(sword)
	expectLog(log, "all=body:5")
	host:remove(body)
	expectLog(log, "all=nil,quiet=nil,others=nil")
	release()
	release()
	host:push(body, 0)
	expectLog(log, "all=body:5,quiet=body:5")
end)

case(
	"excluded names a source that is not pushed: nothing is excluded, and it is no error",
	function()
		local host = Anatomy.anatomyHost.new()
		local group = Anatomy.anatomyHost.new()
		local body = newInstance("body", { [5] = "hand" })
		local sword = newInstance("sword", { [1] = "hand" })
		local log: { string } = {}
		host:push(body, 0)

		-- Subscribed before sword is pushed: it sees every source, and sword is skipped once pushed.
		host:onSocketAmongOthersChanged("hand", sword, logger(log, "others"), true)
		expectLog(log, "others=body:5")
		host:push(sword, 10)
		expectSocket(host, "hand", "sword:1")
		expectLog(log, "")
		host:remove(sword)
		expectLog(log, "")

		-- sword inside a pushed host is not a source pushed directly to this host, so it is not
		-- excluded.
		group:push(sword, 0)
		host:push(group, 10)
		expectLog(log, "others=sword:1")
		host:remove(group)
		expectLog(log, "others=body:5")

		-- A source pushed to no host at all.
		local never = newInstance("never", { [1] = "hand" })
		host:onSocketAmongOthersChanged("hand", never, logger(log, "never"), true)
		expectLog(log, "never=body:5")
	end
)

case("deconstruct tells every subscriber and parent nil once, and ends the host", function()
	local parent = Anatomy.anatomyHost.new()
	local host = Anatomy.anatomyHost.new()
	local body = newInstance("body", { [2] = "body.head" }, { [2] = "body" })
	local helm = newInstance("helm", { [1] = "body.head" })
	local log: { string } = {}
	parent:push(host, 0)
	host:push(body, 0)
	host:push(helm, 10)
	local release = host:onSocketChanged("body.head", logger(log, "socket"))
	host:onTopTaggedChanged("body", logger(log, "tagged"))
	host:onSocketAmongOthersChanged("body.head", helm, logger(log, "others"))
	parent:onSocketChanged("body.head", logger(log, "parent"))

	host:deconstruct()
	-- One report of nil per name: body is never reported as the fallback on the way down.
	expectLog(log, "parent=nil,socket=nil,others=nil,tagged=nil")

	expectSocket(host, "body.head", "nil")
	expectTopTagged(host, "body", "nil")
	local elementIndexes: { number } = {}
	local anatomyInstances: { AnatomySource } = {}
	host:getTagged("body", elementIndexes, anatomyInstances)
	assert(#elementIndexes == 0 and #anatomyInstances == 0, "a deconstructed host appends nothing")
	assert(not host:containsSource(body), "a deconstructed host has no sources")

	expectRaise(function()
		host:push(body, 0)
	end, "deconstructed")
	expectRaise(function()
		host:onSocketChanged("body.head", logger(log, "late"))
	end, "deconstructed")
	expectRaise(function()
		host:onTopTaggedChanged("body", logger(log, "late"))
	end, "deconstructed")
	expectRaise(function()
		host:onSocketAmongOthersChanged("body.head", helm, logger(log, "late"))
	end, "deconstructed")
	expectRaise(function()
		host:onAnySocketChanged(function(): () end)
	end, "deconstructed")
	expectRaise(function()
		host:onAnyTopTaggedChanged(function(): () end)
	end, "deconstructed")
	expectRaise(function()
		host:setPriority(body, 1)
	end, "not pushed")
	-- A release obtained earlier still works, remove does nothing, and a second deconstruct too.
	release()
	host:remove(body)
	host:deconstruct()
	expectLog(log, "")

	-- Still pushed in its parent, it answers nil until the parent removes it.
	assert(parent:containsSource(host), "the parent still holds the deconstructed host")
	expectSocket(parent, "body.head", "nil")
	parent:push(body, -1)
	expectSocket(parent, "body.head", "body:2")
	expectLog(log, "parent=body:2")
	parent:remove(host)
	expectSocket(parent, "body.head", "body:2")
	assert(not parent:containsSource(host), "removed")
end)

-- Heap growth in bytes of `run()`, the value most trials measure. A collector step runs only on an
-- allocation, so code that allocates nothing grows the heap by exactly 0 in every trial.
local TRIALS = 15
local trialGrowths: { number } = table.create(TRIALS) :: { number }
local function measureHeapGrowthBytes(run: () -> ()): number
	for trial = 1, TRIALS do
		local before = collectgarbage("count")
		run()
		trialGrowths[trial] = (collectgarbage("count") - before) * 1024
	end
	table.sort(trialGrowths)
	local mostFrequent, mostCount, runCount = trialGrowths[1], 0, 0
	for trial = 1, TRIALS do
		runCount = if trial > 1 and trialGrowths[trial] == trialGrowths[trial - 1]
			then runCount + 1
			else 1
		if runCount > mostCount then
			mostFrequent, mostCount = trialGrowths[trial], runCount
		end
	end
	assert(mostCount * 2 > TRIALS, "no heap growth was measured by a majority of trials")
	return mostFrequent
end

case(
	"the queries, and push, setPriority, remove and their reports for an instance, allocate nothing",
	function()
		local OPERATIONS = 200
		local parent = Anatomy.anatomyHost.new()
		local host = Anatomy.anatomyHost.new()
		local body = newInstance(
			"body",
			{ [2] = "body.head", [3] = "hand" },
			{ [2] = "skin", [3] = "skin" }
		)
		local helm = newInstance("helm", { [1] = "body.head" }, { [1] = "skin" })
		local elementIndexes: { number } = {}
		local anatomyInstances: { AnatomySource } = {}
		local calls = 0
		local function count(): ()
			calls += 1
		end
		parent:push(host, 0)
		host:push(body, 0)
		host:onSocketChanged("body.head", count)
		host:onTopTaggedChanged("skin", count)
		host:onSocketAmongOthersChanged("body.head", body, count)
		parent:onSocketChanged("body.head", count)

		-- Once before measuring, so every array has the capacity it needs.
		local function change(): ()
			host:push(helm, 5)
			host:setPriority(helm, 7)
			host:remove(helm)
		end
		local checksum = 0
		local function query(): ()
			local elementIndex, anatomyInstance = parent:getSocket("body.head")
			local topElementIndex = host:getTopTagged("skin")
			if elementIndex ~= nil and topElementIndex ~= nil and anatomyInstance == body then
				checksum += elementIndex + topElementIndex
			end
			table.clear(elementIndexes)
			table.clear(anatomyInstances)
			parent:getTagged("skin", elementIndexes, anatomyInstances)
			checksum += #elementIndexes
		end
		change()
		query()
		calls, checksum = 0, 0

		local queryGrowth = measureHeapGrowthBytes(function(): ()
			for _ = 1, OPERATIONS do
				query()
			end
		end)
		assert(
			checksum == (2 + 3 + 2) * OPERATIONS * TRIALS,
			"every query returned body's elements"
		)
		assert(queryGrowth == 0, "the queries grew the heap by " .. queryGrowth .. " bytes")

		local changeGrowth = measureHeapGrowthBytes(function(): ()
			for _ = 1, OPERATIONS do
				change()
			end
		end)
		-- push and remove each change both subscribed names on host, the name on parent and the winner
		-- among the sources other than body: 4 calls each. setPriority changes no winner.
		assert(
			calls == 8 * OPERATIONS * TRIALS,
			"expected 8 calls per change, got " .. calls / (OPERATIONS * TRIALS)
		)
		assert(
			changeGrowth == 0,
			"push, setPriority and remove grew the heap by " .. changeGrowth .. " bytes"
		)
	end
)
