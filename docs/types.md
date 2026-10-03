# Types

Anatomy exposes Luau types from the package entrypoint so consumers can type sockets, tags, hosts, instances, and mount inputs without importing implementation modules directly.

```luau
local Anatomy = require(ReplicatedStorage.packages.anatomy)

type RecognizeOptions<SocketT, TagT> = Anatomy.RecognizeOptions<SocketT, TagT>
type AnatomyHost<SocketT, TagT> = Anatomy.AnatomyHost<SocketT, TagT>
type SocketWatcher<SocketT> = Anatomy.SocketWatcher<SocketT>
type SocketMount = Anatomy.SocketMount
```

The exact public surface is re-exported from [`src/init.luau`](https://github.com/emdomanus/anatomy/blob/main/src/init.luau) and backed by canonical leaf modules under `src/anatomy/types`.

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

- [`SocketChangedCallback`](#socketchangedcallback)
- [`AnatomySocket`](#anatomysocket)
- [`AnatomyTaggedElement`](#anatomytaggedelement)
- [`AnatomyTemplate`](#anatomytemplate)
- [`AnatomyInstance`](#anatomyinstance)
- [`SocketWatcher`](#socketwatcher)
- [`SocketMount`](#socketmount)
- [`SocketMountOptions`](#socketmountoptions)

### Host

- [`AnatomyHost`](#anatomyhost)
- [`AnatomyHostOptions`](#anatomyhostoptions)
- [`AnatomyHostLayer`](#anatomyhostlayer)
- [`AnatomyHostLayerOptions`](#anatomyhostlayeroptions)
- [`TagChangedCallback`](#tagchangedcallback)

## AnatomyCategory

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

String category for grouping templates and host layers, such as `"rig"` or `"weapon"`.

## AnatomyId

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

String identifier used by recognized templates and other anatomy-owned records.

## LayerId

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

String identifier for a pushed host layer. Layer ids are used by socket queries and reactive mounts.

## AnatomyPathStep

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

One resolved step in a structural path from a recognized root.

```luau
export type AnatomyPathStep = {
	name: string,
	className: string?,
	ordinal: number?,
}
```

## AnatomyPath

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

Array of [`AnatomyPathStep`](#anatomypathstep) entries used to resolve a descriptor against a cloned or wrapped instance.

## DescriptorMetadata

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

Loose metadata map carried by descriptors and templates.

## NameGuard

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

Identity-preserving guard for socket and tag names. It accepts `unknown`, returns
the accepted typed value, and throws on rejection; it does not return a boolean.

```luau
export type NameGuard<TName> = Guard.GuardFn<TName> -- (unknown) -> TName; throws on rejection
```

## InstancePolicy

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

Optional part policy applied when a template instantiates a clone.

## SocketDescriptor

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

Template-time socket record. It stores the socket name, structural path, and optional metadata.

```luau
export type SocketDescriptor<SocketT> = {
	name: SocketT,
	path: AnatomyPath,
	metadata: DescriptorMetadata?,
}
```

## TagDescriptor

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

Template-time tag record. It stores the tagged element path, accepted typed tags, and query prefixes.

## RecognizeOptions

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

Configuration for `Anatomy.anatomyTemplate.recognize`.

```luau
export type RecognizeOptions<SocketT, TagT> = {
	id: AnatomyId?,
	category: AnatomyCategory?,

	socketAttribute: string?,
	tagsAttribute: string?,
	tagDelimiter: string?,
	tagPathDelimiter: string?,
	socketNameGuard: NameGuard<SocketT>,
	tagGuard: NameGuard<TagT>,

	instancePolicy: InstancePolicy?,

	metadata: DescriptorMetadata?,
}
```

Both guards are required. Their typed return values infer the socket and tag generics. A guard must preserve identity and throw on invalid input; a string guard provides an unrestricted vocabulary.

## RecognizeConfig

Source: [`src/anatomy/types/def/anatomy/shared/anatomy.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/def/anatomy/shared/anatomy.luau)

Alias of [`RecognizeOptions`](#recognizeoptions), used internally once recognition options are normalized.




## SocketChangedCallback

Source: [`src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau)

Callback used by host subscriptions and socket watchers when a socket resolves, retargets, or clears.

## AnatomySocket

Source: [`src/anatomy/types/components/anatomySocket/shared/anatomySocket.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/anatomySocket/shared/anatomySocket.luau)

Runtime socket resolved from a [`SocketDescriptor`](#socketdescriptor). `getAttachment()` returns a required `Attachment`. It has no change event; a retired socket rejects attachment access.

## AnatomyTaggedElement

Source: [`src/anatomy/types/components/anatomyTaggedElement/shared/anatomyTaggedElement.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/anatomyTaggedElement/shared/anatomyTaggedElement.luau)

Runtime tagged element resolved from a [`TagDescriptor`](#tagdescriptor). Host and instance tag queries return these.

## AnatomyTemplate

Source: [`src/anatomy/types/components/anatomyTemplate/shared/anatomyTemplate.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/anatomyTemplate/shared/anatomyTemplate.luau)

Recognized asset description. Templates store descriptor paths and can instantiate clones or wrap existing roots.

## AnatomyInstance

Source: [`src/anatomy/types/components/anatomyInstance/shared/anatomyInstance.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/anatomyInstance/shared/anatomyInstance.luau)

Live clone or wrapped model resolved against an [`AnatomyTemplate`](#anatomytemplate).

## SocketWatcher

Source: [`src/anatomy/types/components/socketWatcher/shared/socketWatcher.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketWatcher/shared/socketWatcher.luau)

Caller-owned observer returned by `host:watchSocket(name, layerId?, includeOverrides?)`.
It has `getName()`, `getSocket(): AnatomySocket?`, `bindSocketChanged(callback, runInitially?)`,
and idempotent `deconstruct()`. There is no public watcher constructor, attachment getter,
or attachment-change event. Consumers read the attachment from the selected socket.

## SocketMount

Source: [`src/anatomy/types/components/socketMount/shared/socketMount.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketMount/shared/socketMount.luau)

Owns one `RigidConstraint` with explicit `Attachment?` inputs. Construct with
`socketMount.new(from, to, options?)` or `host:mount(from, to, options?)`.

- `setAttachments(from, to)` updates both sides. Either side may be nil.
- `setEnabled(enabled)` sets caller intent, retained across attachment changes.
- `setParent(parent)` explicitly parents/unparents only the constraint.
- `getFromAttachment()`, `getToAttachment()`, and `getConstraint()` inspect current state.
- `isConnected()` reports an enabled constraint with both attachment references, not physics activity.
- `deconstruct()` destroys the owned constraint, idempotently.

Construction allocates the constraint immediately. A missing side disables it; attachment changes
reuse it without altering its parent. There is no `refresh`, watcher subscription, polymorphic
input, or reactive subclass. Caller-owned observation drives any retargeting or visibility behavior.

## SocketMountOptions

Source: [`src/anatomy/types/components/socketMount/shared/socketMount.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/components/socketMount/shared/socketMount.luau)

Options for creating a [`SocketMount`](#socketmount), including the constraint name, requested enabled state, and explicit parent. An omitted
parent leaves the constraint unparented. The mount consumes these options during construction.

## AnatomyHost

Source: [`src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau)

Main runtime aggregation API. It accepts anatomy instances as ordered layers, resolves sockets, resolves tag prefixes, creates watchers, and creates mounts.

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
		layerId: LayerId?,
		includeOverrides: boolean?
	) -> AnatomySocket<SocketT>?,

	getByTag: (
		self: AnatomyHost<SocketT, TagT>,
		prefix: string,
		layerId: LayerId?
	) -> { AnatomyTaggedElement<TagT> },

	mount: (
		self: AnatomyHost<SocketT, TagT>,
		from: Attachment?,
		to: Attachment?,
		options: SocketMountOptions?
	) -> SocketMount,
}
```

The excerpt above is smaller than the full type. Keep the source type as the exact contract.

## AnatomyHostOptions

Source: [`src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau)

Options for constructing a host. Both generic arguments are inferred from the
required typed guard returns. The option fields are read-only to Anatomy, allowing
it to consume ordinary caller tables or frozen configuration without mutation.

## AnatomyHostLayer

Source: [`src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau)

Handle returned by `host:push(...)`. It exposes layer priority, the pushed instance, and removal.

## AnatomyHostLayerOptions

Source: [`src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau)

Options for pushing an anatomy instance onto a host.







## TagChangedCallback

Source: [`src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau`](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/managers/anatomyHost/shared/anatomyHost.luau)

Callback used by `host:bindByTag(...)` when tagged elements enter or leave a watched prefix.

## Guard and ownership migration

`AnatomyHostOptions<SocketT, TagT>` requires both `socketNameGuard: NameGuard<SocketT>`
and `tagGuard: NameGuard<TagT>`. `anatomyHost.new(options)` infers both generic arguments
from their return types. `NameGuard<T>` re-exports the standalone Guard package's
`GuardFn<T>`, whose signature is `(unknown) -> T`. Invalid values throw. Recognition
options and instance policy fields likewise expose read-only consumption contracts.

`AnatomySocket` and `AnatomyTaggedElement` are borrowed views. Only their instance
owner receives the internal `Owned` contracts with `deconstruct`. A layer handle's
`id` is read-only; removal is idempotent and a retired handle cannot affect its replacement.
Reprioritizing a retired handle fails. `AnatomyInstance:getTaggedElements()` returns a
snapshot of all borrowed tagged elements, including those needed for host ingress validation.

`SocketSubscription<SocketT>` is the narrow host capability consumed by watcher construction.
Its method is `bindSocket(name, callback, runInitially?, layerId?, includeOverrides?)`.
The internal host layer command port is not a package export. Query/address records, attachment
adapter factories, endpoint contracts, and instance-address lookup ports have been removed.

Owners remove instances from hosts and clear/destroy attachment mounts before instance teardown.
Watchers publish `nil` when their address stops resolving. Callers subscribe and explicitly update
mounts; those subscriptions must be released before mount/host teardown. Watchers survive until
explicitly released or their host ends. Mounts never own subscriptions or watchers.

Templates snapshot configuration and descriptor tables. Descriptor records, path steps,
paths, tag sets, and prefix sets are frozen; metadata receives a shallow frozen snapshot
(nested arbitrary metadata values remain caller-owned). The source Roblox Instance remains live.
Collection-returning getters retain their existing snapshot semantics.

## Allocation-free reads

The collection getters continue to return independent, mutable outer snapshots.
These additional operations avoid those temporary collections:

| Object | Method | Callback/result |
| --- | --- | --- |
| Instance | `forEachSocket(callback)` | Callback receives `(name, socket)` |
| Instance | `forEachTaggedElement(callback)` | Callback receives each tagged element |
| Instance | `forEachByTag(prefix, callback)` | Callback receives each prefix match |
| Tagged element | `forEachTag(callback)` | Callback receives each complete tag |
| Instance | `getFirstByTag(prefix)` | First match or nil |
| Host | `getFirstByTag(prefix, layerId?)` | First match or nil |
| Instance | `getLastByTag(prefix)` | Last match or nil |
| Host | `getLastByTag(prefix, layerId?)` | Last match or nil |

Traversal is synchronous and borrows object references without exposing backing tables.
Callbacks must not destroy or structurally mutate the instance being traversed. Use a
snapshot getter for mutation during iteration. Missing prefixes produce no calls; retired
tagged elements produce no tags. Single-result selection matches the corresponding
end of the `getByTag(...)` collection, including the unspecified set order for watched host prefixes.
No extra source object, adapter, or public port is needed.

Template construction retains one frozen instance-options record shared by all its instances.
Recognized descriptors are frozen in place; public construction from caller descriptors still
copies and freezes them. Metadata retains its existing shallow-snapshot behavior.
See [allocation accounting](./allocation-review-2026-10-03.md).
