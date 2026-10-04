--!strict
--!optimize 2
local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)
type Element = Anatomy.AnatomyTaggedElement<string>
local function guard(value: unknown): string
	assert(type(value) == "string", "Expected string")
	return value
end
local function host(): Anatomy.AnatomyHost<string, string>
	return Anatomy.anatomyHost.new({ socketNameGuard = guard, tagGuard = guard })
end
local function fixture(tag: string): Anatomy.AnatomyInstance<string, string>
	local root = Instance.new("Model")
	root:SetAttribute("Tags", tag)
	local child = Instance.new("Attachment")
	child.Name = "Socket"
	child:SetAttribute("Socket", "grip")
	child:SetAttribute("Tags", tag)
	child.Parent = root
	local template = Anatomy.anatomyTemplate.new(root, {
		socketNameGuard = guard,
		tagGuard = guard,
		tagsAttribute = "Tags",
		socketAttribute = "Socket",
	})
	local result = template:instantiate(nil)
	root:Destroy()
	return result
end
local function run(): ()
	local a, b, other = fixture("body.hand"), fixture("body.hand"), fixture("effect.spark")
	local aTags, bTags = a:getTagged("body"), b:getTagged("body")
	local aTop, bTop = aTags[#aTags], bTags[#bTags]
	assert(a:getTopTagged("body") == aTop, "Instance top must be its last match")
	local child, parent = host(), host()
	child:push(a)
	parent:push(child)
	local queries, subscriptions = 0, 0
	local probe: Anatomy.AnatomySource<string, string> = {
		getSocket = function(_self, name)
			return b:getSocket(name)
		end,
		getTagged = function(_self, prefix)
			return b:getTagged(prefix)
		end,
		getTopTagged = function(_self, prefix)
			queries += 1
			return b:getTopTagged(prefix)
		end,
		bindToSocket = function(_self, name, callback, initial)
			return b:bindToSocket(name, callback, initial)
		end,
		bindSocketChanged = function(_self, callback, initial)
			return b:bindSocketChanged(callback, initial)
		end,
		bindTaggedAdded = function(_self, callback, initial)
			return b:bindTaggedAdded(callback, initial)
		end,
		bindTaggedRemoved = function(_self, callback)
			return b:bindTaggedRemoved(callback)
		end,
		bindTopTaggedChanged = function(_self, prefix, callback, initial)
			subscriptions += 1
			local release = b:bindTopTaggedChanged(prefix, callback, initial)
			local active = true
			return function()
				if active then
					active = false
					subscriptions -= 1
					release()
				end
			end
		end,
	}
	child:push(probe, -1)
	assert(queries == 0 and subscriptions == 0, "Unobserved prefixes created selection work")
	local selected: Element? = nil
	local changes = 0
	local release = parent:bindTopTaggedChanged("body", function(element)
		selected = element
		changes += 1
	end, true)
	assert(
		selected == aTop and changes == 1 and subscriptions == 1,
		"Nested initial selection failed"
	)
	local releaseSecond = parent:bindTopTaggedChanged("body", function() end)
	assert(subscriptions == 1, "Second listener duplicated child subscription")
	local before = queries
	parent:getTopTagged("body")
	assert(queries == before, "Observed getter did not use cache")
	child:push(other, 20)
	child:setPriority(other, 30)
	child:remove(other)
	assert(queries == before and changes == 1, "Unrelated tag mutation refreshed body")
	child:setPriority(probe, 1)
	assert(selected == bTop and changes == 2, "Nested priority-only change was lost")
	local ordered = parent:getTagged("body")
	assert(
		#ordered == 4 and ordered[1] == aTags[1] and ordered[4] == bTop,
		"Ordered aggregate differs from top selection"
	)
	child:setPriority(a, 1)
	assert(selected == bTop and changes == 2, "Priority tie ignored registration order")
	child:setPriority(a, 2)
	assert(selected == aTop and changes == 3, "Priority winner did not change")
	child:remove(a)
	assert(selected == bTop and changes == 4, "Winner removal did not fall back")
	child:remove(probe)
	assert(
		selected == nil and changes == 5 and subscriptions == 0,
		"Final removal did not publish nil/release child"
	)
	child:push(probe)
	assert(selected == bTop and subscriptions == 1, "Observed empty prefix did not recover")
	release()
	release()
	assert(subscriptions == 1, "One release disconnected another listener")
	releaseSecond()
	assert(subscriptions == 0, "Final release retained nested observation")
	before = queries
	child:setPriority(probe, 99)
	assert(queries == before, "Unobserved priority change recomputed selection")
	assert(
		parent:getTopTagged("body") == bTop and queries > before,
		"Discrete query did not resolve current value"
	)
	-- Shared leaves remain unique and take their highest-precedence occurrence.
	local sibling = host()
	sibling:push(b)
	parent:push(sibling, 10)
	assert(#parent:getTagged("body") == 2, "Shared nested leaf was duplicated")
	-- Initial callback failure must release recursively acquired subscriptions.
	local ok = pcall(function()
		parent:bindTopTaggedChanged("body", function()
			error("intentional callback failure")
		end, true)
	end)
	assert(not ok and subscriptions == 0, "Initial failure leaked selection subscriptions")
	local socketChanges = 0
	local releaseSocket = parent:bindToSocket("grip", function()
		socketChanges += 1
	end, true)
	local final: Element? = bTop
	local releaseFinal = parent:bindTopTaggedChanged("body", function(element)
		final = element
	end, true)
	sibling:deconstruct()
	assert(final == bTop, "Nested teardown erased another contribution")
	child:deconstruct()
	assert(
		final == nil and parent:getSocket("grip") == nil and socketChanges == 2,
		"Nested teardown left a stale selection"
	)
	releaseSocket()
	releaseFinal()
	parent:deconstruct()
	-- Synchronous listener mutation may change the winner again during dispatch.
	local reentrant = host()
	reentrant:push(a)
	local releaseReentrant = reentrant:bindTopTaggedChanged("body", function(element)
		if element == bTop then
			reentrant:remove(b)
		end
	end)
	reentrant:push(b, 10)
	assert(
		reentrant:getTopTagged("body") == aTop,
		"Reentrant winner removal left stale cached selection"
	)
	releaseReentrant()
	local failure = pcall(function()
		reentrant:bindToSocket("grip", function()
			error("intentional socket callback failure")
		end, true)
	end)
	assert(not failure, "Initial socket callback error was swallowed")
	reentrant:deconstruct()
	a:deconstruct()
	b:deconstruct()
	other:deconstruct()
end
return run
