# Anatomy

Anatomy reads named sockets and hierarchical tags from an asset's element table and composes them
across sources by priority. It is plain Luau: it reads no model, holds no engine object and calls no
engine API. A socket and a tagged element are each an element index with the instance that supplied
it; the consumer turns that pair into an engine object through whatever owns the asset.

## Install

Add the package to your `pesde.toml` and run `pesde install`. Its target is `luau` and its entry is
`src/shared.luau`. It depends on `emdomanus/luau_utils`.

## Example

```luau
local Anatomy = require(path.to.anatomy)

-- Once per asset. `elements[elementIndex].authoredAttributes` is that element's attributes.
local bodyTemplate = Anatomy.anatomyTemplate.new(bodyElements, "RigSocket", "RigSurface")
local helmTemplate = Anatomy.anatomyTemplate.new(helmElements, "RigSocket", "RigSurface")

-- Once per clone. The instance holds nothing about the clone: you keep the map.
local body = Anatomy.anatomyInstance.new(bodyTemplate)
local helm = Anatomy.anatomyInstance.new(helmTemplate)
cloneByInstance[body] = bodyClone
cloneByInstance[helm] = helmClone

-- Once per composed thing.
local host = Anatomy.anatomyHost.new()
host:push(body, 0)
host:push(helm, 10)

local elementIndex, anatomyInstance = host:getSocket("body.head")   -- the helm's, while it is pushed
local release = host:onSocketChanged("body.head", function(elementIndex, anatomyInstance)
	-- nil, nil when no source supplies it
end, true)

host:remove(helm)                                                    -- the callback receives the body's
release()
host:deconstruct()
```

## The API in one table

| Call | Does |
| --- | --- |
| `anatomyTemplate.new(elements, socketAttribute, tagsAttribute)` | frozen data: which element carries each socket name, which elements are under each tag prefix |
| `anatomyInstance.new(anatomyTemplate)` | one clone's identity; a source |
| `anatomyHost.new()` | a host; a source too, so a host can be pushed into a host |
| `source:getSocket(socketName)` | `elementIndex, anatomyInstance`, or `nil, nil` |
| `source:getTopTagged(prefix)` | the same for the top element under a tag prefix |
| `source:getTagged(prefix, intoElementIndexes, intoAnatomyInstances)` | appends every element under the prefix, lowest precedence first |
| `host:onSocketChanged(socketName, callback, initially?)` | reports a changed `getSocket` result |
| `host:onTopTaggedChanged(prefix, callback, initially?)` | reports a changed `getTopTagged` result |
| `host:onSocketAmongOthersChanged(socketName, excluded, callback, initially?)` | the socket as the sources other than `excluded` supply it |
| `host:push(source, priority)`, `remove(source)`, `setPriority(source, priority)`, `deconstruct()` | the owner's methods |

The queries, and `push`, `remove` and `setPriority` of an instance with their reports, allocate
nothing.

## Documentation

- [Overview](docs/index.md)
- [Public contracts](docs/types.md)
- [Architecture](docs/ARCHITECTURE.md)

## Checks

```powershell
rokit install
pesde install --locked
compass checks run -ProjectRoot . -Kind code
```

`compass.json` names the checks: the `luau` preset's formatting, lint, layout, source and analysis
checks, and `scripts/verify/tests.ps1`, which runs every `*.spec.luau` in Lune. The analysis loads no
engine definitions, so an engine type written in `src` is a diagnostic. Nothing in the package needs
Studio.
