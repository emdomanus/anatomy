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

The dev Rojo project mounts Anatomy directly under `ReplicatedStorage.packages`.

## Concepts

- `AnatomyTemplate` is the recognized asset description. It stores relative paths
  to sockets and tagged elements.
- `AnatomyInstance` is a live clone or wrapped model resolved against a template.
- `AnatomyHost` layers one or more anatomy instances, usually a rig plus addons,
  and resolves sockets and tags reactively.
- `SocketBinding` is a reactive endpoint returned by `host:socket(...)`.
- `SocketMount` connects two endpoints with a `RigidConstraint` and updates when
  reactive endpoints retarget.

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

local recognizeOptions = {
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

local host = Anatomy.anatomyHost.new()
host:push(rig, {
	id = "rig",
	priority = 0,
})
host:push(weapon, {
	id = "weapon",
	priority = 10,
})

local weaponMount = host:mount({
	from = {
		socket = "weaponGrip",
		layerId = "weapon",
	},
	to = {
		socket = "rightGrip",
	},
	options = {
		name = "WeaponToRightGrip",
	},
})

for _, element in host:getByTag("effect") do
	local instance = element:getInstance()
	print(instance:GetFullName(), element:getLeafUnder("effect"))
end

print(weaponMount:isConnected())
```

When the `weapon` layer is removed and another weapon layer is pushed with the
same id, any mount or binding that targets that layer will retarget automatically.
Preview and editor tooling can use `host:getSocketNames()`, `host:getSockets()`,
or `host:getByTag(prefix)` to inspect the currently resolved socket and tag sets.

## Tags

Configure tags with:

- `tagsAttribute: string?`
- `tagDelimiter: string?` default `";"`
- `tagPathDelimiter: string?` default `"."`
- `tagGuard: ((path: string) -> TagT?)?`

If `tagGuard` is omitted, authored tag paths are accepted as strings. If it is
provided, it receives each full authored tag path and returns the typed tag value
or `nil` to reject the tag.

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

VFX should usually depend on an anatomy host, socket endpoint, or tagged element,
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
sockets or tags, or create mounts. For one-shot effects that are merely handed an
endpoint or tagged element by a visualizer, the effect does not need to know how
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

Those systems should pass Anatomy the models, hosts, endpoints, or tagged
elements that Anatomy can resolve and mount.

## Development

The dev project includes a client harness under `dev/client`. It creates simple
block rigs and weapons, runs assertion tests, and exposes a small UI for static
mounting, reactive host-layer swaps, and a `Stress 300` benchmark.

The benchmark is meant for local validation, not a stable public performance
claim. Exact timings depend on hardware, Studio/client state, and the asset shape
being tested.

Run static/build checks:

```sh
selene src dev
rojo build default.project.json --output anatomy-build.rbxm
rojo build dev.project.json --output anatomy-dev-build.rbxl
```

The package entrypoint is `src/init.luau`, which re-exports `src/anatomy`.
