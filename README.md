# Anatomy

Anatomy is a Roblox/pesde package for describing renderable rigs and addons through
named sockets, named parts, named surfaces, and socket-to-socket mounts.

It is meant to sit below character visualizers, VFX tools, character creators, and
equipment preview UI. Anatomy gives those systems a stable way to find and bind to
attachments without coupling them to gameplay character classes, replication state,
skills, teams, collision capsules, or world policy.

## Install

```sh
pesde install
```

Anatomy's direct pesde dependency is:

```toml
hook = { name = "emdomanus/hook", version = "^0.1.0" }
```

The dev Rojo project mounts the generated `roblox_packages` folder beside Anatomy
under `ReplicatedStorage.packages`.

## Concepts

- `AnatomyTemplate` is the recognized asset description. It stores relative paths
  to sockets, parts, and surfaces.
- `AnatomyInstance` is a live clone or wrapped model resolved against a template.
- `AnatomyHost` layers one or more anatomy instances, usually a rig plus addons,
  and resolves sockets reactively.
- `SocketBinding` is a reactive endpoint returned by `host:socket(...)`.
- `SocketMount` connects two endpoints with a `RigidConstraint` and updates when
  reactive endpoints retarget.

Sockets are explicit Roblox `Attachment` instances with a configured socket
attribute. Parts and surfaces can be marked with configured attributes on any
instance. Duplicate socket names in one recognized asset are rejected.

Sockets, parts, and surfaces are resolved when an `AnatomyInstance` is created.
Anatomy reacts to host layer changes, but it does not watch a model's descendant
tree for later additions, removals, or streaming changes inside the same instance.

## Example

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Anatomy = require(ReplicatedStorage.packages.anatomy)

local recognizeOptions = {
	socketAttribute = "AnatomySocket",
	partAttribute = "AnatomyPart",
	surfaceAttribute = "AnatomySurface",
	instancePolicy = {
		canCollide = false,
		canTouch = false,
		canQuery = false,
		castShadow = false,
		massless = true,
	},
}

local rigTemplate = Anatomy.recognizeRig(rigAsset, recognizeOptions)
local weaponTemplate = Anatomy.recognizeAddon(weaponAsset, recognizeOptions)

local rig = rigTemplate:instantiate(workspace)
local weapon = weaponTemplate:instantiate(workspace)

local host = Anatomy.createHost()
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

print(weaponMount:isConnected())
```

When the `weapon` layer is removed and another weapon layer is pushed with the
same id, any mount or binding that targets that layer will retarget automatically.
Preview and editor tooling can use `host:getSocketNames()` or `host:getSockets()`
to inspect the currently resolved socket set.

## VFX And Preview Tools

VFX should usually depend on an anatomy host or socket endpoint, not a full
gameplay character object. A gameplay visualizer can provide the live host, while
an editor preview, viewport UI, or character creator can construct a small preview
host from stand-in rig/addon assets.

That keeps effects portable:

- a weapon trail can bind to `trailStart` and `trailEnd` on the weapon layer;
- an enchant can bind to a weapon surface or socket;
- a transformation preview can swap the rig anatomy on the host;
- a UI preview can use the same sockets without loading replication or gameplay
  state.

The VFX layer can require Anatomy when it needs to construct hosts, inspect sockets,
or create mounts. For one-shot effects that are merely handed an endpoint by a
visualizer, the effect does not need to know how the host was built.

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

Those systems should pass Anatomy the models, hosts, or endpoints that Anatomy can
resolve and mount.

## Development

The dev project includes a client harness under `dev/client`. It creates simple
block rigs and weapons, runs assertion tests, and exposes a small UI for static
mounting, reactive host-layer swaps, and a `Stress 300` benchmark.

The benchmark is meant for local validation, not a stable public performance claim.
Exact timings depend on hardware, Studio/client state, and the asset shape being
tested.

Run static/build checks:

```sh
selene src dev
rojo build default.project.json --output anatomy-build.rbxm
rojo build dev.project.json --output anatomy-dev-build.rbxl
```

The package entrypoint is `src/init.luau`, which re-exports `src/anatomy`.
