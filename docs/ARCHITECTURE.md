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
  `tagDelimiter`, trimmed, optionally validated by `tagGuard`, and expanded into
  query prefixes using `tagPathDelimiter`.

Templates are immutable by convention. `instantiate(parent)` clones the source
model and binds the clone. `wrap(root)` binds an existing model without cloning.

## Instance

`AnatomyInstance.new(template, root, ownsRoot?)` resolves descriptor paths against
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
