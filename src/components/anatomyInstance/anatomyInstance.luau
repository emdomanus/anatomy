--!native
--!strict
--!optimize 2
-- One clone's identity inside Anatomy: a frozen table that refers to its template's four tables and
-- holds nothing about the clone. It answers the capability from those tables and returns itself
-- beside every element index, so a caller can tell which clone an index belongs to.
local AnatomyInstancePrivateTypes =
	require("../../types/components/anatomyInstance/anatomyInstance/private")
local AnatomyInstanceTypes =
	require("../../types/components/anatomyInstance/anatomyInstance/public")
local AnatomySourceTypes = require("../../types/components/anatomySource/anatomySource/public")
local AnatomyTemplateTypes =
	require("../../types/components/anatomyTemplate/anatomyTemplate/public")

type AnatomyInstance = AnatomyInstanceTypes.AnatomyInstance
type AnatomyInstanceImpl = AnatomyInstancePrivateTypes.AnatomyInstanceImpl
type AnatomySource = AnatomySourceTypes.AnatomySource
type AnatomyTemplate = AnatomyTemplateTypes.AnatomyTemplate
export type AnatomyInstanceModule = {
	-- A new instance of the template. It takes nothing about the clone it stands for.
	read new: (anatomyTemplate: AnatomyTemplate) -> AnatomyInstance,
}

-- What both subscriptions return: an instance never changes, so there is nothing to release.
local function doNothing(): () end

local AnatomyInstance = {}
AnatomyInstance.__index = AnatomyInstance

function AnatomyInstance.new(anatomyTemplate: AnatomyTemplate): AnatomyInstance
	local self = (
		setmetatable({
			socketNames = anatomyTemplate.socketNames,
			taggedPrefixes = anatomyTemplate.taggedPrefixes,
			_socketElementIndexByName = anatomyTemplate.socketElementIndexByName,
			_taggedElementIndexesByPrefix = anatomyTemplate.taggedElementIndexesByPrefix,
		}, AnatomyInstance) :: unknown
	) :: AnatomyInstanceImpl
	table.freeze(self)
	return self
end

function AnatomyInstance.getSocket(
	self: AnatomyInstanceImpl,
	socketName: string
): (number?, AnatomySource?)
	local elementIndex = self._socketElementIndexByName[socketName]
	if elementIndex == nil then
		return nil, nil
	end
	return elementIndex, self
end

function AnatomyInstance.getTopTagged(
	self: AnatomyInstanceImpl,
	prefix: string
): (number?, AnatomySource?)
	local elementIndexes = self._taggedElementIndexesByPrefix[prefix]
	if elementIndexes == nil then
		return nil, nil
	end
	return elementIndexes[#elementIndexes], self
end

function AnatomyInstance.getTagged(
	self: AnatomyInstanceImpl,
	prefix: string,
	intoElementIndexes: { number },
	intoAnatomyInstances: { AnatomySource }
): ()
	local elementIndexes = self._taggedElementIndexesByPrefix[prefix]
	if elementIndexes == nil then
		return
	end
	for position = 1, #elementIndexes do
		table.insert(intoElementIndexes, elementIndexes[position])
		table.insert(intoAnatomyInstances, self)
	end
end

function AnatomyInstance.onAnySocketChanged(
	_self: AnatomyInstanceImpl,
	_callback: (socketName: string) -> ()
): () -> ()
	return doNothing
end

function AnatomyInstance.onAnyTopTaggedChanged(
	_self: AnatomyInstanceImpl,
	_callback: (prefix: string) -> ()
): () -> ()
	return doNothing
end

function AnatomyInstance.containsSource(
	self: AnatomyInstanceImpl,
	anatomySource: AnatomySource
): boolean
	return anatomySource == self
end

table.freeze(AnatomyInstance)

local module: AnatomyInstanceModule = table.freeze({ new = AnatomyInstance.new })
return module
