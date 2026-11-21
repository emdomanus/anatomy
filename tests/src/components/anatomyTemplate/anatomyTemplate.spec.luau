--!strict
--!optimize 2
-- anatomyTemplate through the package entry: what it reads from an element table, what it rejects,
-- and that the data it returns is frozen.
local Anatomy = require("../../../../src/shared")

type AnatomyElement = Anatomy.AnatomyElement

local function case(name: string, body: () -> ()): ()
	body()
	print("PASS " .. name)
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

local function expectList(actual: { read [number]: string | number }, expected: string): ()
	local text = table.concat(actual :: { string | number }, ",")
	assert(text == expected, `expected {expected}, got {text}`)
end

case("sockets and tag prefixes are read by element index from the two named attributes", function()
	local elements: { AnatomyElement } = {
		{ authoredAttributes = {} },
		{ authoredAttributes = { Socket = "body.head", Surface = "body.head; skin" } },
		{ authoredAttributes = { Other = "body.torso", Surface = "" } },
		{ authoredAttributes = { Socket = "mount_1", Surface = "body.arm.left;body.arm.right;;" } },
		{ authoredAttributes = { Surface = "skin" } },
	}
	local anatomyTemplate = Anatomy.anatomyTemplate.new(elements, "Socket", "Surface")

	expectList(anatomyTemplate.socketNames, "body.head,mount_1")
	assert(anatomyTemplate.socketElementIndexByName["body.head"] == 2, "body.head is element 2")
	assert(anatomyTemplate.socketElementIndexByName["mount_1"] == 4, "mount_1 is element 4")
	assert(
		anatomyTemplate.socketElementIndexByName["body.torso"] == nil,
		"another attribute is not read"
	)

	-- Every prefix of every tag, in the order the table first shows it. An entry is trimmed of
	-- surrounding spaces and an empty entry is skipped.
	expectList(
		anatomyTemplate.taggedPrefixes,
		"body,body.head,skin,body.arm,body.arm.left,body.arm.right"
	)
	expectList(anatomyTemplate.taggedElementIndexesByPrefix["body.head"], "2")
	expectList(anatomyTemplate.taggedElementIndexesByPrefix["skin"], "2,5")
	-- Element 4 has two tags under "body" and under "body.arm": it is listed once under each.
	expectList(anatomyTemplate.taggedElementIndexesByPrefix["body"], "2,4")
	expectList(anatomyTemplate.taggedElementIndexesByPrefix["body.arm"], "4")
	expectList(anatomyTemplate.taggedElementIndexesByPrefix["body.arm.right"], "4")
	assert(
		anatomyTemplate.taggedElementIndexesByPrefix["body.ar"] == nil,
		"a prefix is whole segments"
	)

	local empty = Anatomy.anatomyTemplate.new({}, "Socket", "Surface")
	assert(#empty.socketNames == 0 and #empty.taggedPrefixes == 0, "an empty table has nothing")
end)

case("the template and every table in it is frozen", function()
	local anatomyTemplate = Anatomy.anatomyTemplate.new({
		{ authoredAttributes = { Socket = "body.head", Surface = "skin" } },
	}, "Socket", "Surface")
	assert(table.isfrozen(anatomyTemplate), "the template")
	assert(table.isfrozen(anatomyTemplate.socketNames), "socketNames")
	assert(table.isfrozen(anatomyTemplate.socketElementIndexByName), "socketElementIndexByName")
	assert(table.isfrozen(anatomyTemplate.taggedPrefixes), "taggedPrefixes")
	assert(
		table.isfrozen(anatomyTemplate.taggedElementIndexesByPrefix),
		"taggedElementIndexesByPrefix"
	)
	assert(table.isfrozen(anatomyTemplate.taggedElementIndexesByPrefix["skin"]), "an index array")
end)

case(
	"a name that is not dotted segments, a wrong attribute type and a repeated socket are refused",
	function()
		local function build(socketName: unknown, tags: unknown): ()
			Anatomy.anatomyTemplate.new({
				{ authoredAttributes = {} },
				{ authoredAttributes = { Socket = socketName, Surface = tags } },
			}, "Socket", "Surface")
		end
		for _, socketName in
			{ "", "body..head", ".body", "body.", "body head", "body-head", " body" }
		do
			expectRaise(function()
				build(socketName, nil)
			end, "Anatomy element 2")
		end
		expectRaise(function()
			build(12, nil)
		end, 'attribute "Socket" must be a socket name')
		for _, tags in { "body..head", "skin;body head", "a.b;.c" } do
			expectRaise(function()
				build(nil, tags)
			end, "Anatomy element 2: tag")
		end
		expectRaise(function()
			build(nil, true)
		end, 'attribute "Surface" must be a string')
		expectRaise(function()
			Anatomy.anatomyTemplate.new({
				{ authoredAttributes = { Socket = "body.head" } },
				{ authoredAttributes = {} },
				{ authoredAttributes = { Socket = "body.head" } },
			}, "Socket", "Surface")
		end, 'Anatomy element 3: socket "body.head" is already on element 1')
		-- Letters, digits and "_" are a segment.
		build("Body_2.head_L", "A1.b_2")
	end
)
