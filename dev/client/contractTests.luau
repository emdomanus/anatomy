--!strict
--!optimize 2

local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)

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
	testExplicitMount()
	require(script.Parent.sourceContractTests)()
end

return run
