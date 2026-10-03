--!strict
--!optimize 2

local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)

type SocketName = "grip"
type TagName = "body.hand"
type AnatomyHost = Anatomy.AnatomyHost<SocketName, TagName>

local function guardSocket(value: unknown): SocketName
	assert(value == "grip", "Expected grip")
	return value :: SocketName
end

local function guardTag(value: unknown): TagName
	assert(value == "body.hand", "Expected body.hand")
	return value :: TagName
end

local function guardString(value: unknown): string
	assert(type(value) == "string", "Expected string")
	return value
end

local function expectError(callback: () -> ())
	assert(not pcall(callback), "Expected rejection")
end

local function run()
	-- The constructor call has no annotation or assertion: both types must infer.
	local inferredHost =
		Anatomy.anatomyHost.new({ socketNameGuard = guardSocket, tagGuard = guardTag })
	local host: AnatomyHost = inferredHost
	local source = Instance.new("Model")
	local attachment = Instance.new("Attachment")
	attachment.Name = "Grip"
	attachment:SetAttribute("Socket", "grip")
	attachment:SetAttribute("Tags", "body.hand")
	attachment.Parent = source
	local template = Anatomy.anatomyTemplate.recognize(source, {
		socketAttribute = "Socket",
		tagsAttribute = "Tags",
		socketNameGuard = guardSocket,
		tagGuard = guardTag,
	})
	local instance = template:wrap(source)
	local layer = host:push(instance, { id = "rig" })
	assert(#host:getByTag("body") == 1, "Ancestor prefixes must not use the leaf guard")
	local socket = assert(host:getSocket("grip" :: SocketName))
	local binding = host:socket("grip" :: SocketName)
	local terminal = false
	binding:bindAttachmentChanged(function(value)
		if value == nil then
			terminal = true
		end
	end)
	local mount = host:mount({ from = binding, to = attachment })
	instance:deconstruct()
	assert(terminal, "Destroying a borrowed instance must notify binding dependents")
	assert(mount:getFromAttachment() == nil, "Mount retained a destroyed endpoint")
	assert(socket:getAttachment() == nil, "Destroyed socket retained attachment")
	assert(
		source.Parent == nil and source:FindFirstChild("Grip") == attachment,
		"Wrap must not destroy the source"
	)
	layer:remove()
	local replacementInstance = template:wrap(source)
	local replacement = host:push(replacementInstance, { id = "rig" })
	layer:remove()
	assert(
		host:getLayer("rig") == replacement,
		"Retired handles must not remove replacement registrations"
	)
	expectError(function()
		layer:setPriority(5)
	end)
	replacement:setPriority(3)
	assert(replacement:getPriority() == 3, "Host did not apply layer priority")

	local permissiveTemplate = Anatomy.anatomyTemplate.recognize(source, {
		socketAttribute = "Socket",
		tagsAttribute = "Tags",
		socketNameGuard = guardString,
		tagGuard = guardString,
	})
	local permissiveInstance = permissiveTemplate:wrap(source)
	local rejectingHost = Anatomy.anatomyHost.new({
		socketNameGuard = guardString,
		tagGuard = function(value: unknown): string
			assert(value ~= "body.hand", "Rejected tag")
			return guardString(value)
		end,
	})
	expectError(function()
		rejectingHost:push(permissiveInstance)
	end)
	assert(#rejectingHost:getLayers() == 0, "Rejected layers must not install state")
	local descriptor = assert(template:getSocketDescriptor("grip" :: SocketName))
	assert(
		table.isfrozen(descriptor) and table.isfrozen(descriptor.path),
		"Descriptors must be immutable snapshots"
	)
	host:deconstruct()
	expectError(function()
		host:socket("grip" :: SocketName)
	end)
	replacementInstance:deconstruct()
	permissiveInstance:deconstruct()
	rejectingHost:deconstruct()
	source:Destroy()
end

return run
