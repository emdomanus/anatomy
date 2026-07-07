# Types

Anatomy exposes Luau types from the package entrypoint so consumers can type sockets, tags, hosts, instances, and mount configs without importing implementation modules directly.

```luau
local Anatomy = require(ReplicatedStorage.packages.anatomy)

type RecognizeOptions<SocketT, TagT> = Anatomy.RecognizeOptions<SocketT, TagT>
type AnatomyHost<SocketT, TagT> = Anatomy.AnatomyHost<SocketT, TagT>
type AnatomyHostMountConfig<SocketT, TagT> = Anatomy.AnatomyHostMountConfig<SocketT, TagT>
```

The exact public surface is re-exported from [`src/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/init.luau) and backed by [`src/anatomy/types/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/init.luau).

## Type Index

### Definitions

- [`AnatomyCategory`](#anatomycategory)
- [`AnatomyId`](#anatomyid)
- [`LayerId`](#layerid)
- [`AnatomyPathStep`](#anatomypathstep)
- [`AnatomyPath`](#anatomypath)
- [`DescriptorMetadata`](#descriptormetadata)
- [`NameGuard`](#nameguard)
- [`InstancePolicy`](#instancepolicy)

### Recognition

- [`SocketDescriptor`](#socketdescriptor)
- [`TagDescriptor`](#tagdescriptor)
- [`RecognizeOptions`](#recognizeoptions)
- [`RecognizeConfig`](#recognizeconfig)

### Components

- [`MountAttachment`](#mountattachment)
- [`SocketEndpoint`](#socketendpoint)
- [`SocketAttachmentChangedCallback`](#socketattachmentchangedcallback)
- [`SocketChangedCallback`](#socketchangedcallback)
- [`AnatomySocket`](#anatomysocket)
- [`AnatomyTaggedElement`](#anatomytaggedelement)
- [`AnatomyTemplate`](#anatomytemplate)
- [`AnatomyInstance`](#anatomyinstance)
- [`SocketBinding`](#socketbinding)
- [`SocketMount`](#socketmount)
- [`SocketMountOptions`](#socketmountoptions)

### Host

- [`AnatomyHost`](#anatomyhost)
- [`AnatomyHostOptions`](#anatomyhostoptions)
- [`AnatomyHostLayer`](#anatomyhostlayer)
- [`AnatomyHostLayerOptions`](#anatomyhostlayeroptions)
- [`AnatomyHostSocketQuery`](#anatomyhostsocketquery)
- [`AnatomyHostTagQuery`](#anatomyhosttagquery)
- [`AnatomyHostSocketAddress`](#anatomyhostsocketaddress)
- [`AnatomyInstanceSocketAddress`](#anatomyinstancesocketaddress)
- [`AnatomyHostMountEndpoint`](#anatomyhostmountendpoint)
- [`AnatomyHostMountConfig`](#anatomyhostmountconfig)
- [`TagChangedCallback`](#tagchangedcallback)

## AnatomyCategory

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

String category for grouping templates and host layers, such as `"rig"` or `"weapon"`.

## AnatomyId

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

String identifier used by recognized templates and other anatomy-owned records.

## LayerId

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

String identifier for a pushed host layer. Layer ids are used by socket queries and reactive mounts.

## AnatomyPathStep

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

One resolved step in a structural path from a recognized root.

```luau
export type AnatomyPathStep = {
	name: string,
	className: string?,
	ordinal: number?,
}
```

## AnatomyPath

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

Array of [`AnatomyPathStep`](#anatomypathstep) entries used to resolve a descriptor against a cloned or wrapped instance.

## DescriptorMetadata

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

Loose metadata map carried by descriptors and templates.

## NameGuard

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

Predicate used to validate authored socket names before they enter the typed API.

```luau
export type NameGuard<TName> = (name: string) -> boolean
```

## InstancePolicy

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

Optional part policy applied when a template instantiates a clone.

## SocketDescriptor

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

Template-time socket record. It stores the socket name, structural path, and optional metadata.

```luau
export type SocketDescriptor<SocketT> = {
	name: SocketT,
	path: AnatomyPath,
	metadata: DescriptorMetadata?,
}
```

## TagDescriptor

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

Template-time tag record. It stores the tagged element path, accepted typed tags, and query prefixes.

## RecognizeOptions

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

Configuration for `Anatomy.anatomyTemplate.recognize`.

```luau
export type RecognizeOptions<SocketT, TagT> = {
	id: AnatomyId?,
	category: AnatomyCategory?,

	socketAttribute: string?,
	tagsAttribute: string?,
	tagDelimiter: string?,
	tagPathDelimiter: string?,
	socketNameGuard: NameGuard<SocketT>?,
	tagGuard: ((path: string) -> TagT?)?,

	instancePolicy: InstancePolicy?,

	metadata: DescriptorMetadata?,
}
```

Use `socketNameGuard` and `tagGuard` when a consuming game wants a closed vocabulary instead of raw strings.

## RecognizeConfig

Source: [`src/anatomy/types/def/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/init.luau)

Alias of [`RecognizeOptions`](#recognizeoptions), used internally once recognition options are normalized.

## MountAttachment

Source: [`src/anatomy/types/components/socketEndpoint.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketEndpoint.luau)

Alias for the Roblox `Attachment` instance used by socket endpoints and mounts.

## SocketEndpoint

Source: [`src/anatomy/types/components/socketEndpoint.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketEndpoint.luau)

Common interface for anything that can provide a current mount attachment and notify when it changes.

## SocketAttachmentChangedCallback

Source: [`src/anatomy/types/components/socketEndpoint.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketEndpoint.luau)

Callback fired when an endpoint's current attachment changes.

## SocketChangedCallback

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Callback used by host socket watchers and socket bindings when a socket resolves, retargets, or clears.

## AnatomySocket

Source: [`src/anatomy/types/components/anatomySocket.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/anatomySocket.luau)

Runtime socket resolved from a [`SocketDescriptor`](#socketdescriptor). It behaves as a [`SocketEndpoint`](#socketendpoint).

## AnatomyTaggedElement

Source: [`src/anatomy/types/components/anatomyTaggedElement.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/anatomyTaggedElement.luau)

Runtime tagged element resolved from a [`TagDescriptor`](#tagdescriptor). Host and instance tag queries return these.

## AnatomyTemplate

Source: [`src/anatomy/types/components/anatomyTemplate.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/anatomyTemplate.luau)

Recognized asset description. Templates store descriptor paths and can instantiate clones or wrap existing roots.

## AnatomyInstance

Source: [`src/anatomy/types/components/anatomyInstance.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/anatomyInstance.luau)

Live clone or wrapped model resolved against an [`AnatomyTemplate`](#anatomytemplate).

## SocketBinding

Source: [`src/anatomy/types/components/socketBinding.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketBinding.luau)

Reactive endpoint returned by `host:socket(...)`. It follows the host socket resolution as layers change.

## SocketMount

Source: [`src/anatomy/types/components/socketMount.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketMount.luau)

Runtime socket-to-socket mount backed by a `RigidConstraint`.

## SocketMountOptions

Source: [`src/anatomy/types/components/socketMount.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketMount.luau)

Options for creating a [`SocketMount`](#socketmount), including the constraint name and parent.

## AnatomyHost

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Main runtime aggregation API. It accepts anatomy instances as ordered layers, resolves sockets, resolves tag prefixes, creates bindings, and creates mounts.

```luau
export type AnatomyHost<SocketT, TagT> = {
	push: (
		self: AnatomyHost<SocketT, TagT>,
		instance: AnatomyInstance<SocketT, TagT>,
		options: AnatomyHostLayerOptions?
	) -> AnatomyHostLayer<SocketT, TagT>,

	getSocket: (
		self: AnatomyHost<SocketT, TagT>,
		name: SocketT,
		query: AnatomyHostSocketQuery?
	) -> AnatomySocket<SocketT>?,

	getByTag: (
		self: AnatomyHost<SocketT, TagT>,
		prefix: string,
		query: AnatomyHostTagQuery?
	) -> { AnatomyTaggedElement<TagT> },

	mount: (
		self: AnatomyHost<SocketT, TagT>,
		config: AnatomyHostMountConfig<SocketT, TagT>
	) -> SocketMount,
}
```

The excerpt above is smaller than the full type. Keep the source type as the exact contract.

## AnatomyHostOptions

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Options for constructing a host.

## AnatomyHostLayer

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Handle returned by `host:push(...)`. It exposes layer priority, the pushed instance, and removal.

## AnatomyHostLayerOptions

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Options for pushing an anatomy instance onto a host.

## AnatomyHostSocketQuery

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Socket lookup filter for layer id and override behavior.

## AnatomyHostTagQuery

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Tag lookup filter. It currently matches [`AnatomyHostSocketQuery`](#anatomyhostsocketquery).

## AnatomyHostSocketAddress

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Mount endpoint address for resolving a socket through a host.

## AnatomyInstanceSocketAddress

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Mount endpoint address for resolving a socket directly from a specific anatomy instance.

## AnatomyHostMountEndpoint

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Union of all endpoint forms accepted by `host:mount(...)`: host socket address, instance socket address, [`AnatomySocket`](#anatomysocket), [`SocketBinding`](#socketbinding), or raw `Attachment`.

## AnatomyHostMountConfig

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Config object for connecting two mount endpoints.

```luau
local mountConfig: Anatomy.AnatomyHostMountConfig<string, string> = {
	from = {
		socket = "weaponGrip",
		layerId = "weapon",
	},
	to = {
		socket = "rightGrip",
		layerId = "rig",
	},
	options = {
		name = "WeaponToRightGrip",
	},
}
```

## TagChangedCallback

Source: [`src/anatomy/types/managers/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost.luau)

Callback used by `host:bindByTag(...)` when tagged elements enter or leave a watched prefix.
