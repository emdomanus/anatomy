--!strict
--!optimize 2
local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)
local bindMountSockets = require(script.Parent.bindMountSockets)

type Name = "grip"
type Tag = "body.hand"
local function socketGuard(value: unknown): Name
	assert(value == "grip", "Expected grip")
	return value :: Name
end
local function tagGuard(value: unknown): Tag
	assert(value == "body.hand", "Expected body.hand")
	return value :: Tag
end
local function stringGuard(value: unknown): string
	assert(type(value) == "string", "Expected string")
	return value
end
local function reject(callback: () -> ()): ()
	assert(not pcall(callback), "Expected rejection")
end
local function check(condition: boolean, message: string): ()
	assert(condition, message)
end
local function fixture(name: string, socketName: string?): Anatomy.AnatomyInstance<string, string>
	local root = Instance.new("Model")
	root.Name = name
	root:SetAttribute("Tags", "body.root")
	local folder = Instance.new("Folder")
	folder.Name = "Duplicate"
	folder.Parent = root
	local selectedFolder = Instance.new("Folder")
	selectedFolder.Name = "Duplicate"
	selectedFolder.Parent = root
	local attachment = Instance.new("Attachment")
	attachment.Name = "Grip"
	attachment:SetAttribute("Socket", socketName or "grip")
	attachment:SetAttribute("Tags", "body.hand;effect.grip")
	attachment.Parent = selectedFolder
	local template = Anatomy.anatomyTemplate.new(root, {
		socketNameGuard = stringGuard,
		tagGuard = stringGuard,
		socketAttribute = "Socket",
		tagsAttribute = "Tags",
	})
	local instance = template:instantiate(nil)
	local live = assert(instance:getSocket(socketName or "grip"), "Missing recognized socket")
	check(
		live:getAttachment().Parent == instance:getRoot():GetChildren()[2],
		"Duplicate sibling path resolved incorrectly"
	)
	check(live:getAttachment() ~= attachment, "Instantiation reused source attachment")
	root:Destroy()
	return instance
end

local function run(): ()
	-- No constructor assertion: both generics must infer from guards.
	local inferred = Anatomy.anatomyHost.new({ socketNameGuard = socketGuard, tagGuard = tagGuard })
	local typed: Anatomy.AnatomyHost<Name, Tag> = inferred
	local initial = 0
	local releaseTyped = typed:bindToSocket("grip" :: Name, function(socket)
		check(socket == nil, "Empty subscription must publish nil")
		initial += 1
	end, true)
	check(initial == 1, "Missing initial nil")
	releaseTyped()
	typed:deconstruct()
	local typedAsset = Instance.new("Attachment")
	typedAsset:SetAttribute("Socket", "grip")
	typedAsset:SetAttribute("Tags", "body.hand")
	local inferredTemplate = Anatomy.anatomyTemplate.new(typedAsset, {
		socketNameGuard = socketGuard,
		tagGuard = tagGuard,
		socketAttribute = "Socket",
		tagsAttribute = "Tags",
	})
	local typedInstance: Anatomy.AnatomyInstance<Name, Tag> = inferredTemplate:wrap(typedAsset)
	check(
		typedInstance:getSocket("grip" :: Name) ~= nil,
		"Template generics or root socket recognition failed"
	)
	typedInstance:deconstruct()
	check(typedAsset:GetAttribute("Socket") == "grip", "Wrapping destroyed a borrowed root")
	typedAsset:Destroy()
	local invalid = Instance.new("Model")
	invalid:SetAttribute("Socket", "grip")
	reject(function()
		Anatomy.anatomyTemplate.new(
			invalid,
			{ socketNameGuard = stringGuard, tagGuard = stringGuard, socketAttribute = "Socket" }
		)
	end)
	invalid:SetAttribute("Socket", nil)
	invalid:SetAttribute("Tags", "wrong")
	reject(function()
		Anatomy.anatomyTemplate.new(
			invalid,
			{ socketNameGuard = socketGuard, tagGuard = tagGuard, tagsAttribute = "Tags" }
		)
	end)
	invalid:Destroy()
	local options = { socketNameGuard = stringGuard, tagGuard = stringGuard }
	local a, b, c = fixture("A"), fixture("B"), fixture("C")
	local socketA = assert(a:getSocket("grip"), "Missing A socket")
	local socketB = assert(b:getSocket("grip"), "Missing B socket")
	local element = a:getTagged("effect")[1]
	local tags = element:getTags()
	check(
		tags == element:getTags() and table.isfrozen(tags),
		"Tags should return the same frozen set"
	)
	reject(function()
		tags["bad"] = true
	end)
	local collection = a:getTagged("body")
	table.clear(collection)
	check(#a:getTagged("body") == 2, "Tag result leaked mutable storage")
	local initialSockets = 0
	a:bindSocketChanged(function(name, socket)
		check(name == "grip" and socket == socketA, "Source initial socket mismatch")
		initialSockets += 1
	end, true)()
	check(initialSockets == 1, "Source initial enumeration missing")
	local host = Anatomy.anatomyHost.new(options)
	local child = Anatomy.anatomyHost.new(options)
	local sibling = Anatomy.anatomyHost.new(options)
	local sourceView: Anatomy.AnatomySource<string, string> = child
	local instanceView: Anatomy.AnatomySource<string, string> = a
	child:push(instanceView)
	host:push(sourceView, 10)
	check(host:getSocket("grip") == socketA, "Nested initial enumeration failed")
	local mount = host:mount(nil, nil)
	local disconnectMount = bindMountSockets(mount, host, "grip", "grip")
	check(mount:getFromAttachment() == socketA:getAttachment(), "Owner mount did not initialize")
	local changes = 0
	local releaseSocket = host:bindSocketChanged(function(name, _socket)
		check(name == "grip", "Unrelated socket was emitted")
		changes += 1
	end)
	child:push(b, 5)
	check(host:getSocket("grip") == socketB, "Nested replacement failed")
	check(changes == 1, "Replacement emitted duplicate notifications")
	host:push(c, 0)
	check(changes == 1, "Nonwinning source emitted a socket change")
	host:setPriority(c, 10)
	check(
		host:getSocket("grip") == c:getSocket("grip"),
		"Later registration did not win equal priority"
	)
	host:setPriority(child, 20)
	check(host:getSocket("grip") == socketB, "Parent group priority was not respected")
	child:remove(b)
	check(host:getSocket("grip") == socketA, "Nested fallback failed")
	check(not child:remove(b), "Repeated removal should return false")
	reject(function()
		host:push(child)
	end)
	reject(function()
		host:push(host)
	end)
	reject(function()
		child:push(host)
	end)
	sibling:push(host)
	reject(function()
		child:push(sibling)
	end)
	sibling:remove(host)
	reject(function()
		child:setPriority(b, 1)
	end)
	-- Shared leaf membership through distinct hosts must be counted once.
	sibling:push(a)
	local adds, removes = 0, 0
	local releaseAdded = host:bindTaggedAdded(function(_element)
		adds += 1
	end, true)
	local releaseRemoved = host:bindTaggedRemoved(function(_element)
		removes += 1
	end)
	check(adds == 4, "Initial tag union mismatch")
	host:push(sibling, -1)
	check(adds == 4 and #host:getTagged("body") == 4, "Shared tags were duplicated")
	child:remove(a)
	check(removes == 0, "One child removal erased shared membership")
	sibling:remove(a)
	check(removes == 2 and #host:getTagged("body") == 2, "Final contribution removal failed")
	check(
		host:getSocket("grip") == c:getSocket("grip"),
		"Final contribution socket fallback failed"
	)
	host:remove(c)
	check(
		host:getSocket("grip") == nil and not mount:isConnected(),
		"Empty selection did not clear owner mount"
	)
	-- Reentrant removal during publication must not leave subscriptions or membership.
	local reentrant = Anatomy.anatomyHost.new(options)
	local releaseReentrant = reentrant:bindSocketChanged(function(_name, socket)
		if socket then
			reentrant:remove(a)
		end
	end)
	reentrant:push(a)
	check(
		reentrant:getSocket("grip") == nil and #reentrant:getTagged("body") == 0,
		"Reentrant removal left state"
	)
	releaseReentrant()
	reentrant:push(a)
	reentrant:remove(a)
	reentrant:deconstruct()
	-- A dynamic provider only publishes the changed name. Parent caches its contributions;
	-- it must not query unrelated names or rebuild tag collections on socket events.
	local provider = Anatomy.anatomyHost.new(options)
	local tip = fixture("Tip", "tip")
	provider:push(a)
	provider:push(tip)
	local queryCount = 0
	local probe: Anatomy.AnatomySource<string, string> = {
		getSocket = function(_self, name)
			queryCount += 1
			return provider:getSocket(name)
		end,
		getTagged = function(_self, prefix)
			queryCount += 1
			return provider:getTagged(prefix)
		end,
		getTopTagged = function(_self, prefix)
			return provider:getTopTagged(prefix)
		end,
		bindTopTaggedChanged = function(_self, prefix, callback, initially)
			return provider:bindTopTaggedChanged(prefix, callback, initially)
		end,
		bindToSocket = function(_self, name, callback, initially)
			return provider:bindToSocket(name, callback, initially)
		end,
		bindSocketChanged = function(_self, callback, initially)
			return provider:bindSocketChanged(callback, initially)
		end,
		bindTaggedAdded = function(_self, callback, initially)
			return provider:bindTaggedAdded(callback, initially)
		end,
		bindTaggedRemoved = function(_self, callback)
			return provider:bindTaggedRemoved(callback)
		end,
	}
	local parent = Anatomy.anatomyHost.new(options)
	parent:push(probe)
	local tipChanges, gripChanges = 0, 0
	local releaseProbe = parent:bindSocketChanged(function(name)
		if name == "tip" then
			tipChanges += 1
		else
			gripChanges += 1
		end
	end)
	provider:remove(tip)
	check(
		tipChanges == 1 and gripChanges == 0 and queryCount == 0,
		"Single-name update crawled the source or notified unrelated sockets"
	)
	check(
		parent:getSocket("grip") == socketA and parent:getSocket("tip") == nil,
		"Incremental cached membership drifted"
	)
	releaseProbe()
	parent:remove(probe)
	parent:deconstruct()
	provider:deconstruct()
	tip:deconstruct()
	-- Failed initial guard validation releases child subscriptions and leaves no registration.
	local restrictive = Anatomy.anatomyHost.new({
		socketNameGuard = stringGuard,
		tagGuard = function(value: unknown): string
			assert(value == "allowed", "Rejected tag")
			return value :: string
		end,
	})
	child:push(a)
	reject(function()
		restrictive:push(child)
	end)
	check(
		not restrictive:remove(child) and restrictive:getSocket("grip") == nil,
		"Rejected source installed state"
	)
	child:remove(a)
	restrictive:deconstruct()
	releaseAdded()
	releaseRemoved()
	releaseSocket()
	disconnectMount()
	host:deconstruct()
	check(
		host:getSocket("grip") == nil and mount:getConstraint() == nil,
		"Host-owned resources survived teardown"
	)
	child:push(a)
	check(child:getSocket("grip") == socketA, "Parent teardown destroyed borrowed child")
	child:remove(a)
	child:deconstruct()
	sibling:deconstruct()
	reject(function()
		host:push(a)
	end)
	reject(function()
		host:bindToSocket("grip", function() end)
	end)
	a:deconstruct()
	b:deconstruct()
	c:deconstruct()
	check(
		next(element:getTags()) == nil and table.isfrozen(element:getTags()),
		"Retired tags must be frozen empty"
	)
	reject(function()
		socketA:getAttachment()
	end)
end
return run
