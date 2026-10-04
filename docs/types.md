# Public contracts

`src/init.luau` selects the public constructors and canonical types. Internal descriptor, registration,
and implementation types remain package-owned.

## AnatomySource

The [source port](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/ports/anatomySource/shared/anatomySource.luau)
is implemented directly by instances and hosts, with no view wrapper:

```luau
source:getSocket(name)
source:getTagged(prefix) -- independent array, lowest to highest precedence
source:getTopTagged(prefix) -- optional element; no result-array allocation
source:bindToSocket(name, function(socketOrNil) end, runInitially)
source:bindTopTaggedChanged(prefix, function(elementOrNil) end, runInitially)
source:bindSocketChanged(function(name, socketOrNil) end, runInitially)
source:bindTaggedAdded(function(element) end, runInitially)
source:bindTaggedRemoved(function(element) end)
```

Each binding returns a disconnect function. Source-wide socket events include names; source tag
events cover all elements. Initial delivery is synchronous. Source-wide events enumerate existing membership; named socket and
top-tag subscriptions deliver exactly one initial value, including nil.
An instance's membership is fixed; a host's membership follows its registered sources.
Providers must publish complete initial membership, emit actual changes, and release listeners on
disconnect. Subscription methods that throw must clean up any listener they installed.
Custom providers must not hide feedback cycles behind adapters; package hosts reject cycles
through their directly registered host graph. Remove sources from parents before final teardown.

## AnatomyHost

`anatomyHost.new({ socketNameGuard, tagGuard })` infers both vocabulary types from guards.
It implements AnatomySource and adds:

```luau
host:push(source, priority?) -- one registration per source identity; no result handle
host:remove(source) -- boolean; idempotent
host:setPriority(source, priority) -- registered sources only
host:clear()
host:mount(fromAttachment, toAttachment, options?)
host:deconstruct()
```

Registrations strongly retain borrowed sources. Higher priority wins; later insertion wins ties.
A child host contributes its resolved output as a group. Tag union membership is deduplicated by
element identity, independent of priority. Arrays are ordered from lowest to highest precedence;
shared elements occur once at their highest-precedence position. A host first ranks its immediate
sources by priority and insertion order, then uses each source's own ordering. Child priorities are
local to that child, not flattened into parent priorities. `getTopTagged` agrees with the last result.
Instances use recognition order; their top match is the last match. Custom sources must preserve this
agreement and publish top-tag changes for membership or ordering changes, even without add/remove events.
No layer IDs, layer objects, selector records, override modes, or name-list methods are public.

## AnatomyTemplate and AnatomyInstance

`anatomyTemplate.new(asset, options)` recognizes authored attributes and captures immutable descriptors.
Options require typed identity-preserving `socketNameGuard` and `tagGuard`, each `(unknown) -> T`.
Optional fields: `socketAttribute`, `tagsAttribute`, `tagDelimiter`, `tagPathDelimiter`,
`category`, `metadata`, and `instancePolicy`. No template ID is accepted.
`RecognizeOptions` and its existing `RecognizeConfig` alias describe those options.

Templates expose `getSource`, `getCategory`, `getMetadata`, `instantiate(parent?)`, and `wrap(root)`.
The source Roblox Instance remains caller-owned. Construction options and policy are snapshotted;
metadata receives a shallow frozen snapshot, with arbitrary nested values retaining their existing ownership.
Descriptors and the reused instance-construction record are internal and frozen.

Instances implement AnatomySource and expose root/template/category/metadata access, `setParent`,
`applyInstancePolicy`, and `deconstruct`. An instantiated root is owned; a wrapped root is borrowed.
There is no live attribute scan after recognition and no tag/socket mutation API on instances.

## AnatomySocket and AnatomyTaggedElement

Sockets are borrowed concrete objects with `getName`, `getAttachment`, `getPath`, and `getMetadata`.
`getAttachment` returns Attachment and rejects access after retirement. Sockets have no change event.

A tagged element exposes `getInstance`, `getTags`, `hasTag`, and `getLeafUnder`.
`getTags` returns shared frozen membership, not a clone. `hasTag` supports ancestor prefixes.
Retired elements report no tag membership; their engine-instance access must not be used.
Only their owning anatomy instance holds child teardown authority.

## Direct observation and SocketMount

There is no watcher constructor, type or lifetime. `bindToSocket` uses one callback bucket per observed
name; `bindTopTaggedChanged` shares a selection and nested subscriptions per observed prefix. Both
release their bucket/state on the last disconnect and reject subscribing to a destroyed host.
Initial nil is observable. Changes notify only when the selected identity differs, including fallback
and final removal. Host teardown removes membership before destroying its owned mounts.
Static instances have no listener storage: their membership remains fixed until owner teardown.

`socketMount.new(from: Attachment?, to: Attachment?, options?)` owns one RigidConstraint.
Its public methods are `getName`, `getFromAttachment`, `getToAttachment`, `getConstraint`,
`isConnected`, `setAttachments`, `setEnabled`, `setParent`, and `deconstruct`.
Mount options contain `name?`, `rigidName?`, `parent?`, `enabled?`.
Omitted parent is nil, missing attachments disable the constraint, and attachment updates preserve
requested enabled state and explicit parenting. `isConnected` does not test engine ancestry or physics.
External owners control subscription wiring and visual-parenting policy.

See [direct-subscription migration details](./direct-subscriptions-review-2026-10-04.md).
