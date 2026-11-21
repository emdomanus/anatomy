# Anatomy

Anatomy reads named sockets and hierarchical tags from an asset's element table and composes them
across sources by priority. It is plain Luau: it reads no model, holds no engine object and calls no
engine API.

```luau
local Anatomy = require(path.to.anatomy)

local anatomyTemplate = Anatomy.anatomyTemplate.new(elements, "RigSocket", "RigSurface")
local anatomyInstance = Anatomy.anatomyInstance.new(anatomyTemplate)
local anatomyHost = Anatomy.anatomyHost.new()

anatomyHost:push(anatomyInstance, 10)
local elementIndex, supplier = anatomyHost:getSocket("body.head")
local topElementIndex, topSupplier = anatomyHost:getTopTagged("skin")
anatomyHost:remove(anatomyInstance)
anatomyHost:deconstruct()
```

The three things it builds:

| Object | One per | Is |
| --- | --- | --- |
| `AnatomyTemplate` | element table | frozen data: socket names and tag prefixes, each with element indexes |
| `AnatomyInstance` | clone of the asset | the identity of one clone; holds nothing about the clone |
| `AnatomyHost` | composed thing | the sources pushed to it, by priority, and the winner of every name |

Every query returns an element index with the instance that supplied it. The consumer keeps the map
from an instance to its clone and asks the asset's owner for the engine object at that index.

- [Public contracts](./types.md)
- [Architecture](./ARCHITECTURE.md)

Anatomy owns the reading of names from an element table and the composition of sources. It does not
own the asset, its clones, any engine object, or a constraint between two of them.
