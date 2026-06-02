--!strict
--!optimize 2
--!native

local AnatomyHostTypes = require(script.anatomyHost)

export type AnatomyHost = AnatomyHostTypes.AnatomyHost
export type AnatomyHostOptions = AnatomyHostTypes.AnatomyHostOptions
export type AnatomyHostLayer = AnatomyHostTypes.AnatomyHostLayer
export type AnatomyHostLayerOptions = AnatomyHostTypes.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = AnatomyHostTypes.AnatomyHostSocketQuery
export type AnatomyHostSocketAddress = AnatomyHostTypes.AnatomyHostSocketAddress
export type AnatomyInstanceSocketAddress = AnatomyHostTypes.AnatomyInstanceSocketAddress
export type AnatomyHostMountEndpoint = AnatomyHostTypes.AnatomyHostMountEndpoint
export type AnatomyHostMountConfig = AnatomyHostTypes.AnatomyHostMountConfig

return {}
