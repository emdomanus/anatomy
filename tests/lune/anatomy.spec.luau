--!strict
--!optimize 2

-- Executes actual package modules in memory. Roblox datatypes are supplied by Lune;
-- this verifies ownership/guard behavior, not Studio physics or engine scheduling.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local root = {}
local paths = {}
local nodesByPath = {}
local loaded = {}

local function register(directory, parent)
	for _, entry in fs.readDir(directory) do
		local path = directory .. "/" .. entry
		if fs.isDir(path) then
			local node = { Parent = parent }
			parent[entry] = node
			nodesByPath[path] = node
			register(path, node)
		elseif string.sub(entry, -5) == ".luau" then
			local name = string.sub(entry, 1, -6)
			local node = if name == "init" then parent else { Parent = parent }
			if name ~= "init" then
				parent[name] = node
			end
			paths[node] = path
			nodesByPath[path] = node
		end
	end
end

for _, directory in { "src", "roblox_packages", "dev" } do
	root[directory] = { Parent = root }
	nodesByPath[directory] = root[directory]
	register(directory, root[directory])
end

local function normalize(path)
	local result = {}
	for _, part in string.split(path, "/") do
		if part == ".." then
			table.remove(result)
		elseif part ~= "." and part ~= "" then
			table.insert(result, part)
		end
	end
	return table.concat(result, "/")
end

local gameTree = { ReplicatedStorage = { packages = { anatomy = { src = root.src } } } }
-- Lune 0.10.5 cannot clear a reflected Ref property to nil. Model only the
-- constraint property sink here; no headless assertion claims engine physics.
local instanceFactory = {
	new = function(className)
		if className == "RigidConstraint" then
			return {
				Destroy = function(self)
					self.Parent = nil
				end,
			}
		end
		return roblox.Instance.new(className)
	end,
}
local function loadModule(node)
	if loaded[node] ~= nil then
		return loaded[node]
	end
	local path = assert(paths[node], "Missing module path")
	local result = luau.load(fs.readFile(path), {
		debugName = "@" .. path,
		environment = {
			script = node,
			Instance = instanceFactory,
			game = gameTree,
			require = function(target)
				if type(target) == "string" then
					local parentPath = string.match(path, "^(.*)/[^/]+$") or "."
					local targetPath = normalize(parentPath .. "/" .. target)
					target = assert(
						nodesByPath[targetPath] or nodesByPath[targetPath .. ".luau"],
						"Missing dependency " .. targetPath
					)
				end
				return loadModule(target)
			end,
		},
		injectGlobals = true,
	})()
	loaded[node] = result
	return result
end

local Anatomy = loadModule(root.src)
loadModule(root.dev.client.contractTests)()

local function guardString(value: unknown): string
	assert(type(value) == "string", "Expected string")
	return value
end
local function count(entries)
	local result = 0
	for _ in entries do
		result += 1
	end
	return result
end

local bindMountSockets = loadModule(root.dev.client.bindMountSockets)
local host = Anatomy.anatomyHost.new({ socketNameGuard = guardString, tagGuard = guardString })
for _ = 1, 20 do
	local mount = host:mount(nil, nil)
	local disconnectMount = bindMountSockets(mount, host, "from", "to")
	assert(count(host._socketChangedCallbacks) == 0, "Direct subscriptions used the global stream")
	assert(count(host._socketCallbacksByName) == 2, "Missing direct subscriptions")
	disconnectMount()
	disconnectMount()
	mount:deconstruct()
	mount:deconstruct()
	assert(count(host._socketCallbacksByName) == 0, "Direct subscription buckets leaked")
end
host:deconstruct()
print("PASS: explicit mounts, direct subscriptions, source contracts and lifecycle (20 cycles)")
