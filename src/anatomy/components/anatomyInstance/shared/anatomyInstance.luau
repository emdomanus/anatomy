--!strict
--!optimize 2

local AnatomySocket = require(script.Parent.Parent.Parent.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElement =
	require(script.Parent.Parent.Parent.anatomyTaggedElement.shared.anatomyTaggedElement)
local AnatomyPath = require(script.Parent.Parent.Parent.Parent.utils.anatomyPath.shared.anatomyPath)
local AnatomySocketTypes =
	require(script.Parent.Parent.Parent.Parent.types.components.anatomySocket.shared.anatomySocket)
local AnatomyTaggedElementTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTaggedElement.shared.anatomyTaggedElement
)
local AnatomyTemplateTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyTemplate.shared.anatomyTemplate
)
local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.types.def.anatomy.shared.anatomy)
local AnatomyInstanceTypes = require(
	script.Parent.Parent.Parent.Parent.types.components.anatomyInstance.shared.anatomyInstance
)

type AnatomyTaggedElementOwned<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElementOwned<TagT>
type AnatomyInstanceOptions<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstanceOptions<
	SocketT,
	TagT
>
type AnatomySocketOwned<SocketT> = AnatomySocketTypes.AnatomySocketOwned<SocketT>

type AnatomyCategory = AnatomyInstanceTypes.AnatomyCategory
type AnatomyId = AnatomyInstanceTypes.AnatomyId
type AnatomyTemplate<SocketT, TagT> = AnatomyTemplateTypes.AnatomyTemplate<SocketT, TagT>
type AnatomyInstance<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstance<
	AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
type AnatomyInstanceImpl<SocketT, TagT> = AnatomyInstanceTypes.AnatomyInstanceImpl<
	AnatomyTemplate<SocketT, TagT>,
	SocketT,
	TagT
>
type AnatomySocket<SocketT> = AnatomySocketTypes.AnatomySocket<SocketT>
type AnatomyTaggedElement<TagT> = AnatomyTaggedElementTypes.AnatomyTaggedElement<TagT>
type DescriptorMetadata = AnatomyInstanceTypes.DescriptorMetadata
type InstancePolicy = AnatomyInstanceTypes.InstancePolicy
type SocketDescriptor<SocketT> = AnatomyInstanceTypes.SocketDescriptor<SocketT>
type TagDescriptor<TagT> = AnatomyInstanceTypes.TagDescriptor<TagT>
type AnatomyPath = AnatomyTypes.AnatomyPath
type RecognizeConfig<SocketT, TagT> = AnatomyTypes.RecognizeConfig<SocketT, TagT>

local function forRootAndDescendants(root: Instance, callback: (Instance) -> ()): ()
	callback(root)
	for _, descendant in root:GetDescendants() do
		callback(descendant)
	end
end

local function addTaggedElementToIndex<TagT>(
	tagPrefixIndex: { [string]: { AnatomyTaggedElementOwned<TagT> } },
	element: AnatomyTaggedElementOwned<TagT>,
	prefixes: { [string]: true }
): ()
	for prefix in prefixes do
		local elements = tagPrefixIndex[prefix]
		if elements == nil then
			elements = {}
			tagPrefixIndex[prefix] = elements
		end

		table.insert(elements, element)
	end
end

local AnatomyInstance = {}
AnatomyInstance.__index = AnatomyInstance

function AnatomyInstance.new<SocketT, TagT>(
	template: AnatomyTemplate<SocketT, TagT>,
	root: Instance,
	ownsRoot: boolean?,
	options: AnatomyInstanceOptions<SocketT, TagT>
): AnatomyInstance<SocketT, TagT>
	local self: AnatomyInstanceImpl<SocketT, TagT> =
		setmetatable({}, AnatomyInstance) :: AnatomyInstanceImpl<SocketT, TagT>

	self._template = template
	self._root = root
	self._id = template:getId()
	self._category = template:getCategory()
	self._metadata = template:getMetadata()
	self._ownsRoot = ownsRoot == true
	self._tagPathDelimiter = options.tagPathDelimiter

	self._sockets = {}
	self._taggedElements = {}
	self._tagPrefixIndex = {}
	self._destroyed = false

	for name, descriptor in options.socketDescriptors do
		self._sockets[name] = self:_buildSocket(descriptor)
	end

	for _, descriptor in options.tagDescriptors do
		local element = self:_buildTaggedElement(descriptor)
		table.insert(self._taggedElements, element)
		addTaggedElementToIndex(self._tagPrefixIndex, element, descriptor.prefixes)
	end

	if options.instancePolicy then
		self:applyInstancePolicy(options.instancePolicy)
	end

	return self
end

function AnatomyInstance.getId<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): AnatomyId?
	return self._id
end

function AnatomyInstance.getCategory<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): AnatomyCategory?
	return self._category
end

function AnatomyInstance.getRoot<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): Instance
	return self._root
end

function AnatomyInstance.getTemplate<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>
): AnatomyTemplate<SocketT, TagT>
	return self._template
end

function AnatomyInstance.getMetadata<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): DescriptorMetadata?
	return self._metadata
end

function AnatomyInstance.getSocket<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	name: SocketT
): AnatomySocket<SocketT>?
	return self._sockets[name]
end

function AnatomyInstance.getSockets<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>
): { [SocketT]: AnatomySocket<SocketT> }
	-- The independent snapshot exposes borrowed children, not their owner's teardown authority.
	return table.clone(self._sockets) :: { [SocketT]: AnatomySocket<SocketT> }
end

function AnatomyInstance.getTaggedElements<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>
): { AnatomyTaggedElement<TagT> }
	local elements: { AnatomyTaggedElement<TagT> } = {}
	for _, element in self._taggedElements do
		table.insert(elements, element)
	end
	return elements
end

function AnatomyInstance.getByTag<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	prefix: string
): { AnatomyTaggedElement<TagT> }
	local elements = self._tagPrefixIndex[prefix]
	if elements == nil then
		return {}
	end

	local result: { AnatomyTaggedElement<TagT> } = {}
	for _, element in elements do
		table.insert(result, element)
	end
	return result
end

function AnatomyInstance.setParent<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>, parent: Instance?): ()
	self._root.Parent = parent
end

function AnatomyInstance.applyInstancePolicy<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	policy: InstancePolicy
): ()
	forRootAndDescendants(self._root, function(instance: Instance)
		if not instance:IsA("BasePart") then
			return
		end

		local part = instance :: BasePart
		if policy.canCollide ~= nil then
			part.CanCollide = policy.canCollide
		end
		if policy.canQuery ~= nil then
			part.CanQuery = policy.canQuery
		end
		if policy.canTouch ~= nil then
			part.CanTouch = policy.canTouch
		end
		if policy.audioCanCollide ~= nil then
			(part :: any).AudioCanCollide = policy.audioCanCollide
		end
		if policy.castShadow ~= nil then
			part.CastShadow = policy.castShadow
		end
		if policy.enableFluidForces ~= nil then
			part.EnableFluidForces = policy.enableFluidForces
		end
		if policy.massless ~= nil then
			part.Massless = policy.massless
		end
		if policy.anchored ~= nil then
			part.Anchored = policy.anchored
		end
	end)
end

function AnatomyInstance._resolvePath<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	path: AnatomyPath
): Instance?
	return AnatomyPath.resolve(self._root, path)
end

function AnatomyInstance._buildSocket<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	descriptor: SocketDescriptor<SocketT>
): AnatomySocketOwned<SocketT>
	local target = self:_resolvePath(descriptor.path)
	if target == nil then
		error(
			`Anatomy socket "{descriptor.name}" path did not resolve under {self._root:GetFullName()}`,
			2
		)
	end
	if not target:IsA("Attachment") then
		error(
			`Anatomy socket "{descriptor.name}" resolved to {target.ClassName}; sockets must resolve to Attachment`,
			2
		)
	end

	return AnatomySocket.fromDescriptor(descriptor, target :: Attachment)
end

function AnatomyInstance._buildTaggedElement<SocketT, TagT>(
	self: AnatomyInstanceImpl<SocketT, TagT>,
	descriptor: TagDescriptor<TagT>
): AnatomyTaggedElementOwned<TagT>
	local instance = self:_resolvePath(descriptor.path)
	if instance == nil then
		error(`Anatomy tag path did not resolve under {self._root:GetFullName()}`, 2)
	end

	return AnatomyTaggedElement.fromDescriptor(descriptor, instance, self._tagPathDelimiter)
end

function AnatomyInstance.deconstruct<SocketT, TagT>(self: AnatomyInstanceImpl<SocketT, TagT>): ()
	if self._destroyed then
		return
	end

	self._destroyed = true

	for name, socket in self._sockets do
		socket:deconstruct()
		self._sockets[name] = nil
	end
	for index, element in self._taggedElements do
		element:deconstruct()
		self._taggedElements[index] = nil
	end
	table.clear(self._tagPrefixIndex)

	if self._ownsRoot then
		self._root:Destroy()
	end
end

return AnatomyInstance
