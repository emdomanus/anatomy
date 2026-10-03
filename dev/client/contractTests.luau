--!strict
--!optimize 2

local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)
local bindMountWatchers = require(script.Parent.bindMountWatchers)

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

local function expect(condition: boolean, message: string): ()
	assert(condition, message)
end

local function testExplicitMount()
	local owner = Instance.new("Model")
	local from = Instance.new("Attachment")
	local to = Instance.new("Attachment")
	local replacement = Instance.new("Attachment")
	from.Parent = owner
	to.Parent = owner
	replacement.Parent = owner
	local mount = Anatomy.socketMount.new(nil, nil)
	local rigid = assert(mount:getConstraint(), "Mount must create its one constraint immediately")
	expect(rigid.Parent == nil and not rigid.Enabled, "Empty mount must be unparented and disabled")
	mount:setAttachments(from, to)
	expect(mount:isConnected() and rigid.Enabled, "Explicit attachment update did not connect")
	expect(rigid.Parent == nil, "Mount inferred a parent from its attachments")
	mount:setParent(owner)
	mount:setEnabled(false)
	mount:setAttachments(replacement, to)
	expect(not rigid.Enabled, "Retargeting lost the caller's disabled state")
	mount:setAttachments(nil, to)
	mount:setEnabled(true)
	expect(not rigid.Enabled and not mount:isConnected(), "Missing source must stay disabled")
	mount:setAttachments(from, nil)
	expect(not rigid.Enabled and not mount:isConnected(), "Missing target must stay disabled")
	mount:setAttachments(from, to)
	expect(rigid.Enabled, "Restoring attachments did not restore requested enabled state")
	expect(mount:getConstraint() == rigid, "Retargeting replaced the owned constraint")
	mount:setParent(nil)
	mount:setAttachments(replacement, to)
	mount:setEnabled(false)
	mount:setEnabled(true)
	expect(rigid.Parent == nil, "Attachment/enabled updates undid explicit unparenting")
	mount:setParent(owner)
	expect(rigid.Parent == owner, "Explicit parenting did not apply")
	mount:deconstruct()
	mount:deconstruct()
	expect(
		mount:getConstraint() == nil and not mount:isConnected(),
		"Destroyed mount retained state"
	)
	expect(
		mount:getFromAttachment() == nil and mount:getToAttachment() == nil,
		"Destroyed mount retained attachments"
	)
	expectError(function()
		mount:setAttachments(from, to)
	end)
	expectError(function()
		mount:setEnabled(true)
	end)
	expectError(function()
		mount:setParent(owner)
	end)
	local named = Anatomy.socketMount.new(
		from,
		to,
		{ parent = owner, name = "Logical", rigidName = "Physical", enabled = false }
	)
	local namedRigid = assert(named:getConstraint(), "Missing named constraint")
	expect(named:getName() == "Logical" and namedRigid.Name == "Physical", "Mount naming changed")
	expect(
		namedRigid.Parent == owner and not namedRigid.Enabled,
		"Constructor options did not apply"
	)
	named:deconstruct()
	owner:Destroy()
end

local function run()
	require(script.Parent.allocationContractTests)()
	testExplicitMount()
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
	local watcher = host:watchSocket("grip" :: SocketName)
	local terminal = false
	watcher:bindSocketChanged(function(value)
		if value == nil then
			terminal = true
		end
	end)
	local mount = host:mount(nil, attachment)
	local disconnectMount = watcher:bindSocketChanged(function(selected)
		mount:setAttachments(if selected then selected:getAttachment() else nil, attachment)
	end, true)
	local concreteAttachment: Attachment = socket:getAttachment()
	assert(concreteAttachment == attachment, "A live socket must always have its attachment")
	local staticMount = Anatomy.socketMount.new(socket:getAttachment(), attachment)
	assert(staticMount:getFromAttachment() == attachment, "Concrete socket mount failed")
	staticMount:deconstruct()
	layer:remove()
	instance:deconstruct()
	assert(terminal, "Removing the layer must notify watcher dependents")
	assert(mount:getFromAttachment() == nil, "Mount retained a removed socket")
	expectError(function()
		socket:getAttachment()
	end)
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

	local replacementSocket = assert(replacementInstance:getSocket("grip" :: SocketName))
	assert(watcher:getSocket() == replacementSocket, "Watcher did not follow layer replacement")
	assert(mount:getFromAttachment() == attachment, "Mount did not reconnect after replacement")
	local overlayInstance = template:instantiate(nil)
	local overlay = host:push(overlayInstance, { id = "overlay", priority = 10 })
	local overlaySocket = assert(overlayInstance:getSocket("grip" :: SocketName))
	local pinned = host:watchSocket("grip" :: SocketName, "rig")
	local baseOnly = host:watchSocket("grip" :: SocketName, nil, false)
	local missing = host:watchSocket("grip" :: SocketName, "missing")
	local watcherMount = Anatomy.socketMount.new(nil, nil)
	local disconnectWatcherMount = bindMountWatchers(watcherMount, pinned, watcher)
	assert(watcher:getSocket() == overlaySocket, "Default watcher must follow overrides")
	assert(pinned:getSocket() == replacementSocket, "Layer watcher must ignore other layers")
	assert(baseOnly:getSocket() == replacementSocket, "Overrides-disabled watcher must choose base")
	assert(missing:getSocket() == nil, "Missing address must produce nil")
	assert(
		watcherMount:getToAttachment() == overlaySocket:getAttachment(),
		"Watcher pair mount did not resolve"
	)
	local notifications = 0
	local disconnect = watcher:bindSocketChanged(function()
		notifications += 1
	end, true)
	overlay:setPriority(20)
	assert(notifications == 1, "Unchanged selection must not notify")
	overlay:setPriority(-1)
	assert(watcher:getSocket() == replacementSocket, "Priority change did not retarget")
	assert(notifications == 2, "Changed selection must notify exactly once")
	assert(watcherMount:getToAttachment() == attachment, "Mount missed priority retarget")
	disconnect()
	overlay:remove()
	overlayInstance:deconstruct()
	disconnectWatcherMount()
	watcherMount:deconstruct()
	assert(pinned:getSocket() == replacementSocket, "Mount destroyed a borrowed watcher")
	assert(watcher:getSocket() == replacementSocket, "Mount destroyed its other borrowed watcher")
	pinned:deconstruct()
	baseOnly:deconstruct()
	missing:deconstruct()
	-- A socket-vocabulary difference must not force a shared concrete generic on mounts.
	local stringHost =
		Anatomy.anatomyHost.new({ socketNameGuard = guardString, tagGuard = guardString })
	local stringWatcher = stringHost:watchSocket("other")
	local crossVocabularyMount = Anatomy.socketMount.new(nil, nil)
	local disconnectCrossVocabulary =
		bindMountWatchers(crossVocabularyMount, watcher, stringWatcher)
	assert(not crossVocabularyMount:isConnected(), "Unresolved watcher must disable mount")
	disconnectCrossVocabulary()
	crossVocabularyMount:deconstruct()
	stringHost:deconstruct()
	-- Destroying a watcher publishes nil to an independently owned mount.
	local disposable = host:watchSocket("grip" :: SocketName)
	local detachedMount = Anatomy.socketMount.new(nil, attachment)
	local visual = Instance.new("Model")
	local disconnectDisposable = disposable:bindSocketChanged(function(selected)
		detachedMount:setAttachments(if selected then selected:getAttachment() else nil, attachment)
		visual.Parent = if selected then source else nil
	end, true)
	assert(visual.Parent == source, "Owner did not parent the mounted visual")

	disposable:deconstruct()
	disposable:deconstruct()
	assert(disposable:getSocket() == nil, "Destroyed watcher retained socket")
	assert(detachedMount:getFromAttachment() == nil, "Watcher destruction did not disconnect mount")
	assert(not detachedMount:isConnected(), "Watcher destruction left mount enabled")
	assert(visual.Parent == nil, "Owner did not unparent the unmounted visual")
	disconnectDisposable()
	detachedMount:deconstruct()
	visual:Destroy()

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
	disconnectMount()
	host:deconstruct()
	expectError(function()
		host:watchSocket("grip" :: SocketName)
	end)
	replacementInstance:deconstruct()
	permissiveInstance:deconstruct()
	rejectingHost:deconstruct()
	source:Destroy()
end

return run
