--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Anatomy = require(ReplicatedStorage:WaitForChild("packages"):WaitForChild("anatomy"))


local DEV_ROOT_NAME = "AnatomyDev"
local SOCKET_ATTRIBUTE = "AnatomySocket"
local TAGS_ATTRIBUTE = "AnatomyTags"
local DEMO_RIG_ORIGIN = CFrame.new(0, 5, -6)
local DEMO_WEAPON_ORIGIN = CFrame.new(1.6, 5, -6)
local DEMO_SLOT_SPACING = 4

type DevModelKind = "rig" | "weapon"
type TestDefinition = {
	name: string,
	run: () -> (),
}
type DemoState = {
	host: any?,
	reactiveMount: any?,
	directMount: any?,
	rigInstances: { any },
	weaponInstances: { any },
	activeRigIndex: number,
	activeWeaponIndex: number,
	mountedRigIndex: number?,
	mountedWeaponIndex: number?,
}

local recognizeOptions = {
	socketAttribute = SOCKET_ATTRIBUTE,
	tagsAttribute = TAGS_ATTRIBUTE,
	tagDelimiter = ";",
	tagPathDelimiter = ".",
	instancePolicy = {
		canCollide = false,
		canQuery = false,
		canTouch = false,
		audioCanCollide = false,
		castShadow = false,
		enableFluidForces = false,
		massless = true,
	},
}

local function buildRecognizeConfig<TSocketName, TTagName>(
	role: "rig" | "addon",
	options: Anatomy.RecognizeOptions<TSocketName, TTagName>
): Anatomy.RecognizeConfig<TSocketName, TTagName>
	return {
		id = options.id,
		category = options.category,
		socketAttribute = options.socketAttribute,
		tagsAttribute = options.tagsAttribute,
		tagDelimiter = options.tagDelimiter,
		tagPathDelimiter = options.tagPathDelimiter,
		socketNameGuard = options.socketNameGuard,
		tagGuard = options.tagGuard,
		instancePolicy = options.instancePolicy,
		metadata = options.metadata,
		role = role,
	}
end

local function recognizeRig<TSocketName, TTagName>(
	root: Instance,
	options: Anatomy.RecognizeOptions<TSocketName, TTagName>
): Anatomy.AnatomyTemplate<TSocketName, TTagName>
	return Anatomy.anatomyTemplate.recognize(root, buildRecognizeConfig("rig", options))
end

local function recognizeAddon<TSocketName, TTagName>(
	root: Instance,
	options: Anatomy.RecognizeOptions<TSocketName, TTagName>
): Anatomy.AnatomyTemplate<TSocketName, TTagName>
	return Anatomy.anatomyTemplate.recognize(root, buildRecognizeConfig("addon", options))
end

local function wrap<TSocketName, TTagName>(
	root: Instance,
	template: Anatomy.AnatomyTemplate<TSocketName, TTagName>
): Anatomy.AnatomyInstance<TSocketName, TTagName>
	return template:wrap(root)
end

local function createHost<TSocketName, TTagName>(
	options: Anatomy.AnatomyHostOptions<TSocketName>?
): Anatomy.AnatomyHost<TSocketName, TTagName>
	return Anatomy.anatomyHost.new(options)
end

local function attach(from: Attachment, to: Attachment, options: Anatomy.SocketMountOptions?): Anatomy.SocketMount
	return Anatomy.socketMount.new(Anatomy.socketEndpoint.fromAttachment(from), Anatomy.socketEndpoint.fromAttachment(to), options)
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldRoot = Workspace:FindFirstChild(DEV_ROOT_NAME)
if oldRoot ~= nil then
	oldRoot:Destroy()
end

local devRoot = Instance.new("Folder")
devRoot.Name = DEV_ROOT_NAME
devRoot.Parent = Workspace

local logLines: { string } = {}
local consoleLabel: TextLabel? = nil
local summaryLabel: TextLabel? = nil

local function countDictionary(dictionary: { [any]: any }): number
	local count = 0
	for _ in dictionary do
		count += 1
	end

	return count
end

local function appendLog(message: string): ()
	print("[AnatomyDev] " .. message)

	table.insert(logLines, message)
	if #logLines > 120 then
		table.remove(logLines, 1)
	end

	local label = consoleLabel
	if label ~= nil then
		label.Text = table.concat(logLines, "\n")
	end
end

local function setSummary(message: string): ()
	local label = summaryLabel
	if label ~= nil then
		label.Text = message
	end
end

local function expect(condition: boolean, message: string): ()
	if not condition then
		error(message, 2)
	end
end

local function expectError(callback: () -> (), message: string): ()
	local ok = pcall(callback)
	if ok then
		error(message, 2)
	end
end

local function makePart(
	name: string,
	size: Vector3,
	color: Color3,
	cframe: CFrame,
	parent: Instance,
	anchored: boolean
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = anchored
	part.CanCollide = true
	part.CanQuery = true
	part.CanTouch = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent

	return part
end

local function addSocket(parent: BasePart, socketName: string, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = socketName .. "Socket"
	attachment.Position = position
	attachment:SetAttribute(SOCKET_ATTRIBUTE, socketName)
	attachment.Parent = parent

	return attachment
end

local function addInternalRigidConstraint(
	name: string,
	part0: BasePart,
	position0: Vector3,
	part1: BasePart,
	position1: Vector3,
	parent: Instance
): RigidConstraint
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = name .. "0"
	attachment0.Position = position0
	attachment0.Parent = part0

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = name .. "1"
	attachment1.Position = position1
	attachment1.Parent = part1

	local rigid = Instance.new("RigidConstraint")
	rigid.Name = name
	rigid.Attachment0 = attachment0
	rigid.Attachment1 = attachment1
	rigid.Parent = parent

	return rigid
end

local function makeRigAsset(name: string, color: Color3, origin: CFrame): Model
	local model = Instance.new("Model")
	model.Name = name

	local torso = makePart("Torso", Vector3.new(3, 3, 2), color, origin, model, true)
	torso:SetAttribute(TAGS_ATTRIBUTE, "part.torso;body.core;body.upper.torso;equip.slots.rightGrip;effect.anchor.body")

	local head = makePart(
		"Head",
		Vector3.new(1.5, 1.5, 1.5),
		color:Lerp(Color3.new(1, 1, 1), 0.2),
		origin * CFrame.new(0, 2.25, 0),
		model,
		false
	)
	head:SetAttribute(TAGS_ATTRIBUTE, "part.head;body.core;body.upper.head;effect.anchor.head")

	addInternalRigidConstraint("HeadToTorso", torso, Vector3.new(0, 1.5, 0), head, Vector3.new(0, -0.75, 0), model)

	addSocket(torso, "rightGrip", Vector3.new(1.75, 0.2, -0.2))
	addSocket(torso, "leftGrip", Vector3.new(-1.75, 0.2, -0.2))
	addSocket(torso, "backMount", Vector3.new(0, 0.6, 1.2))
	addSocket(head, "headTop", Vector3.new(0, 1, 0))

	model.PrimaryPart = torso
	model.Parent = devRoot

	return model
end

local function makeWeaponAsset(name: string, color: Color3, origin: CFrame): Model
	local model = Instance.new("Model")
	model.Name = name

	local handle = makePart("Handle", Vector3.new(0.45, 2.8, 0.45), color, origin, model, false)
	handle:SetAttribute(TAGS_ATTRIBUTE, "part.handle;material.metal.handle;effect.trail.handle;weapon.grip.primary")

	local blade = makePart(
		"Blade",
		Vector3.new(0.65, 3.6, 0.25),
		color:Lerp(Color3.new(1, 1, 1), 0.35),
		origin * CFrame.new(0, 2.5, 0),
		model,
		false
	)
	blade:SetAttribute(TAGS_ATTRIBUTE, "part.blade;material.metal.blade;effect.trail.blade;weapon.edge.primary")

	addInternalRigidConstraint("BladeToHandle", handle, Vector3.new(0, 1.2, 0), blade, Vector3.new(0, -1.3, 0), model)

	addSocket(handle, "weaponGrip", Vector3.new(0, -1.2, 0))
	addSocket(blade, "trailStart", Vector3.new(0, -1.6, 0))
	addSocket(blade, "trailEnd", Vector3.new(0, 1.6, 0))

	model.PrimaryPart = handle
	model.Parent = devRoot

	return model
end

local function makeDuplicateSocketAsset(): Model
	local model = Instance.new("Model")
	model.Name = "DuplicateSocketAsset"

	local part = makePart(
		"SocketCarrier",
		Vector3.new(1, 1, 1),
		Color3.fromRGB(255, 220, 120),
		CFrame.new(-12, 2, 0),
		model,
		true
	)
	addSocket(part, "sameSocket", Vector3.new(0, 0.5, 0))
	addSocket(part, "sameSocket", Vector3.new(0, -0.5, 0))

	model.Parent = devRoot
	return model
end

local function makeBadSocketAsset(): Model
	local model = Instance.new("Model")
	model.Name = "BadSocketAsset"

	local part = makePart(
		"SocketOnPart",
		Vector3.new(1, 1, 1),
		Color3.fromRGB(255, 120, 120),
		CFrame.new(-10, 2, 0),
		model,
		true
	)
	part:SetAttribute(SOCKET_ATTRIBUTE, "badSocket")

	model.Parent = devRoot
	return model
end

local function getSocketAttachment(instance: any, socketName: string): Attachment
	local socket = instance:getSocket(socketName)
	expect(socket ~= nil, "Missing socket " .. socketName)

	local attachment = socket:getAttachment()
	expect(attachment ~= nil, "Missing attachment for socket " .. socketName)

	return attachment :: Attachment
end

local function getBasePart(instance: any, partName: string): BasePart
	local elements = instance:getByTag("part." .. partName)
	expect(#elements == 1, "Expected exactly one tagged anatomy element for part." .. partName)

	local partInstance = elements[1]:getInstance()
	expect(partInstance ~= nil and partInstance:IsA("BasePart"), "Anatomy part " .. partName .. " should resolve a BasePart")

	return partInstance :: BasePart
end

local function getTaggedElementForInstance(elements: { any }, target: Instance): any
	for _, element in elements do
		if element:getInstance() == target then
			return element
		end
	end

	return nil
end

local function pivotRoot(root: Instance, cframe: CFrame): ()
	if root:IsA("PVInstance") then
		(root :: PVInstance):PivotTo(cframe)
	end
end

local function makeTemplate(kind: DevModelKind, name: string, color: Color3, origin: CFrame): any
	local asset = if kind == "rig" then makeRigAsset(name, color, origin) else makeWeaponAsset(name, color, origin)

	if kind == "rig" then
		return recognizeRig(asset, recognizeOptions)
	end

	return recognizeAddon(asset, recognizeOptions)
end

local function makeInstance(kind: DevModelKind, name: string, color: Color3, origin: CFrame, parent: Instance?): any
	local template = makeTemplate(kind, name .. "Template", color, origin)
	local instance = template:instantiate(parent)
	pivotRoot(instance:getRoot(), origin)
	template:getSource():Destroy()

	return instance
end

local function resetAssemblyMotion(root: Instance): ()
	if root:IsA("BasePart") then
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end

	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function parkDemoAnatomy(instance: any): ()
	resetAssemblyMotion(instance:getRoot())
	instance:setParent(nil)
end

local function activateDemoAnatomy(instance: any, cframe: CFrame): ()
	local root = instance:getRoot()
	resetAssemblyMotion(root)
	pivotRoot(root, cframe)
	if root.Parent ~= devRoot then
		instance:setParent(devRoot)
	end
	resetAssemblyMotion(root)
end

local function getDemoRigCFrame(index: number): CFrame
	return DEMO_RIG_ORIGIN * CFrame.new((index - 1) * DEMO_SLOT_SPACING, 0, 0)
end

local function getDemoWeaponCFrame(rigIndex: number): CFrame
	return DEMO_WEAPON_ORIGIN * CFrame.new((rigIndex - 1) * DEMO_SLOT_SPACING, 0, 0)
end

local function runBenchmark(name: string, callback: () -> ()): number
	local startTime = os.clock()
	callback()
	local elapsed = os.clock() - startTime
	appendLog("BENCH " .. name .. ": " .. string.format("%.4f", elapsed) .. "s")

	return elapsed
end

local function testRecognitionAndPolicy(): ()
	local template = makeTemplate("rig", "UnitRigPolicy", Color3.fromRGB(50, 180, 255), CFrame.new(-8, 2, 0))

	expect(template:getRole() == "rig", "Rig template role should be rig")
	expect(countDictionary(template:getSocketDescriptors()) == 4, "Rig should expose four sockets")
	expect(#template:getTagDescriptors() == 2, "Rig should expose two tagged elements")

	local instance = template:instantiate(devRoot)
	local rightGrip = instance:getSocket("rightGrip")
	expect(rightGrip ~= nil, "Instantiated rig should resolve rightGrip")
	expect(rightGrip:getAttachment() ~= nil, "rightGrip should resolve a live Attachment")

	local torsoBasePart = getBasePart(instance, "torso")
	expect(torsoBasePart.CanCollide == false, "Instance policy should disable CanCollide")
	expect(torsoBasePart.CanQuery == false, "Instance policy should disable CanQuery")
	expect(torsoBasePart.CanTouch == false, "Instance policy should disable CanTouch")
	expect(torsoBasePart.CastShadow == false, "Instance policy should disable CastShadow")
	expect(torsoBasePart.EnableFluidForces == false, "Instance policy should disable EnableFluidForces")
	expect(torsoBasePart.Massless == true, "Instance policy should make parts massless")
	expect((torsoBasePart :: any).AudioCanCollide == false, "Instance policy should disable AudioCanCollide")
	expect(torsoBasePart.Anchored == true, "Rig torso should be the anchored physics root")

	local headBasePart = getBasePart(instance, "head")
	expect(headBasePart.Anchored == false, "Rig head should stay unanchored and constrained to the torso")
	expect(instance:getRoot():FindFirstChild("HeadToTorso", true) ~= nil, "Rig should contain an internal head constraint")

	local bodyElements = instance:getByTag("body")
	local upperElements = instance:getByTag("body.upper")
	expect(#bodyElements == 2, "Body tag prefix should resolve torso and head")
	expect(#upperElements == 2, "Nested body.upper tag prefix should resolve torso and head")

	local torsoElement = getTaggedElementForInstance(upperElements, torsoBasePart)
	local headElement = getTaggedElementForInstance(upperElements, headBasePart)
	expect(torsoElement ~= nil, "Nested body tag query should include torso")
	expect(headElement ~= nil, "Nested body tag query should include head")
	expect(torsoElement:hasTag("body.upper.torso"), "Torso should expose its nested body leaf")
	expect(headElement:hasTag("body.upper.head"), "Head should expose its nested body leaf")
	expect(torsoElement:getLeafUnder("body.upper") == "torso", "Torso body.upper leaf should be torso")
	expect(headElement:getLeafUnder("body.upper") == "head", "Head body.upper leaf should be head")
	expect(torsoElement:hasTag("part.torso"), "Torso should expose its named part tag")
	expect(torsoElement:getTags()["equip.slots.rightGrip"] == true, "Torso should expose equipment slot tag")

	instance:deconstruct()
	template:getSource():Destroy()
end

local function testRecognitionGuards(): ()
	local duplicateSocketAsset = makeDuplicateSocketAsset()
	expectError(function()
		recognizeRig(duplicateSocketAsset, recognizeOptions)
	end, "Duplicate sockets should error during recognition")
	duplicateSocketAsset:Destroy()

	local badSocketAsset = makeBadSocketAsset()
	expectError(function()
		recognizeRig(badSocketAsset, recognizeOptions)
	end, "Socket attributes on non-Attachments should error during recognition")
	badSocketAsset:Destroy()
end

local function testWrapAndInstantiateOwnership(): ()
	local source = makeRigAsset("OwnershipRig", Color3.fromRGB(170, 130, 255), CFrame.new(-5, 2, 0))
	local template = recognizeRig(source, recognizeOptions)

	local wrapped = wrap(source, template)
	wrapped:deconstruct()
	expect(source.Parent == devRoot, "Wrapped anatomy deconstruct should not destroy the wrapped root")

	local ownedInstance = template:instantiate(devRoot)
	local ownedRoot = ownedInstance:getRoot()
	ownedInstance:deconstruct()
	expect(ownedRoot.Parent == nil, "Instantiated anatomy deconstruct should destroy the cloned root")

	source:Destroy()
end

local function testStaticAttach(): ()
	local rig = makeInstance("rig", "StaticRig", Color3.fromRGB(80, 200, 150), CFrame.new(-2, 2, 0), devRoot)
	local weapon = makeInstance(
		"weapon",
		"StaticWeapon",
		Color3.fromRGB(240, 90, 90),
		CFrame.new(-0.5, 2, 0),
		devRoot
	)

	local rigAttachment = getSocketAttachment(rig, "rightGrip")
	local weaponAttachment = getSocketAttachment(weapon, "weaponGrip")
	local handle = getBasePart(weapon, "handle")
	local blade = getBasePart(weapon, "blade")
	expect(handle.Anchored == false, "Weapon handle should be unanchored before mounting")
	expect(blade.Anchored == false, "Weapon blade should be unanchored before mounting")
	expect(weapon:getRoot():FindFirstChild("BladeToHandle", true) ~= nil, "Weapon should contain an internal blade constraint")

	local mount = attach(weaponAttachment, rigAttachment, {
		name = "StaticAttach",
		parent = devRoot :: Instance,
	})

	expect(mount:isConnected(), "Static attach should connect once both attachments exist")
	expect(mount:getFromAttachment() == weaponAttachment, "Static mount from attachment mismatch")
	expect(mount:getToAttachment() == rigAttachment, "Static mount to attachment mismatch")

	local constraint = mount:getConstraint()
	expect(constraint ~= nil, "Static attach should create a RigidConstraint")
	local rigid = constraint :: RigidConstraint
	expect(rigid.Attachment0 == weaponAttachment, "RigidConstraint Attachment0 mismatch")
	expect(rigid.Attachment1 == rigAttachment, "RigidConstraint Attachment1 mismatch")

	mount:deconstruct()
	expect(rigid.Parent == nil, "Static mount deconstruct should destroy its constraint")

	rig:deconstruct()
	weapon:deconstruct()
end

local function testHostReactiveSocketsAndMounts(): ()
	local host = createHost({
		id = "ReactiveUnitHost",
	})

	local rigA = makeInstance("rig", "ReactiveRigA", Color3.fromRGB(75, 155, 255), CFrame.new(2, 2, 0), devRoot)
	local rigB = makeInstance("rig", "ReactiveRigB", Color3.fromRGB(255, 170, 60), CFrame.new(5, 2, 0), devRoot)
	local weaponA = makeInstance("weapon", "ReactiveWeaponA", Color3.fromRGB(255, 80, 120), CFrame.new(3, 2, 0), devRoot)
	local weaponB = makeInstance("weapon", "ReactiveWeaponB", Color3.fromRGB(100, 245, 130), CFrame.new(6, 2, 0), devRoot)

	host:push(rigA, {
		id = "rig",
		priority = 0,
	})
	host:push(weaponA, {
		id = "weapon",
		priority = 10,
	})

	local rightGripBinding = host:socket("rightGrip")
	local weaponGripBinding = host:socket("weaponGrip", {
		layerId = "weapon",
	})

	local attachmentChangeCount = 0
	local disconnectAttachmentChanged = rightGripBinding:bindAttachmentChanged(function(_attachment: Attachment?)
		attachmentChangeCount += 1
	end, true)

	local bodyTagAddCount = 0
	local bodyTagRemoveCount = 0
	local lastAddedBodyElement: any? = nil
	local lastRemovedBodyElement: any? = nil
	local disconnectBodyTags = host:bindByTag("body.upper", function(element: any)
		bodyTagAddCount += 1
		lastAddedBodyElement = element
		expect(element:hasTag("body.upper"), "Body tag add should come from the nested body prefix")
	end, function(element: any)
		bodyTagRemoveCount += 1
		lastRemovedBodyElement = element
		expect(element:hasTag("body.upper"), "Body tag remove should come from the nested body prefix")
	end, true)

	local trailTagAddCount = 0
	local trailTagRemoveCount = 0
	local lastAddedTrailElement: any? = nil
	local lastRemovedTrailElement: any? = nil
	local disconnectTrailTags = host:bindByTag("effect.trail", function(element: any)
		trailTagAddCount += 1
		lastAddedTrailElement = element
		expect(element:hasTag("effect.trail"), "Trail tag add should come from the nested trail prefix")
	end, function(element: any)
		trailTagRemoveCount += 1
		lastRemovedTrailElement = element
		expect(element:hasTag("effect.trail"), "Trail tag remove should come from the nested trail prefix")
	end, true)

	local mount = host:mount({
		from = {
			socket = "weaponGrip",
			layerId = "weapon",
		},
		to = {
			socket = "rightGrip",
		},
		options = {
			name = "ReactiveWeaponMount",
			parent = devRoot :: Instance,
		},
	})

	expect(rightGripBinding:getAttachment() == getSocketAttachment(rigA, "rightGrip"), "Host should expose rig A rightGrip")
	expect(weaponGripBinding:getAttachment() == getSocketAttachment(weaponA, "weaponGrip"), "Host should expose weapon A grip")
	expect(#host:getByTag("body") == 2, "Host should expose two rig body-tagged elements")
	expect(#host:getByTag("body.upper") == 2, "Host should expose two nested body elements")
	expect(#host:getByTag("material.metal") == 2, "Host should expose two nested metal weapon elements")
	expect(#host:getByTag("effect.trail") == 2, "Host should expose two nested trail weapon elements")
	expect(#host:getByTag("material.metal", {
		layerId = "weapon",
	}) == 2, "Layer tag query should expose only weapon metal elements")
	expect(bodyTagAddCount == 2, "Body tag binding should run initially for torso and head")
	expect(bodyTagRemoveCount == 0, "Body tag binding should not report removals initially")
	expect(trailTagAddCount == 2, "Trail tag binding should run initially for handle and blade")
	expect(trailTagRemoveCount == 0, "Trail tag binding should not report removals initially")
	expect(lastAddedBodyElement ~= nil and lastAddedBodyElement:hasTag("body.upper"), "Initial body tag add should be nested")
	expect(
		lastAddedTrailElement ~= nil and lastAddedTrailElement:hasTag("effect.trail"),
		"Initial trail tag add should be nested"
	)
	expect(mount:isConnected(), "Reactive host mount should connect initially")

	host:remove("weapon")
	expect(#host:getByTag("effect.trail") == 0, "Trail tag prefix should clear when weapon layer is removed")
	expect(trailTagRemoveCount == 2, "Trail tag binding should fire for handle and blade removal")
	expect(
		lastRemovedTrailElement ~= nil and lastRemovedTrailElement:hasTag("effect.trail"),
		"Removed trail tag should still describe the removed element"
	)
	host:push(weaponB, {
		id = "weapon",
		priority = 10,
	})
	expect(weaponGripBinding:getAttachment() == getSocketAttachment(weaponB, "weaponGrip"), "Weapon binding should follow weapon layer swap")
	expect(mount:getFromAttachment() == getSocketAttachment(weaponB, "weaponGrip"), "Reactive mount should follow weapon layer swap")
	expect(#host:getByTag("material.metal") == 2, "Host metal tag prefix should follow weapon layer swap")
	expect(#host:getByTag("effect.trail") == 2, "Host trail tag prefix should follow weapon layer swap")
	expect(trailTagAddCount == 4, "Trail tag binding should fire when weapon B is pushed")
	expect(
		lastAddedTrailElement ~= nil and lastAddedTrailElement:hasTag("effect.trail"),
		"Added trail tag should still describe the added element"
	)

	host:remove("rig")
	expect(#host:getByTag("body") == 0, "Host body tag prefix should clear when rig layer is removed")
	expect(#host:getByTag("body.upper") == 0, "Host nested body tag prefix should clear when rig layer is removed")
	expect(bodyTagRemoveCount == 2, "Body tag binding should fire for torso and head removal")
	expect(
		lastRemovedBodyElement ~= nil and lastRemovedBodyElement:hasTag("body.upper"),
		"Removed body tag should still describe the removed element"
	)
	host:push(rigB, {
		id = "rig",
		priority = 0,
	})
	expect(rightGripBinding:getAttachment() == getSocketAttachment(rigB, "rightGrip"), "Rig binding should follow rig layer swap")
	expect(mount:getToAttachment() == getSocketAttachment(rigB, "rightGrip"), "Reactive mount should follow rig layer swap")
	expect(#host:getByTag("body") == 2, "Host body tag prefix should follow rig layer swap")
	expect(#host:getByTag("body.upper") == 2, "Host nested body tag prefix should follow rig layer swap")
	expect(bodyTagAddCount == 4, "Body tag binding should fire when rig B is pushed")
	expect(lastAddedBodyElement ~= nil and lastAddedBodyElement:hasTag("body.upper"), "Added body tag should be nested")
	expect(attachmentChangeCount >= 2, "Right grip binding should report initial and swapped attachments")

	disconnectAttachmentChanged()
	disconnectBodyTags()
	disconnectTrailTags()
	rightGripBinding:deconstruct()
	weaponGripBinding:deconstruct()
	host:deconstruct()
	rigA:deconstruct()
	rigB:deconstruct()
	weaponA:deconstruct()
	weaponB:deconstruct()
end

local function testOverrideResolution(): ()
	local host = createHost({
		id = "OverrideHost",
	})

	local baseRig = makeInstance("rig", "OverrideRig", Color3.fromRGB(90, 160, 255), CFrame.new(8, 2, 0), devRoot)
	local addonOverride = makeInstance(
		"rig",
		"OverrideAddon",
		Color3.fromRGB(255, 90, 220),
		CFrame.new(10, 2, 0),
		devRoot
	)

	host:push(baseRig, {
		id = "base",
		priority = 0,
	})
	host:push(addonOverride, {
		id = "override",
		priority = 10,
		allowSocketOverrides = true,
	})

	expect(host:getSocket("rightGrip") == addonOverride:getSocket("rightGrip"), "Higher priority layer should override sockets by default")
	expect(
		host:getSocket("rightGrip", {
			includeOverrides = false,
		}) == baseRig:getSocket("rightGrip"),
		"includeOverrides=false should resolve the base socket"
	)

	host:deconstruct()
	baseRig:deconstruct()
	addonOverride:deconstruct()
end

local tests: { TestDefinition } = {
	{
		name = "recognition descriptors + instance policy",
		run = testRecognitionAndPolicy,
	},
	{
		name = "recognition guard rails",
		run = testRecognitionGuards,
	},
	{
		name = "wrap vs instantiate ownership",
		run = testWrapAndInstantiateOwnership,
	},
	{
		name = "static attachment mount",
		run = testStaticAttach,
	},
	{
		name = "host reactive sockets + tags + mounts",
		run = testHostReactiveSocketsAndMounts,
	},
	{
		name = "host override resolution",
		run = testOverrideResolution,
	},
}

local function runTests(): ()
	appendLog("Running anatomy dev tests...")

	local passed = 0
	local failed = 0
	local startedAt = os.clock()

	for _, test in tests do
		local ok, err = pcall(function()
			test.run()
			return nil
		end)
		if ok then
			passed += 1
			appendLog("PASS " .. test.name)
		else
			failed += 1
			appendLog("FAIL " .. test.name .. ": " .. tostring(err))
		end
	end

	local elapsed = os.clock() - startedAt
	local summary = "Tests: "
		.. tostring(passed)
		.. " passed, "
		.. tostring(failed)
		.. " failed in "
		.. string.format("%.4f", elapsed)
		.. "s"
	appendLog(summary)
	setSummary(summary)
end

local function runStressBenchmark(count: number): ()
	local benchmarkFolder = Instance.new("Folder")
	benchmarkFolder.Name = "Benchmark_" .. tostring(count)
	benchmarkFolder.Parent = devRoot

	local rigTemplate = makeTemplate("rig", "BenchmarkRigTemplate", Color3.fromRGB(90, 160, 255), CFrame.new(0, 50, 0))
	local weaponTemplate = makeTemplate(
		"weapon",
		"BenchmarkWeaponTemplate",
		Color3.fromRGB(255, 90, 100),
		CFrame.new(0, 50, 4)
	)

	local rigInstances: { any } = {}
	local weaponInstances: { any } = {}

	runBenchmark("instantiate " .. tostring(count) .. " rigs + " .. tostring(count) .. " weapons", function()
		for index = 1, count do
			local rig = rigTemplate:instantiate(benchmarkFolder)
			local weapon = weaponTemplate:instantiate(benchmarkFolder)

			local x = (index % 30) * 1.5
			local z = math.floor(index / 30) * 1.5
			pivotRoot(rig:getRoot(), CFrame.new(x, 20, z))
			pivotRoot(weapon:getRoot(), CFrame.new(x + 0.8, 20, z))

			table.insert(rigInstances, rig)
			table.insert(weaponInstances, weapon)
		end
	end)

	runBenchmark("create + destroy " .. tostring(count) .. " static mounts", function()
		local mounts: { any } = table.create(count)
		for index = 1, count do
			mounts[index] = attach(
				getSocketAttachment(weaponInstances[index], "weaponGrip"),
				getSocketAttachment(rigInstances[index], "rightGrip"),
				{
					parent = benchmarkFolder :: Instance,
				}
			)
		end

		for _, mount in mounts do
			mount:deconstruct()
		end
	end)

	runBenchmark("swap host layers " .. tostring(count) .. " times", function()
		local host = createHost({
			id = "BenchmarkHost",
		})
		host:push(rigInstances[1], {
			id = "rig",
			priority = 0,
		})
		host:push(weaponInstances[1], {
			id = "weapon",
			priority = 10,
		})

		local mount = host:mount({
			from = {
				socket = "weaponGrip",
				layerId = "weapon",
			},
			to = {
				socket = "rightGrip",
			},
			options = {
				parent = benchmarkFolder :: Instance,
			},
		})

		for index = 1, count do
			local rigIndex = ((index - 1) % #rigInstances) + 1
			local weaponIndex = ((index - 1) % #weaponInstances) + 1

			host:remove("rig")
			host:push(rigInstances[rigIndex], {
				id = "rig",
				priority = 0,
			})

			host:remove("weapon")
			host:push(weaponInstances[weaponIndex], {
				id = "weapon",
				priority = 10,
			})
		end

		expect(mount:isConnected(), "Benchmark reactive mount should stay connected after swaps")
		host:deconstruct()
	end)

	for _, rig in rigInstances do
		rig:deconstruct()
	end
	for _, weapon in weaponInstances do
		weapon:deconstruct()
	end
	rigTemplate:getSource():Destroy()
	weaponTemplate:getSource():Destroy()
	benchmarkFolder:Destroy()
end

local demoState: DemoState = {
	host = nil,
	reactiveMount = nil,
	directMount = nil,
	rigInstances = {},
	weaponInstances = {},
	activeRigIndex = 1,
	activeWeaponIndex = 1,
	mountedRigIndex = nil,
	mountedWeaponIndex = nil,
}

local function refreshDemoLayers(): ()
	local host = demoState.host
	if host == nil then
		return
	end

	local directMount = demoState.directMount
	if directMount ~= nil then
		directMount:deconstruct()
		demoState.directMount = nil
	end

	local rig = demoState.rigInstances[demoState.activeRigIndex]
	local weapon = demoState.weaponInstances[demoState.activeWeaponIndex]

	for index, weaponInstance in demoState.weaponInstances do
		if index ~= demoState.activeWeaponIndex then
			parkDemoAnatomy(weaponInstance)
		end
	end

	activateDemoAnatomy(weapon, getDemoWeaponCFrame(demoState.activeRigIndex))

	if demoState.mountedRigIndex ~= demoState.activeRigIndex then
		host:remove("rig")
		host:push(rig, {
			id = "rig",
			priority = 0,
		})
		demoState.mountedRigIndex = demoState.activeRigIndex
	end

	if demoState.mountedWeaponIndex ~= demoState.activeWeaponIndex then
		host:remove("weapon")
		host:push(weapon, {
			id = "weapon",
			priority = 10,
		})
		demoState.mountedWeaponIndex = demoState.activeWeaponIndex
	end
end

local function setupDemo(): ()
	local host = createHost({
		id = "InteractiveDemoHost",
	})
	demoState.host = host
	demoState.rigInstances = {
		makeInstance("rig", "DemoRigBlue", Color3.fromRGB(60, 145, 255), getDemoRigCFrame(1), devRoot),
		makeInstance("rig", "DemoRigGold", Color3.fromRGB(245, 180, 55), getDemoRigCFrame(2), devRoot),
	}
	demoState.weaponInstances = {
		makeInstance("weapon", "DemoWeaponRed", Color3.fromRGB(255, 80, 100), getDemoWeaponCFrame(1), nil),
		makeInstance("weapon", "DemoWeaponGreen", Color3.fromRGB(70, 230, 120), getDemoWeaponCFrame(2), nil),
	}

	refreshDemoLayers()
	demoState.reactiveMount = host:mount({
		from = {
			socket = "weaponGrip",
			layerId = "weapon",
		},
		to = {
			socket = "rightGrip",
		},
		options = {
			name = "InteractiveReactiveMount",
			parent = devRoot :: Instance,
		},
	})

	appendLog("Interactive demo ready. Swap rig or weapon to watch the reactive mount retarget.")
end

local function swapRig(): ()
	demoState.activeRigIndex = (demoState.activeRigIndex % #demoState.rigInstances) + 1
	refreshDemoLayers()
	appendLog("Demo rig swapped to index " .. tostring(demoState.activeRigIndex))
end

local function swapWeapon(): ()
	demoState.activeWeaponIndex = (demoState.activeWeaponIndex % #demoState.weaponInstances) + 1
	refreshDemoLayers()
	appendLog("Demo weapon swapped to index " .. tostring(demoState.activeWeaponIndex))
end

local function attachStaticDemo(): ()
	local directMount = demoState.directMount
	if directMount ~= nil then
		directMount:deconstruct()
	end

	local rig = demoState.rigInstances[demoState.activeRigIndex]
	local weapon = demoState.weaponInstances[demoState.activeWeaponIndex]
	demoState.directMount = attach(getSocketAttachment(weapon, "weaponGrip"), getSocketAttachment(rig, "leftGrip"), {
		name = "InteractiveStaticMount",
		parent = devRoot :: Instance,
	})
	appendLog("Static demo mount attached weaponGrip to leftGrip.")
end

local function rebuildReactiveDemoMount(): ()
	local reactiveMount = demoState.reactiveMount
	if reactiveMount ~= nil then
		reactiveMount:deconstruct()
	end

	local host = demoState.host
	if host == nil then
		return
	end

	demoState.reactiveMount = host:mount({
		from = {
			socket = "weaponGrip",
			layerId = "weapon",
		},
		to = {
			socket = "rightGrip",
		},
		options = {
			name = "InteractiveReactiveMount",
			parent = devRoot :: Instance,
		},
	})
	appendLog("Reactive demo mount rebuilt.")
end

local function makeButton(parent: Instance, text: string, layoutOrder: number, callback: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%s+", "")
	button.Size = UDim2.new(0, 142, 0, 30)
	button.LayoutOrder = layoutOrder
	button.BackgroundColor3 = Color3.fromRGB(38, 42, 50)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.Text = text
	button.TextColor3 = Color3.fromRGB(235, 240, 245)
	button.TextSize = 13
	button.Parent = parent
	button.Activated:Connect(callback)

	return button
end

local function buildUi(): ()
	local oldGui = playerGui:FindFirstChild("AnatomyDevHarness")
	if oldGui ~= nil then
		oldGui:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AnatomyDevHarness"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 1)
	panel.Position = UDim2.new(0, 16, 1, -16)
	panel.Size = UDim2.new(0, 620, 0, 310)
	panel.BackgroundColor3 = Color3.fromRGB(18, 21, 26)
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(14, 10)
	title.Size = UDim2.new(1, -28, 0, 24)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "Anatomy Dev Harness"
	title.TextColor3 = Color3.fromRGB(245, 248, 252)
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel

	local summary = Instance.new("TextLabel")
	summary.Name = "Summary"
	summary.Position = UDim2.fromOffset(14, 36)
	summary.Size = UDim2.new(1, -28, 0, 24)
	summary.BackgroundTransparency = 1
	summary.Font = Enum.Font.Gotham
	summary.Text = "Waiting for test results..."
	summary.TextColor3 = Color3.fromRGB(180, 190, 205)
	summary.TextSize = 13
	summary.TextXAlignment = Enum.TextXAlignment.Left
	summary.Parent = panel
	summaryLabel = summary

	local buttonBar = Instance.new("Frame")
	buttonBar.Name = "Buttons"
	buttonBar.Position = UDim2.fromOffset(14, 68)
	buttonBar.Size = UDim2.new(1, -28, 0, 70)
	buttonBar.BackgroundTransparency = 1
	buttonBar.Parent = panel

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.fromOffset(142, 30)
	layout.CellPadding = UDim2.fromOffset(8, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = buttonBar

	makeButton(buttonBar, "Run Tests", 1, runTests)
	makeButton(buttonBar, "Stress 300", 2, function()
		runStressBenchmark(300)
	end)
	makeButton(buttonBar, "Swap Rig", 3, swapRig)
	makeButton(buttonBar, "Swap Weapon", 4, swapWeapon)
	makeButton(buttonBar, "Static Attach", 5, attachStaticDemo)
	makeButton(buttonBar, "Reactive Attach", 6, rebuildReactiveDemoMount)

	local console = Instance.new("TextLabel")
	console.Name = "Console"
	console.Position = UDim2.fromOffset(14, 146)
	console.Size = UDim2.new(1, -28, 1, -160)
	console.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
	console.BorderSizePixel = 0
	console.Font = Enum.Font.Code
	console.Text = ""
	console.TextColor3 = Color3.fromRGB(210, 220, 230)
	console.TextSize = 12
	console.TextXAlignment = Enum.TextXAlignment.Left
	console.TextYAlignment = Enum.TextYAlignment.Top
	console.TextWrapped = true
	console.Parent = panel
	consoleLabel = console
end

buildUi()
setupDemo()
runTests()
