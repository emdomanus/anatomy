--!strict
--!optimize 2
--!native

local DefTypes = require(script.Parent.Parent.types.def)

export type AnatomyPath = DefTypes.AnatomyPath
export type AnatomyPathStep = DefTypes.AnatomyPathStep

local Path = {}

local function getOrdinal(instance: Instance): number
	local parent = instance.Parent
	if parent == nil then
		return 1
	end

	local ordinal = 0
	for _, sibling in parent:GetChildren() do
		if sibling.Name == instance.Name and sibling.ClassName == instance.ClassName then
			ordinal += 1
		end

		if sibling == instance then
			return ordinal
		end
	end

	return 1
end

function Path.fromRoot(root: Instance, target: Instance): AnatomyPath
	if root == target then
		return {}
	end

	local reversedPath = {}
	local current: Instance? = target

	while current ~= nil and current ~= root do
		table.insert(reversedPath, {
			name = current.Name,
			className = current.ClassName,
			ordinal = getOrdinal(current),
		})

		current = current.Parent
	end

	if current ~= root then
		error(`Anatomy path target {target:GetFullName()} is not below root {root:GetFullName()}`, 2)
	end

	local path = table.create(#reversedPath)
	for index = #reversedPath, 1, -1 do
		table.insert(path, reversedPath[index])
	end

	return path
end

function Path.resolve(root: Instance, path: AnatomyPath): Instance?
	local current: Instance = root

	for _, step: AnatomyPathStep in path do
		local ordinal = step.ordinal or 1
		local seen = 0
		local nextInstance: Instance? = nil

		for _, child in current:GetChildren() do
			if child.Name ~= step.name then
				continue
			end

			if step.className ~= nil and child.ClassName ~= step.className then
				continue
			end

			seen += 1
			if seen == ordinal then
				nextInstance = child
				break
			end
		end

		if nextInstance == nil then
			return nil
		end

		current = nextInstance
	end

	return current
end

return Path
