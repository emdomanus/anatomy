--!strict
--!optimize 2
--!native

local AnatomyHostTypes = require(script.anatomyHost)

export type AnatomyHost<SocketT, TagT> = AnatomyHostTypes.AnatomyHost<SocketT, TagT>
export type AnatomyHostOptions<SocketT> = AnatomyHostTypes.AnatomyHostOptions<SocketT>
export type AnatomyHostLayer<SocketT, TagT> = AnatomyHostTypes.AnatomyHostLayer<SocketT, TagT>
export type AnatomyHostLayerOptions = AnatomyHostTypes.AnatomyHostLayerOptions
export type AnatomyHostSocketQuery = AnatomyHostTypes.AnatomyHostSocketQuery
export type AnatomyHostTagQuery = AnatomyHostTypes.AnatomyHostTagQuery
export type AnatomyHostSocketAddress<SocketT> = AnatomyHostTypes.AnatomyHostSocketAddress<SocketT>
export type AnatomyInstanceSocketAddress<SocketT> = AnatomyHostTypes.AnatomyInstanceSocketAddress<SocketT>
export type AnatomyHostMountEndpoint<SocketT> = AnatomyHostTypes.AnatomyHostMountEndpoint<SocketT>
export type AnatomyHostMountConfig<SocketT> = AnatomyHostTypes.AnatomyHostMountConfig<SocketT>
export type SocketChangedCallback<SocketT> = AnatomyHostTypes.SocketChangedCallback<SocketT>
export type TagChangedCallback<TagT> = AnatomyHostTypes.TagChangedCallback<TagT>

return {}
