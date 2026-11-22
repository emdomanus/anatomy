--!strict
--!optimize 2
-- The package's one entry: every module and type Anatomy hands out. The package is plain Luau: it
-- names no engine type and calls no engine API, so it runs under Lune and in Roblox alike.
local AnatomyHost = require("./components/anatomyHost/anatomyHost")
local AnatomyInstance = require("./components/anatomyInstance/anatomyInstance")
local AnatomyTemplate = require("./components/anatomyTemplate/anatomyTemplate")
local AnatomyHostTypes = require("./types/components/anatomyHost/anatomyHost/public")
local AnatomyInstanceTypes = require("./types/components/anatomyInstance/anatomyInstance/public")
local AnatomySourceTypes = require("./types/components/anatomySource/anatomySource/public")
local AnatomyTemplateTypes = require("./types/components/anatomyTemplate/anatomyTemplate/public")

export type AnatomyElement = AnatomyTemplateTypes.AnatomyElement
export type AnatomySource = AnatomySourceTypes.AnatomySource
export type AnatomyTemplate = AnatomyTemplateTypes.AnatomyTemplate
export type AnatomyInstance = AnatomyInstanceTypes.AnatomyInstance
export type AnatomyHost = AnatomyHostTypes.AnatomyHost
export type AnatomyHostOwned = AnatomyHostTypes.AnatomyHostOwned

type AnatomyHostModule = AnatomyHost.AnatomyHostModule
type AnatomyInstanceModule = AnatomyInstance.AnatomyInstanceModule
type AnatomyTemplateModule = AnatomyTemplate.AnatomyTemplateModule
type AnatomyModule = {
	read anatomyTemplate: AnatomyTemplateModule,
	read anatomyInstance: AnatomyInstanceModule,
	read anatomyHost: AnatomyHostModule,
}

local module: AnatomyModule = table.freeze({
	anatomyTemplate = AnatomyTemplate,
	anatomyInstance = AnatomyInstance,
	anatomyHost = AnatomyHost,
})
return module
