# Anatomy

Anatomy is a Roblox Luau package for describing renderable rigs and addons through named sockets, hierarchical tags, and socket-to-socket mounts.

This documentation is intentionally handwritten for now. The source types remain the API contract, and these pages explain how the pieces fit together without adding documentation comments to implementation files.

## Package Boundary

Anatomy owns visual anatomy discovery and mounting primitives:

- recognizing authored sockets and tags on a model;
- cloning or wrapping a recognized model as a live anatomy instance;
- aggregating multiple anatomy instances into a host;
- resolving sockets and tag queries across host layers;
- maintaining socket-to-socket mounts as layers change.

Anatomy does not own gameplay state, replication, skills, teams, collision capsules, world policy, or VFX lifetime policy.

## Source Of Truth

The public package entrypoint is `src/init.luau`. It re-exports the package modules and public Luau types from `src/anatomy/types`.

- [Public entrypoint](https://github.com/emdomanus/anatomy/blob/main/src/init.luau)
- [Type barrel](https://github.com/emdomanus/anatomy/blob/main/src/anatomy/types/init.luau)
- [Architecture notes](/ARCHITECTURE)

## Minimal Flow

```luau
local Anatomy = require(ReplicatedStorage.packages.anatomy)

local template = Anatomy.anatomyTemplate.recognize(model, {
	socketAttribute = "AnatomySocket",
	tagsAttribute = "AnatomyTags",
})

local instance = template:instantiate(workspace)
local host = Anatomy.anatomyHost.new()

host:push(instance, {
	id = "rig",
	priority = 0,
})

local socket = host:getSocket("rightGrip")
local taggedElements = host:getByTag("effect")
```

## Next Slice

The next useful docs pass should expand the [Types](/types) page with one section per stable public type family:

- recognition types;
- template and instance types;
- host layer and query types;
- socket binding and mount types.
