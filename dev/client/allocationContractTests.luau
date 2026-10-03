--!strict
--!optimize 2

local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)

local function guardString(value: unknown): string
	assert(type(value) == "string", "Expected string")
	return value
end

local function run(): ()
	local source = Instance.new("Model")
	source:SetAttribute("Tags", "body.root")
	local first = Instance.new("Folder")
	first.Name = "Duplicate"
	first.Parent = source
	local second = Instance.new("Folder")
	second.Name = "Duplicate"
	second.Parent = source
	local attachment = Instance.new("Attachment")
	attachment.Name = "Grip"
	attachment:SetAttribute("Socket", "grip")
	attachment:SetAttribute("Tags", "body.hand;effect.grip")
	attachment.Parent = second
	local config = {
		socketNameGuard = guardString,
		tagGuard = guardString,
		socketAttribute = "Socket",
		tagsAttribute = "Tags",
	}
	local template = Anatomy.anatomyTemplate.recognize(source, config)
	local descriptor = assert(template:getSocketDescriptor("grip"), "Missing recognized socket")
	assert(
		#descriptor.path == 2 and descriptor.path[1].ordinal == 2,
		"Recognition lost duplicate sibling ordinal"
	)
	assert(table.isfrozen(descriptor.path[1]), "Recognized path steps must be frozen")
	local descriptors = template:getSocketDescriptors()
	descriptors.grip = nil
	local tags = template:getTagDescriptors()
	table.clear(tags)
	assert(
		template:getSocketDescriptor("grip") == descriptor and #template:getTagDescriptors() == 2,
		"Public snapshots mutated the template"
	)

	local instance = template:wrap(source)
	local cloned = template:instantiate(nil)
	local socket = assert(instance:getSocket("grip"), "Missing wrapped socket")
	assert(socket:getAttachment() == attachment, "Reversed path resolved the wrong sibling")
	local cloneSocket = assert(cloned:getSocket("grip"), "Missing cloned socket")
	assert(
		cloneSocket:getAttachment() ~= attachment,
		"Construction reused a live socket across instances"
	)
	assert(
		cloneSocket:getAttachment().Parent == cloned:getRoot():GetChildren()[2],
		"Clone resolved the wrong sibling"
	)
	local sockets = instance:getSockets()
	table.clear(sockets)
	local element = assert(instance:getFirstByTag("effect"), "Missing direct tag result")
	assert(element == instance:getByTag("effect")[1], "Single result changed selection")
	local elementTags = element:getTags()
	table.clear(elementTags)
	assert(element:hasTag("body"), "Tag snapshot mutated the element")
	local socketCount = 0
	instance:forEachSocket(function(name, selected)
		assert(name == "grip" and selected == socket, "Socket traversal changed identity")
		socketCount += 1
	end)
	assert(socketCount == 1, "Snapshot mutation changed traversal")
	local tagCount = 0
	element:forEachTag(function(tag)
		assert(tag == "body.hand" or tag == "effect.grip", "Unexpected leaf tag")
		tagCount += 1
	end)
	assert(tagCount == 2, "Tag traversal lost tags")
	local elementCount = 0
	instance:forEachTaggedElement(function(_element)
		elementCount += 1
	end)
	assert(elementCount == 2, "Root tags were omitted")
	local selectedCount = 0
	instance:forEachByTag("body", function(_element)
		selectedCount += 1
	end)
	assert(selectedCount == 2, "Prefix traversal lost root or descendant")
	assert(instance:getFirstByTag("missing") == nil, "Missing prefix produced a result")
	instance:forEachByTag("missing", function(_element)
		error("Missing prefix invoked callback")
	end)

	local host = Anatomy.anatomyHost.new(config)
	host:push(instance, { id = "one" })
	host:push(cloned, { id = "two" })
	assert(host:getSocket("grip") == cloneSocket, "Host override changed")
	assert(host:getSocket("grip", nil, false) == socket, "Base socket selection changed")
	assert(
		#host:getSocketNames() == 1 and host:getSockets().grip == cloneSocket,
		"Host enumeration changed"
	)
	assert(#host:getByTag("body") == 4, "Host collection lost elements")
	assert(
		host:getFirstByTag("body") == host:getByTag("body")[1],
		"Uncached first result changed order"
	)
	assert(
		host:getFirstByTag("effect", "two") == cloned:getFirstByTag("effect"),
		"Layer-specific first result changed"
	)
	assert(host:getFirstByTag("body", "missing") == nil, "Missing layer produced a result")
	local allElements = host:getByTag("body")
	assert(
		host:getLastByTag("body") == allElements[#allElements],
		"Uncached last result changed order"
	)
	assert(
		instance:getLastByTag("body") == instance:getByTag("body")[2],
		"Instance last result changed order"
	)
	assert(host:getLastByTag("effect", "one") == element, "Layer-specific last result changed")
	assert(
		host:getLastByTag("missing") == nil and host:getLastByTag("body", "missing") == nil,
		"Missing last result should be nil"
	)
	local added = 0
	local removed = 0
	local nestedHost = Anatomy.anatomyHost.new(config)
	local nestedAdded = 0
	local nestedDisconnect = nestedHost:bindByTag("body", function(_element)
		nestedAdded += 1
	end, function(_element) end)
	local disconnect = host:bindByTag("body", function(_element)
		added += 1
		if added == 1 then
			nestedHost:push(instance)
		end
	end, function(_element)
		removed += 1
	end, true)
	assert(added == 4 and nestedAdded == 2, "Nested refresh corrupted tag snapshots")
	assert(
		host:getFirstByTag("body") == host:getByTag("body")[1],
		"Watched first result diverged from collection"
	)
	local watchedElements = host:getByTag("body")
	assert(
		host:getLastByTag("body") == watchedElements[#watchedElements],
		"Watched last result diverged from collection"
	)
	-- The same instance in two layers must still deduplicate watched tag membership.
	host:push(instance, { id = "duplicate" })
	assert(added == 4, "Watched membership reported duplicate additions")
	host:remove("one")
	assert(removed == 0, "Removing one registration removed shared membership")
	host:remove("duplicate")
	assert(removed == 2, "Final registration did not remove membership")
	assert(
		host:getSocket("grip") == cloneSocket,
		"Removing duplicate registration lost remaining socket"
	)
	disconnect()
	nestedDisconnect()
	host:deconstruct()
	nestedHost:deconstruct()
	instance:deconstruct()
	cloned:deconstruct()
	element:forEachTag(function(_tag)
		error("Retired element still enumerates tags")
	end)

	-- Public construction must still copy caller-owned descriptors, including nested tables.
	local branchStep = { name = "Duplicate", className = "Folder", ordinal = 2 }
	local path: Anatomy.AnatomyPath = {
		branchStep,
		{ name = "Grip", className = "Attachment", ordinal = 1 },
	}
	local externalTags = { ["effect.grip"] = true }
	local prefixes = { effect = true, ["effect.grip"] = true }
	local custom = Anatomy.anatomyTemplate.new(
		source,
		config,
		{ grip = { name = "grip", path = path } },
		{ { path = path, tags = externalTags, prefixes = prefixes } }
	)
	branchStep.ordinal = 1
	table.clear(externalTags)
	table.clear(prefixes)
	local wrapped = custom:wrap(source)
	assert(
		assert(wrapped:getSocket("grip"), "Missing custom socket"):getAttachment() == attachment,
		"Caller mutation changed snapshotted path"
	)
	assert(#wrapped:getByTag("effect") == 1, "Caller mutation changed snapshotted tags")
	wrapped:deconstruct()
	source:Destroy()
end

return run
