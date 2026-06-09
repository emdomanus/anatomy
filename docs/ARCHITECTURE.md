# Anatomy — Architecture & API Reference

A small Roblox package that turns a model into a **queryable registry of named points and regions**, lets you **aggregate several models into one query surface**, and **welds attachments together** reactively. It is engine-generic: it knows nothing about characters, weapons, VFX, etc. — only Instances, Attachments, names, and tags.

---

## Part 1 — Simple version (the mental model)

Three lifecycle layers, definition → instance → aggregate:

```
Template   (immutable definition)   --recognize/crawl a model once-->   descriptors (name -> path)
   │ instantiate() / wrap()
   ▼
Instance   (a template bound to a real model)   -->   live element objects (socket/surface/part/taggedElement)
   │ host:push()
   ▼
Host       (aggregates many instances as layers) -->   resolved query surface + reactive bindings + mounts
```

- **Template** — you crawl a model *once* (`recognize`). It records, for each tagged/socketed/surfaced descendant, a **structural path** from the root (not a live reference). Templates are immutable and reusable. `instantiate(parent)` clones the source model and binds; `wrap(existingModel)` binds without cloning.
- **Instance** — a template bound to one concrete model. It walks each descriptor's path to the real instance and builds **element objects**: `AnatomySocket`, `AnatomySurface`, `AnatomyPart`, `AnatomyTaggedElement`. The instance **owns** those elements.
- **Host** — holds many instances as **layers** (with priority + override rules) and presents one merged query surface: "what socket/surface/tag resolves right now, across all layers?" It fires reactive callbacks when layers push/pop, and it creates **mounts** (rigid welds between attachments).

Four element kinds an instance exposes:

| Element | Backed by | What it is | Read |
|---|---|---|---|
| **Socket** | `Attachment` | a named attach point / transform | `getAttachment()` |
| **Surface** | one or more `Instance`s | a named region (e.g. a body area) | `getInstances()` / `getPrimaryInstance()` |
| **Part** | any `Instance` | a named reference to an arbitrary instance | `getInstance()` |
| **TaggedElement** | any `Instance` | an instance carrying hierarchical tags | `hasTag(prefix)` / `getLeafUnder(prefix)` |

The mount system (3 tiny pieces):

- **Endpoint** — "anything that exposes a current `Attachment?` and notifies on change." (a fixed attachment, a socket, or a binding all qualify.)
- **Binding** — a *live, reactive* handle to "the socket currently named X in this host," updated as layers change.
- **Mount** — a `RigidConstraint` between two endpoints' attachments, rebuilt/enabled/disabled automatically as either endpoint changes.

**Authoring** is attribute-driven: place `Attachment`s/parts in Studio, set a name attribute (sockets/surfaces/parts) or a delimited tag string (tags), and the crawl records them. Transforms live in the asset (the Attachment's CFrame), not in config — same spirit as Unreal storing sockets in the skeleton asset.

---

## Part 2 — In-depth: every class

### `types/def` — the vocabulary (no logic)
- `AnatomyRole = "rig" | "addon"` — a template is either the base rig or an addon mounted onto one.
- `AnatomyCategory = string`, `AnatomyId = string`, `LayerId = string`, `PartName = string`.
- `AnatomyPathStep = { name, className?, ordinal? }`, `AnatomyPath = { AnatomyPathStep }` — a **structural** path: walk children by name + class + Nth-duplicate. Survives cloning (no live refs).
- `SocketDescriptor`, `SurfaceDescriptor` (multi-path), `PartDescriptor`, `TagDescriptor<TagT> = { path, tags: {[TagT]:true}, prefixes: {[string]:true} }` — what the crawl records.
- `RecognizeOptions/Config` — attribute names (`socketAttribute`, `surfaceAttribute`, `partAttribute`, `tagsAttribute`), tag delimiters, the guards (`socketNameGuard`, `surfaceNameGuard`, `tagGuard`), `instancePolicy`, `role`, `category`, `metadata`.

### `utils/path` — model-relative addressing
- `Path.fromRoot(root, target)` → builds the structural `AnatomyPath` (name/class/ordinal chain). Used at crawl time.
- `Path.resolve(root, path)` → walks a path against a (possibly cloned) root to find the live instance. Used at instance-build time.
- *Why it exists:* a template is crawled on one model but applied to clones — paths let it re-find the same nodes in any copy without holding references.

### `utils/callbackSet` — minimal pub/sub
- `new()`, `bind(set, cb) -> disconnect`, `fire(set, ...)`. A set-of-callbacks keyed by the callback. Everything reactive in the package uses this.

### `components/anatomyTemplate` — the immutable definition
- `recognize(root, config)` — single pass over `root` + descendants (`makeSearchList`). Per instance: reads the socket attr (must be on an `Attachment`, guarded, unique → `SocketDescriptor`), the surface attr (guarded, multi-path → `SurfaceDescriptor`), the **tags** attr (split by `tagDelimiter`, trim, `tagGuard` each full path, expand prefixes by `tagPathDelimiter` → `TagDescriptor`), and the part attr (→ `PartDescriptor`).
- `new(...)` stores descriptor tables + `_config`, `_role`, `_category`, `_metadata`, `_source`.
- `instantiate(parent)` clones `_source` and binds (owns the clone). `wrap(root)` binds an existing model (does not own).
- Getters: `getSocketDescriptors`, `getSurfaceDescriptors`, `getTagDescriptors`, `getPartDescriptors`, etc. (all shallow-cloned).
- **Immutable** by convention; built once, reused for many instances.

### `components/anatomyInstance` — a template bound to a real model
- `new(template, root, ownsRoot?)` — for every descriptor, resolves the path (`_resolvePath` → `Path.resolve`) and builds the element via `_buildSocket` / `_buildSurface` / `_buildPart` / `_buildTaggedElement`. Stores `_sockets`, `_surfaces`, `_parts`, `_taggedElements`, and `_tagPrefixIndex` (prefix → {elements}).
- Getters: `getSocket(s)`, `getSurface(s)`, `getPart(s)`, `getByTag(prefix)` (instance-level prefix lookup).
- `applyInstancePolicy(policy)` — bulk-set BasePart flags (collide/query/touch/anchored/...).
- `deconstruct()` — deconstructs every element, clears the index, destroys the root if `ownsRoot`.
- **Owns** all its element objects; their lifetime == the instance's lifetime.

### `components/anatomySocket` — a named attachment
- `_name`, `_path`, `_attachment: Attachment?`, `_metadata`, `_owner` (the instance), reactive `_attachmentChangedCallbacks`.
- `getName`, `getAttachment`, `getPath`, `getMetadata`, `bindAttachmentChanged(cb, runInitially?)`.
- `_setAttachment` is **reserved/unused** — a comment marks it for a "future live-socket mode." (Dead-ish today.)
- *Note:* a socket satisfies the Endpoint shape (`getAttachment` + `bindAttachmentChanged`), so it can be a mount endpoint directly.

### `components/anatomySurface` — a named region (1..N instances)
- `_name`, `_paths`, `_instances: {Instance}`, `_metadata`, `_owner`.
- `getInstances`, `getPrimaryInstance`, `getPaths`, `getName`, `getMetadata`.
- No reactivity of its own (static set resolved at build).
- *Status: being removed (Stage 4) — superseded by tags.*

### `components/anatomyPart` — a named arbitrary instance
- `_name`, `_path`, `_instance: Instance?`, `_metadata`, `_owner`. `getInstance`, `getName`, `getPath`, `getMetadata`.
- The most generic element: just "a named handle to one instance." **Verified unused end-to-end** (see Part 4 #3): no host API consumes parts, and no consumer sets `partAttribute` or calls `getPart`, so `_parts` is always empty in practice. Safe-to-delete / fold-into-tags candidate.

### `components/anatomyTaggedElement` — a tagged instance (Stage 2)
- `_path`, `_tags: {[TagT]:true}` (authored truth), `_prefixes: {[string]:true}` (query index), `_instance`, `_owner`, `_tagPathDelimiter`.
- `getInstance`, `getTags`, `hasTag(prefix)` (= `_prefixes[prefix]`), `getLeafUnder(prefix)` (find a tag starting with `prefix..delimiter`, return the leaf — the value-as-leaf read).
- *Why two sets:* `tags` = what was authored (+ value reads); `prefixes` = every root-anchored query that should match (incl. intermediates nobody authored). See the tag design notes.

### `managers/anatomyHost` — the aggregate query surface
- Holds `_layers` (by id) + `_layerOrder` (sorted by priority, then insert order), resolution caches (`_resolvedSockets`, `_resolvedSurfaces`), callback sets (`_socketCallbacks`, `_surfaceCallbacks`, `_surface{Added,Removed}Callbacks`, `_socketQueryCallbacks`), and weak sets of `_bindings` / `_mounts`.
- `push(instance, options?)` → wraps it in an `AnatomyHostLayer` (priority, category, `allowSocketOverrides`), sorts, fires surface-added, then `_refreshAllSockets`/`_refreshAllSurfaces`. `remove(layerId)` / `clear()` reverse it.
- Resolution (`_resolveSocket`/`_resolveSurface`): walk layers in order; first match wins unless a later layer has `allowSocketOverrides` (then later overrides). Optional `query` can pin a `layerId` or disable overrides.
- Query: `getSocket(s)`, `getSocketNames`, `getSurface(s)`, `getSurfaceNames`. Reactive: `bindSocket`, `bindSurface`, `bindSurfaceAdded/Removed`, and `socket(name, query)` → a **SocketBinding**.
- `mount(config)` → builds a `SocketMount` from normalized endpoints (`_normalizeEndpoint` accepts an `Attachment`, a socket/binding object, an `{instance, socket}` address, or a `{socket, ...query}`).
- **Owns** layers, bindings, mounts. **Does NOT own the pushed instances** — `remove` drops the layer but never deconstructs the instance (the caller owns instance lifetime). Important.
- *Tags are not yet wired here — that's Stage 3 (`getByTag`/`bindByTag` mirroring the socket path).*

### `managers/anatomyHostLayer` — one pushed instance in the host
- `id`, `_host`, `_instance`, `_priority`, `_category`, `_allowSocketOverrides`, `_insertOrder`. `getInstance`, `getPriority`, `setPriority` (re-sorts + refreshes), `remove`.
- A thin wrapper — it **references** an instance, doesn't own it.

### The mount system

- **`components/socketEndpoint`** — the abstract "attachment provider": `getAttachment()` + `bindAttachmentChanged()`. `fromAttachment(att)` makes a *static* endpoint (fixed, never changes). A socket or a binding also satisfies the shape.
- **`components/socketBinding`** — a *reactive* handle to "the socket named X" from a source (the host). It subscribes via `source:bindSocket(name, ...)`, tracks `_socket` as layers change, and re-forwards attachment changes. `getSocket`, `getAttachment`, `bindSocketChanged`, `bindAttachmentChanged`. Created by `host:socket(name, query)`.
- **`components/socketMount`** — creates and maintains a `RigidConstraint` between two endpoints' current attachments. Subscribes to both endpoints; `_reconcileConstraint` builds the constraint when both attachments exist, sets `Attachment0/1`, toggles `Enabled`. `setEnabled`, `refresh`, `isConnected`, `deconstruct` (destroys the constraint).

**Mount flow (e.g. weld a weapon grip to a rig hand):**
```
host:mount({
  from = weaponGripAttachment,        -- static, or a binding
  to   = host:socket("rightHand"),    -- live binding that tracks the rig's hand socket
})
-- → SocketMount makes a RigidConstraint(from.attachment, to.attachment)
-- → if "rightHand" retargets (a layer overrides it), the binding updates,
--    the mount reconciles, the constraint re-points. Fully reactive.
```

---

## Part 3 — Ownership map (who owns what)

```
Caller
 └─ owns AnatomyTemplate (immutable; reusable)
 └─ owns AnatomyInstance(s)          ← created via template:instantiate/wrap
       └─ OWNS AnatomySocket / AnatomySurface / AnatomyPart / AnatomyTaggedElement
              (builds them, stores them, deconstructs them; each holds _owner → this instance)
 └─ owns AnatomyHost
       ├─ owns AnatomyHostLayer(s)   ← references (does NOT own) the pushed AnatomyInstance
       ├─ owns SocketBinding(s)      ← from host:socket(...)
       └─ owns SocketMount(s)        ← from host:mount(...)
```

Key rules:
- **An instance owns its elements.** Element lifetime == instance lifetime. Every element stores `_owner` = the instance.
- **The host does NOT own instances.** `push` wraps, `remove`/`clear` unwraps — neither deconstructs the instance. Whoever created the instance must deconstruct it.
- **The host owns bindings + mounts** (weak sets), and deconstructs them on `host:deconstruct()`.
- **A layer references an instance** (no ownership).

---

## Part 4 — Observations & cleanup candidates (not in scope now — flagging only)

1. **`_owner: any` everywhere.** Every element (`anatomySocket`, `anatomySurface`, `anatomyPart`, `anatomyTaggedElement`) stores `_owner: any` and takes `owner: any` in `new`/`fromDescriptor`. It is always the owning `AnatomyInstance`, but it's untyped. The reason is a require cycle (instance type ↔ element types); the honest fix is a minimal owner interface type (e.g. `{ getTemplate, _root, _resolvePath }`) the elements depend on, breaking the cycle without `any`. **Highest-value type cleanup in the package.**
2. **`getTagPathDelimiter` reaches `owner:getTemplate()._config.tagPathDelimiter`** (taggedElement) — a duck-typed reach into the template's private `_config`. Works, defaults to `.`, but couples the element to template internals. Cleaner: pass the delimiter in at build time. (Tie this fix to #1.)
3. **Parts: VERIFIED UNUSED.** `AnatomyPart` is just "a named handle to one instance." Confirmed dead end-to-end: (a) the package never consumes parts (no host-level part API; the host only resolves sockets/surfaces), and (b) the consumer never sets `partAttribute` in any recognize config nor calls `getPart`/`getParts` — so `_parts` is always an empty table in practice. The entire path (def `PartDescriptor`/`PartName`, the `recognize` part-branch, `anatomyInstance` `_parts`/`_buildPart`/`getPart`/`getParts`, the `anatomyPart` component) is removable with zero risk, or folds into tags (a part = a tagged instance with no value), exactly like surfaces. Do it in the cleanup pass alongside surface removal.
4. **Surface is mid-removal** (Stage 4) — superseded by tags. Until removed it shares the `<TSocketName, TSurfaceName>` generic with tags (the Stage-1/2 `TSurfaceName`-as-`TagT` reuse), which collapses to `<SocketT, TagT>` in Stage 5.
5. **`AnatomySocket._setAttachment` is reserved/unused** ("future live-socket mode"). Dead today; keep only if that mode is real, else drop.
6. **`getInstance` on socket/part/taggedElement doesn't always guard `_destroyed`** consistently (taggedElement/socket can return a stale/`nil`-as-`Instance` post-deconstruct). Minor; align the destroy-guards.

**Net:** the architecture is sound and tight — template/instance/host is the right spine, the layer/override resolution and the endpoint→binding→mount chain are clean and reactive. The debt is concentrated and contained: the `_owner: any` cycle (#1, which also resolves #2), and the "do we need parts / surface" footprint reduction (#3, #4). Both are bounded cleanup passes, safe to do after the current tag work lands.
