# Anatomy Architecture

Anatomy turns a Roblox model into a queryable registry of named sockets and
hierarchical tags. A host can aggregate several anatomy instances as
layers, resolve sockets and tags across those layers, and build reactive
socket-to-socket mounts.

The package is engine-generic: it knows about `Instance`, `Attachment`, names,
tags, and paths. It does not know about characters, weapons, VFX, gameplay state,
or replication.

## Lifecycle

```text
Template  --recognize/crawl once-->  descriptors
   | instantiate() / wrap()
   v
Instance  --resolve paths-->  sockets, tagged elements
   | host:push()
   v
Host      --layer aggregate--> sockets, tag queries, watchers, mounts
```

## Template

`AnatomyTemplate.recognize(root, config)` walks `root` and its descendants once.
It records structural paths from the root instead of live references.

The crawl records:

- `SocketDescriptor<SocketT>` from `socketAttribute`; sockets must be on
  `Attachment` instances, are guarded by `socketNameGuard`, and must be unique in
  one template.
- `TagDescriptor<TagT>` from `tagsAttribute`; each authored tag path is split by
  `tagDelimiter`, trimmed, validated by required `tagGuard`, and expanded into
  query prefixes using `tagPathDelimiter`.

Templates snapshot and freeze their configuration and descriptor data. Arbitrary nested metadata values and the live source Instance remain caller-owned. `instantiate(parent)` clones the source
model and binds the clone. `wrap(root)` binds an existing model without cloning.

## Instance

The private instance constructor receives a public template and explicit construction options, and resolves descriptor paths against
the concrete root with `Path.resolve`.

It builds and owns:

- `AnatomySocket<SocketT>`
- `AnatomyTaggedElement<TagT>`

Tagged elements are indexed by prefix in `_tagPrefixIndex`, so
`instance:getByTag(prefix)` is a direct prefix lookup. Named element lookup should
be modeled as tags, for example `part.torso` or `weapon.blade`.

## Host

`AnatomyHost` stores layers in priority order. It does not own pushed anatomy
instances; callers own instance lifetime.

Socket resolution walks layers in order. The first socket wins unless later
layers are allowed to override sockets. Socket APIs include:

- `getSocket(name, layerId?, includeOverrides?)`
- `getSockets(layerId?, includeOverrides?)`
- `getSocketNames(layerId?, includeOverrides?)`
- `bindSocket(name, callback, runInitially?, layerId?, includeOverrides?)`
- `watchSocket(name, layerId?, includeOverrides?)`

Tag queries collect matching tagged elements across layers:

- `getByTag(prefix, layerId?)`
- `bindByTag(prefix, onAdded, onRemoved, runInitially?)`

Watched tag prefixes are materialized in `_resolvedByPrefix` and refreshed when
layers are pushed, removed, or reprioritized.

## Sockets, watchers, and mounts

An `AnatomySocket` identifies one concrete attachment. `getAttachment()` returns `Attachment`;
there is no attachment-change subscription or separate endpoint protocol.

`host:watchSocket(name, layerId?, includeOverrides?)` returns a caller-owned `SocketWatcher`.
It tracks a host address and publishes the selected `AnatomySocket` or `nil` through
`bindSocketChanged(callback, runInitially?)`. Its internal constructor receives the host directly
through `SocketSubscription`; no source adapter or query snapshot is allocated. The host stores
scalar selector fields in its subscription record. A watcher has one callback set.

`host:mount(from, to, options?)` and `Anatomy.socketMount.new(from, to, options?)` accept
`Attachment?` for both sides. A mount eagerly owns exactly one `RigidConstraint`, including
when constructed empty. There are no socket/watcher imports, input unions, subscriptions,
retargeting callbacks, retained query/options records, or lazy constraint state inside it.

Callers use `setAttachments(from, to)`, `setEnabled(enabled)`, and `setParent(parent)`.
A missing attachment disables the constraint; restoring both respects the requested enabled
state. The parent is supplied explicitly at construction or through `setParent`; attachment
updates never infer or restore a parent. The constraint is reused until idempotent teardown.
`isConnected()` describes configured state, not physical activity or ancestry.

Rendering owners may observe watchers, read each selected socket's attachment, update the mount,
and hide/unparent their model as appropriate. They own the disconnect functions and release them
before destroying the mount/host. `dev/client/bindMountWatchers.luau` demonstrates this external
wiring and is exercised by the contract suite; it is not a published reactive-mount abstraction.

## Ownership

- Callers own templates, instances, hosts, and returned watchers/mounts.
- Instances own their sockets and tagged elements; consumers receive borrowed views.
- Hosts own layer registrations and track outstanding watchers/host-created mounts for teardown.
- Mounts borrow attachments and own their constraint. Callers own watcher subscriptions;
  mount destruction has no effect on watchers or subscriptions.
- Watcher destruction disconnects from the host and clears a selected socket to `nil` for listeners.

Remove an instance from every host before deconstructing it. Clear or destroy mounts using its
attachments before deconstructing it. Release caller-owned subscriptions before mount/host teardown. Those rules ensure watchers publish removal while sockets remain
valid. A retired socket rejects attachment access; it does not become an empty socket. Host teardown
does not destroy the instances it layers. External engine destruction and streaming are not observed.

## Notes

- Tags are parsed at template-recognition time and are not re-parsed at runtime.
- `tagGuard` is consumer-injected; the package has no hardcoded tag vocabulary.
- Named part descriptors were removed; use tags for semantic or named element
  lookup.
- Surface APIs were removed in `0.2.0`; authoring that previously used surfaces
  should move to hierarchical tags.

## Contract ownership

Runtime leaves and mirrored object type owners live under explicit `shared` domains.
The package entrypoint selects exact canonical leaves; category-level forwarding barrels
have been removed. `types/ports` holds actual independently consumed capabilities.
Contracts depend on contracts/definitions, never runtime implementations.

The host owns layer ordering and refresh. Layer handles retain `AnatomyHostLayerCommands`
plus an immutable registration ordinal, not the host implementation. Socket and tagged-element
objects do not retain recursive parent implementation types. Instances hold child `Owned`
views and expose borrowed public views.

## Verification

`pwsh -NoProfile -File scripts/verify/run.ps1 -Check tests` runs actual package modules
in Lune with Roblox datatype support, without writing generated source. Its constraint sink
is simulated because Lune 0.10.5 cannot clear reflected attachment references to nil.
It covers guard rejection, inferred-constructor callers, prefix queries, descriptor snapshots,
stale handles, socket selection/removal, explicit constraint updates, stable parenting,
requested enabled state, and cleanup of externally wired watcher subscriptions.
The Studio harness retains its six original assertion groups and adds these contract cases.
Studio physics, UI, and real constraint lifecycle still require explicit Studio verification.

Broader allocation optimization is a separate checkpoint. Collection snapshots, recognition,
instance construction options, and host refresh allocations retain their existing behavior.
