# Anatomy

Anatomy recognizes Roblox assets into concrete sockets and tagged elements, composes instances
and nested hosts through `AnatomySource`, and provides explicit attachment mounts.

```luau
local Anatomy = require(game.ReplicatedStorage.packages.anatomy)
local function guardName(value: unknown): string
    assert(type(value) == "string", "Expected a name")
    return value
end
local template = Anatomy.anatomyTemplate.new(asset, {
    socketNameGuard = guardName,
    tagGuard = guardName,
    socketAttribute = "Socket",
    tagsAttribute = "Tags",
})
local instance = template:instantiate(workspace)
local host = Anatomy.anatomyHost.new({ socketNameGuard = guardName, tagGuard = guardName })
host:push(instance, 10)
local socket = host:getSocket("rightGrip")
local effects = host:getTagged("effect")
host:remove(instance)
host:deconstruct()
instance:deconstruct()
```

- [Public contracts](./types.md)
- [Architecture and ownership](./ARCHITECTURE.md)
- [Source-model migration receipt](./source-model-review-2026-10-03.md)

Anatomy owns recognition, composition, and mounting primitives. It does not own gameplay,
replication, visual parenting, or effect lifetime. The package entrypoint selects exact shared
contract leaves; public descriptor construction and string layer identities are absent.
