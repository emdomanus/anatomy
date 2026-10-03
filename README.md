# Anatomy

Anatomy is a Roblox/pesde package for describing renderable rigs and addons through
named sockets, hierarchical tags, and socket-to-socket mounts.

It is meant to sit below character visualizers, VFX tools, character creators, and
equipment preview UI. Anatomy gives those systems a stable way to find and bind to
attachments or tagged visual regions without coupling them to gameplay character
classes, replication state, skills, teams, collision capsules, or world policy.

## Install

```sh
pesde install
```

The dev Rojo project mirrors the Pesde package layout: its entrypoint is
`ReplicatedStorage.packages.anatomy.src`, beside its `roblox_packages` dependencies.
Installed consumers continue to require their Pesde-generated Anatomy package link.

## Concepts

- `AnatomyTemplate` is the recognized asset description. It stores relative paths
  to sockets and tagged elements.
- `AnatomyInstance` is a live clone or wrapped model resolved against a template.
- `AnatomyHost` layers one or more anatomy instances, usually a rig plus addons,
  and resolves sockets and tags reactively.
- `AnatomySocket` is one concrete socket with an always-present `Attachment`.
- `SocketWatcher` follows a host socket address and returns a socket or `nil`.
  Create it with `host:watchSocket(name, layerId?, includeOverrides?)`.
- `SocketMount` owns one `RigidConstraint` between explicit attachments. The caller
  controls its attachments, enabled state, and parent; watcher wiring stays with that caller.

Sockets are explicit Roblox `Attachment` instances with a configured socket
attribute. Tags can be marked with a configured tags attribute on any instance.
Duplicate socket names in one recognized asset are rejected.

Tags are parsed once when a template is recognized, cached as descriptors, and
queried by hierarchical prefix. A tag such as `effect.trail` matches both
`effect` and `effect.trail`.

Sockets and tags are resolved when an `AnatomyInstance` is created.
Anatomy reacts to host layer changes, but it does not watch a model's descendant
tree for later additions, removals, or streaming changes inside the same instance.

## Example

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Anatomy = require(ReplicatedStorage.packages.anatomy)

local function guardName(value: unknown): string
    assert(type(value) == "string" and value ~= "", "Expected a non-empty name")
    return value
end

local recognizeOptions = {
    socketNameGuard = guardName,
    tagGuard = guardName,
	socketAttribute = "AnatomySocket",
	tagsAttribute = "AnatomyTags",
	tagDelimiter = ";",
	tagPathDelimiter = ".",
	instancePolicy = {
		canCollide = false,
		canTouch = false,
		canQuery = false,
		castShadow = false,
		massless = true,
	},
}

local rigTemplate = Anatomy.anatomyTemplate.recognize(rigAsset, recognizeOptions)
local weaponTemplate = Anatomy.anatomyTemplate.recognize(weaponAsset, recognizeOptions)

local rig = rigTemplate:instantiate(workspace)
local weapon = weaponTemplate:instantiate(workspace)

local host = Anatomy.anatomyHost.new({ socketNameGuard = guardName, tagGuard = guardName })
host:push(rig, {
	id = "rig",
	priority = 0,
})
host:push(weapon, {
	id = "weapon",
	priority = 10,
})

local weaponWatcher = host:watchSocket("weaponGrip", "weapon")
local handWatcher = host:watchSocket("rightGrip")
local weaponMount = host:mount(nil, nil, {
    name = "WeaponToRightGrip",
    parent = workspace,
})
local function updateMount()
    local from = weaponWatcher:getSocket()
    local to = handWatcher:getSocket()
    weaponMount:setAttachments(
        if from then from:getAttachment() else nil,
        if to then to:getAttachment() else nil
    )
    -- The rendering owner can also hide/unparent the visual when either socket is nil.
end
local disconnectWeapon = weaponWatcher:bindSocketChanged(updateMount)
local disconnectHand = handWatcher:bindSocketChanged(updateMount)
updateMount()

for _, element in host:getByTag("effect") do
	local instance = element:getInstance()
	print(instance:GetFullName(), element:getLeafUnder("effect"))
end

print(weaponMount:isConnected())
```

When the `weapon` layer is removed and another weapon layer is pushed with the
same id, watchers targeting that address select the replacement socket. The caller above
updates the mount explicitly in response.
Preview and editor tooling can use `host:getSocketNames()`, `host:getSockets()`,
or `host:getByTag(prefix)` to inspect the currently resolved socket and tag sets.

## Watching and ownership

```luau
local watcher = host:watchSocket("rightGrip") -- normal selection across all layers
local disconnect = watcher:bindSocketChanged(function(socket)
    local attachment = if socket then socket:getAttachment() else nil
    -- Update the consumer from attachment.
end, true)

-- During owner cleanup:
disconnect()
disconnectWeapon()
disconnectHand()
weaponMount:deconstruct()
weaponWatcher:deconstruct()
handWatcher:deconstruct()
watcher:deconstruct()
host:remove("weapon")
host:remove("rig")
weapon:deconstruct()
rig:deconstruct()
host:deconstruct()
```

Watchers have one socket-change event; concrete sockets have no attachment-change event.
`socket:getAttachment()` returns `Attachment`, never `nil`. A destroyed socket is a retired
borrowed handle and rejects attachment access. Missing addresses are represented by a watcher's
`nil` socket. External descendant destruction/streaming is not observed.

Mounts borrow attachment references and own only their constraint. They never subscribe to
watchers. Owners release watcher subscriptions before destroying the mount or its host; host
teardown destroys host-created mounts and releases its remaining watchers. Remove instances
from all hosts and clear/destroy mounts referencing their attachments before instance teardown.

## Explicit mounts

```luau
local mount = Anatomy.socketMount.new(fromSocket:getAttachment(), toSocket:getAttachment(), {
    parent = constraintOwner,
})
mount:setAttachments(nil, toSocket:getAttachment()) -- disabled while a side is missing
mount:setAttachments(fromSocket:getAttachment(), toSocket:getAttachment())
mount:setEnabled(false) -- remains disabled even across attachment changes
mount:setParent(nil) -- stays unparented until explicitly parented again
mount:deconstruct()
```

Construction always creates one constraint, including when either initial attachment is nil.
Omitting `options.parent` leaves it unparented. `setAttachments` reuses that constraint and
never changes its parent. Clearing a side disables it; restoring both honors the caller's
requested enabled state. `setParent` affects the constraint only, not a rendered model.
`isConnected()` reports configured enabled/two-attachment state, not engine ancestry or
physical activity. `getConstraint()` exposes the constraint for inspection; attachment,
enabled, and parent writes should go through the mount. `refresh()` and polymorphic mount
inputs were removed. There is no reactive mount subclass or automatic rendering policy.

Socket selectors are positional: `getSocket(name, layerId?, includeOverrides?)`,
`getSockets(layerId?, includeOverrides?)`, and `getSocketNames(layerId?, includeOverrides?)`.
With a layer id, only that layer is considered. Without one, overrides default to enabled;
passing `nil, false` selects the first matching layer. Tag lookup takes `getByTag(prefix, layerId?)`.
Query/address tables and `socketEndpoint.fromAttachment` are no longer part of the API.

## Collection reads without temporary tables

Existing collection getters still return independent snapshots. Use
`instance:getFirstByTag(prefix)` or `host:getFirstByTag(prefix, layerId?)` when only one
match is needed; use the corresponding `getLastByTag` method for the last match. These return an element or nil without allocating a result array.
The host follows the same selection order as its `getByTag(...)` collection; watched prefix
sets have unspecified order.

For synchronous read-only traversal, use `instance:forEachSocket(callback)`,
`instance:forEachTaggedElement(callback)`, `instance:forEachByTag(prefix, callback)`,
and `element:forEachTag(callback)`. Socket callbacks receive `(name, socket)`; the
others receive the element or tag. They expose borrowed objects, never private tables.
Callbacks must not destroy or structurally mutate the instance being traversed.
Use the existing snapshot getters when iteration must survive such mutation.

Templates now reuse frozen construction data, and hosts use these traversal methods
internally. See [allocation accounting](docs/allocation-review-2026-10-03.md).

## Tags

Configure tags with:

- `tagsAttribute: string?`
- `tagDelimiter: string?` default `";"`
- `tagPathDelimiter: string?` default `"."`
- `tagGuard: GuardFn<TagT>` (required; `(unknown) -> TagT`)

Both `socketNameGuard` and `tagGuard` are required on recognition and host options.
They use the standalone Guard package's `GuardFn<T>`: accept `unknown`, return the
identical value with a concrete type, and throw on rejection. Boolean predicates
and nil-returning validators are no longer accepted. Use a string guard for an
unrestricted string vocabulary. Hosts validate all names/tags before inserting a layer;
queries still accept ancestor prefixes that are not complete tag names.

Template-level tags are available through `template:getTagDescriptors()`.
Instance-level and host-level queries use prefix matching. Use semantic tag
paths such as `part.torso`, `body.upper.torso`, or `effect.trail` when you need
to find specific authored elements:

```luau
local tagged = instance:getByTag("effect")

local disconnect = host:bindByTag("effect", function(element)
	print("added", element:getInstance())
end, function(element)
	print("removed", element:getInstance())
end, true)
```

## VFX And Preview Tools

VFX should usually depend on an anatomy host, socket watcher, concrete socket, or tagged element,
not a full gameplay character object. A gameplay visualizer can provide the live
host, while an editor preview, viewport UI, or character creator can construct a
small preview host from stand-in rig/addon assets.

That keeps effects portable:

- a weapon trail can bind to `trailStart` and `trailEnd` on the weapon layer;
- an enchant can bind to a weapon socket or query tagged elements such as
  `effect.enchant`;
- a transformation preview can swap the rig anatomy on the host;
- a UI preview can use the same sockets and tags without loading replication or
  gameplay state.

The VFX layer can require Anatomy when it needs to construct hosts, inspect
sockets or tags, or create mounts. For one-shot effects that are merely handed a
socket, watcher, or tagged element by a visualizer, the effect does not need to know how
the host was built.

## Boundaries

Anatomy owns discoverable visual anatomy and socket-to-socket mounting primitives.
It does not own:

- gameplay policy;
- replication;
- character state;
- skills;
- teams;
- collision capsules;
- world or place policy;
- VFX lifetime rules.

Those systems should pass Anatomy the models, hosts, sockets, watchers, or tagged
elements that Anatomy can resolve and mount.

## Development

Install CLI tools with `rokit install` (replacing Aftman). Both editor and CLI
analysis explicitly enable `LuauSolverV2`. Both host generics now come from typed
guard inputs; see the
[review receipt](docs/new-solver-review-2026-10-02.md).

```powershell
pwsh -NoProfile -File scripts/setup/fetch-roblox-types.ps1
pwsh -NoProfile -File scripts/verify/run.ps1
```

Use `-Check analyze`, `stylua`, `selene`, `tests`, `build`, or `docs` for one gate.
`-Paths` scopes the formatting check only. The default checks all source and dev
files. Local build
artifacts belong in ignored `.verification/`. Studio tests below are a separate
manual gate; a successful Rojo build does not run them.

The dev project includes a client harness under `dev/client`. It creates simple
block rigs and weapons, runs assertion tests, and exposes a small UI for static
mounting, reactive host-layer swaps, and a `Stress 300` benchmark.

The benchmark is meant for local validation, not a stable public performance
claim. Exact timings depend on hardware, Studio/client state, and the asset shape
being tested.

Run static/build checks:

```sh
pwsh -NoProfile -File scripts/verify/run.ps1 -Check selene
pwsh -NoProfile -File scripts/verify/run.ps1 -Check build
```

The package entrypoint is `src/init.luau`, which selects the public constructors and
types from their canonical domain-qualified owners under `src/anatomy`.
