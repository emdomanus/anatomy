# Anatomy

Anatomy discovers named sockets and hierarchical tags in Roblox assets, instantiates those
assets, composes their contents through hosts, and provides explicit attachment mounts.
Game state, replication, visual parenting, and effect lifetime remain with the caller.

## Asset construction

```luau
local Anatomy = require(game.ReplicatedStorage.packages.anatomy)
local function guardName(value: unknown): string
    assert(type(value) == "string" and value ~= "", "Expected a name")
    return value
end
local options = {
    socketAttribute = "Socket",
    tagsAttribute = "Tags",
    socketNameGuard = guardName,
    tagGuard = guardName,
}
local template = Anatomy.anatomyTemplate.new(swordAsset, options)
local sword = template:instantiate(workspace)
-- Or: template:wrap(existingSwordModel)
```

`new(asset, options)` recognizes the source asset once. It reads the configured attributes
on the root and descendants, validates names, and freezes internal path/tag descriptors.
A socket attribute must be on an Attachment; duplicate socket names are rejected.
Tags such as `body.hand;effect.grip` are parsed into an immutable set and prefix index.
The default tag delimiter is `;` and path delimiter is `.`.

`instantiate(parent?)` clones the source asset and resolves its descriptors against the clone.
`wrap(root)` resolves them against an existing matching model and does not own that model.
Neither operation rescans attributes. The source asset remains live and caller-owned.
Anatomy does not track later descendant/attribute changes or streaming inside a live instance.

Guards accept `unknown`, return the identical value with a concrete type, and throw on rejection.
They determine allowed vocabulary, not which sockets/tags actually exist. Both guards are required.
Template IDs and caller-supplied descriptor construction are absent; recognition is the sole
public construction route. Optional category, metadata, and instance policy retain their prior roles.

## Sources and hosts

Both anatomy instances and hosts implement `AnatomySource<SocketT, TagT>` directly:

| Method | Contract |
| --- | --- |
| `getSocket(name)` | Current concrete socket or nil |
| `getTagged(prefix)` | Independent array of matching tagged elements |
| `bindSocketChanged(callback, runInitially?)` | Callback receives `(name, socketOrNil)` for any changed name |
| `bindTaggedAdded(callback, runInitially?)` | Callback receives each newly present element |
| `bindTaggedRemoved(callback)` | Callback receives each no-longer-present element |

Bindings return idempotent disconnect functions. Initial delivery enumerates current membership
synchronously, without name-list query objects. An empty source produces no initial events.
Static instances need no listener tables: initial delivery is sufficient for their fixed membership.
Hosts publish subsequent changes as registered sources change. Filter tag events with `element:hasTag(prefix)`.

```luau
local host = Anatomy.anatomyHost.new({ socketNameGuard = guardName, tagGuard = guardName })
local equipment = Anatomy.anatomyHost.new({ socketNameGuard = guardName, tagGuard = guardName })
equipment:push(sword, 10)
host:push(rig, 0)
host:push(equipment, 20)
host:setPriority(equipment, 30)
host:remove(equipment)
```

Sources are registered by table identity, once per host. `push(source, priority?)` defaults to
priority zero and returns no layer handle. `remove(source)` returns whether it removed a registration.
`setPriority(source, priority)` rejects absent sources. `clear()` removes sources present at call entry.
The same source may belong to different hosts. Registrations retain their sources strongly until removed.
No string IDs, options tables, override flags, or source-specific selectors are needed: query that source directly.

Highest priority wins each socket name; equal priorities favor later registration. Removing the winner
reveals the next candidate. A nested host resolves internally and contributes its output at its parent's
registration priority. Direct and indirect host cycles are rejected.

Tags form an identity-deduplicated union, with reference counts for shared contributions through
multiple child hosts. Priority does not filter tag membership. Host tag results run from lowest to highest precedence,
with shared elements placed at their highest-precedence occurrence. Instance results follow recognized
element order; `getTopTagged(prefix)` selects the last matching element in the winning source.

## Tags

`AnatomyTaggedElement` describes one live Roblox Instance and its complete tag set.
`element:getTags()` returns the same frozen table on every live call, without cloning it.
`hasTag(prefix)` supports ancestor prefixes; `getLeafUnder(prefix)` reads a suffix.
The tag set is immutable recognition data, not a mutable set of CollectionService tags.
After retirement, `getTags()` returns a shared frozen empty set.

```luau
for _, element in sword:getTagged("effect") do
    print(element:getInstance(), element:getTags())
end
```

Collection queries return independent arrays. There are no public descriptor getters, socket-name
lists, bulk socket maps, or traversal helpers. `getTopTagged(prefix)` resolves one element without
allocating a result array; it returns nil when nothing matches.

## Direct subscriptions and mounts

```luau
local mount = host:mount(nil, weaponAttachment, { parent = constraintOwner })
local disconnect = host:bindToSocket("rightGrip", function(socket)
    mount:setAttachments(if socket then socket:getAttachment() else nil, weaponAttachment)
end, true)

local releaseTagged = host:bindTopTaggedChanged("weapon.blade", function(element)
    -- Update the presentation target, or clear it when element is nil.
end, true)
```

Named socket subscriptions receive the socket or nil directly; there is no SocketWatcher object.
Top-tag subscriptions receive the selected tagged element or nil. Initial delivery includes nil.
Each binding returns an idempotent disconnect function. Callbacks are installed before initial delivery;
a throwing initial callback releases its subscription before propagating the error.

One named socket callback bucket is shared by its listeners. Top-tag selection state is created only
for an observed prefix and shared across its listeners. Nested source subscriptions are installed on
the first listener and released with the last. Unobserved queries resolve on demand; observed queries
read the cached winner. Only affected observed prefixes are reconciled on mutation, and notification
requires an identity change. Winner removal resolves fallback candidates; it does not rebuild all tags.
A concrete socket always has an attachment until its owner retires it.

Mounts accept `Attachment?` values only. `Anatomy.socketMount.new(from, to, options?)` and
`host:mount(from, to, options?)` eagerly own one reusable RigidConstraint. Options are
`name?`, `rigidName?`, `parent?`, and `enabled?`. Omitted parent leaves the constraint unparented.
`setAttachments(from, to)` disables it while either side is missing and otherwise respects requested
enabled state. `setEnabled`, `setParent`, and idempotent `deconstruct` are explicit.
`isConnected` describes enabled/two-attachment configuration, not physics activity or ancestry.
Mounts do not subscribe to sources or parent rendered models; their owner handles those policies.

## Ownership

Remove static instances and custom sources from every parent before destroying them. Removing a
source only disconnects its registration; it never destroys that source. A host publishes its membership
removal during teardown, so a parent can fall back; it does not infer arbitrary provider destruction.
Disconnect external mount-updating callbacks before destroying mounts or their host. Host teardown
releases its named/prefix listeners, mounts, and child subscriptions, while leaving borrowed sources alive.
Remove instances from hosts and clear/destroy mounts referencing their attachments before instance teardown.
`instantiate` owns its cloned root; `wrap` borrows its root.

## Verification and development

Install pinned tools with Rokit and dependencies with Pesde. The local dev project entrypoint is
`ReplicatedStorage.packages.anatomy.src`; installed consumers use the Pesde package link.

```powershell
pwsh -NoProfile -File scripts/verify/run.ps1 -Check all
```

The guarded runner checks formatting, lint, full new-solver analysis, headless behavioral tests,
package/dev Rojo builds, and VitePress documentation. The Studio harness includes visual demos,
assertion groups, and a local benchmark. Headless constraints are simulated property sinks;
Studio physics, UI, and real constraint behavior still need Studio verification.

See [architecture](docs/ARCHITECTURE.md), [types](docs/types.md), and
[the source-model migration receipt](docs/source-model-review-2026-10-03.md).
