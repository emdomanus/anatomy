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
Host      --layer aggregate--> sockets, tag queries, bindings, mounts
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

- `getSocket(name, query?)`
- `getSockets(query?)`
- `getSocketNames(query?)`
- `bindSocket(name, callback, runInitially?)`
- `socket(name, query?)`

Tag queries collect matching tagged elements across layers:

- `getByTag(prefix, query?)`
- `bindByTag(prefix, onAdded, onRemoved, runInitially?)`

Watched tag prefixes are materialized in `_resolvedByPrefix` and refreshed when
layers are pushed, removed, or reprioritized.

## Mounts

Mounts remain socket-only.

`host:mount(config)` normalizes endpoints from:

- an `Attachment`
- an `AnatomySocket`
- a `SocketBinding`
- `{ instance, socket }`
- `{ socket, ...query }`

The resulting `SocketMount` maintains a `RigidConstraint` between the current
attachments of the two endpoints.

## Ownership

```text
Caller
  owns AnatomyTemplate
  owns AnatomyInstance(s)
    owns AnatomySocket / AnatomyTaggedElement
  owns AnatomyHost
    owns AnatomyHostLayer(s)
    owns SocketBinding(s)
    owns SocketMount(s)
```

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

Mounts deconstruct only bindings they created while normalizing host socket addresses.
Externally supplied endpoints remain borrowed. Endpoint destruction publishes a terminal nil
attachment before clearing subscribers. Creating new subscriptions/resources after teardown fails.
Remove a layer before destroying its borrowed instance if tag-removal notifications are needed;
the host observes layer membership, not external instance lifetime or descendant streaming.

## Verification

`pwsh -NoProfile -File scripts/verify/run.ps1 -Check tests` runs actual package modules
in Lune with Roblox datatype support, without writing generated source. Its constraint sink
is simulated because Lune 0.10.5 cannot clear reflected attachment references to nil.
It covers guard rejection, inferred-constructor callers, prefix queries, descriptor snapshots,
stale handles, terminal attachment notification, and mount-owned subscription release.
The Studio harness retains its six original assertion groups and adds these contract cases.
Studio physics, UI, and real constraint lifecycle still require explicit Studio verification.

Allocation optimization is a separate checkpoint. This migration preserves collection snapshot
APIs and the existing binding adapters; ports are structural views with no adapter allocations.
