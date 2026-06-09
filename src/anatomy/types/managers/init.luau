--!strict
--!optimize 2
--!native

local AnatomyHostTypes = require(script.anatomyHost)

export type AnatomyHost<TSocketName, TSurfaceName> = AnatomyHostTypes.AnatomyHost<TSocketName, TSurfaceName>
export type AnatomyHostOptions<TSocketName, TSurfaceName> = AnatomyHostTypes.AnatomyHostOptions<TSocketName, TSurfaceName>
export type AnatomyHostLayer<TSocketName, TSurfaceName> = AnatomyHostTypes.AnatomyHostLayer<TSocketName, TSurfaceName>
export type AnatomyHostLayerOptions = AnatomyHostTypes.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = AnatomyHostTypes.AnatomyHostSocketQuery
export type AnatomyHostTagQuery = AnatomyHostTypes.AnatomyHostTagQuery
export type AnatomyHostSocketAddress<TSocketName> = AnatomyHostTypes.AnatomyHostSocketAddress<TSocketName>
export type AnatomyInstanceSocketAddress<TSocketName, TSurfaceName> =
	AnatomyHostTypes.AnatomyInstanceSocketAddress<TSocketName, TSurfaceName>
export type AnatomyHostMountEndpoint<TSocketName, TSurfaceName> =
	AnatomyHostTypes.AnatomyHostMountEndpoint<TSocketName, TSurfaceName>
export type AnatomyHostMountConfig<TSocketName, TSurfaceName> =
	AnatomyHostTypes.AnatomyHostMountConfig<TSocketName, TSurfaceName>
export type SocketChangedCallback<TSocketName> = AnatomyHostTypes.SocketChangedCallback<TSocketName>
export type TagChangedCallback<TagT> = AnatomyHostTypes.TagChangedCallback<TagT>

return {}
