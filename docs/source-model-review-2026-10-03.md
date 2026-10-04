# Source-model checkpoint — 2026-10-03

Historical checkpoint: the watcher and unordered-tag API below is superseded by [direct subscriptions](./direct-subscriptions-review-2026-10-04.md).

Non-YouTrack task in `C:/Users/edwar/Documents/RobloxProjects/anatomy`, branch `main`.
The accepted performance checkpoint was committed first as `73d3b5d` (following API
checkpoint `3738a5a`). This source-model continuation remains uncommitted for review.
Plinth and VMMO source/dependencies are untouched; no push was performed.

## Accepted API narrowing

- `anatomyTemplate.new(asset, options)` now performs recognition. The former public
  descriptor-input constructor and `recognize` name are gone, with no compatibility alias.
- Template/instance IDs and host registration IDs are removed. Category/metadata retain
  their existing independent meaning. Descriptor collections remain private; recognized
  descriptors and construction records retain the earlier allocation improvements.
- `getTags` on an individual tagged element returns the shared frozen set, or a shared
  frozen empty set after retirement. There is no top-level tag-vocabulary getter.
- The public `AnatomySource<SocketT, TagT>` port provides `getSocket`, `getTagged`,
  `bindSocketChanged`, `bindTaggedAdded`, and `bindTaggedRemoved`. Instances and hosts
  implement it directly. Source events enumerate initial membership when requested.
- `push(source, priority?)`, `remove(source)`, and `setPriority(source, priority)` use
  source table identity. One registration per source per host; sources may have multiple
  parents. Registrations hold strong source references and borrow source lifetime.
- Public layer handles/options, layer command ports, socket-name/bulk socket enumeration,
  traversal methods, first/last tag helpers, selector IDs, and override switches are removed.
- Watchers follow one host name. Mounts retain their previously accepted explicit-attachment API.

## Composition and update behavior

Socket priority is highest-first, with later registration winning ties. A child host
resolves internally and contributes its output as one parent-priority group. Direct and
indirect host cycles are rejected using the package hosts' existing source arrays.
Opaque custom providers must not conceal cyclic feedback behind another object.

Each registration retains two contribution maps and three subscription disconnects.
Initialization stages and validates membership before publishing; failures disconnect
acquired listeners and leave the host unchanged. New socket events resolve only their
name. Push/remove/repriority visit only names supplied by the changed registration.
Source-wide observers are notified only when the selected socket identity changes.

Tags are an identity-deduplicated union, with reference counts for shared contributions
through multiple children. Adding/removing another route to the same element does not
emit a false membership change. Host tag query order is now explicitly unspecified;
callers must not rely on first/last positions. Static instance query order remains its
recognized element order. Host priority has no meaning for tag union membership.

Sources must be detached from every parent before destruction. Source destruction is not
an observable removal event. Host teardown releases subscriptions/watchers/mounts without
destroying borrowed sources. External callbacks that update a mount must be disconnected
before that mount or its host is torn down.

## Allocation implications

No push-options table, ID string, layer object, source adapter, or per-socket candidate
record is created. Registration retains one record plus two maps; push/remove use one
short-lived tag-notification array to commit membership before running callbacks.
Disconnect functions are closures, not free allocations. Incremental source events and
reprioritization create no explicit Luau tables in the current implementation, excluding
consumer callbacks and runtime capacity growth. Tag queries still return an independent
array. Frozen `getTags` reads allocate no tables.

The earlier allocation report describes checkpoint `73d3b5d`; its host-refresh formulas
are historical after this architecture change. No profiler-based speed/heap claim is made.

## VMMO integration still required

- Change template-cache construction from `recognize` to `new`; use typed unknown-input
  socket/tag guards as previously documented.
- Retain source references in CharacterRig; replace string-ID/layer-handle registration,
  removal, and repriority with source-based host operations.
- Query a concrete source directly when former code specified a layer ID. For a changing
  subgroup, retain a child host and watch that group's resolved name.
- Rename `getByTag` queries to `getTagged`. Prefix-filter source tag events with `hasTag`.
  Audit `CharacterRig.getSurface`: its former last-array-element selection is not a
  priority guarantee under the new union contract. The game must choose any desired
  precedence explicitly; no silent integration is made here.
- Keep the prior SocketWatcher and explicit Attachment mount migration. VMMO package pins
  and all those callers remain unchanged until the separate integration task.

## Verification

The pre-change full `src` + `dev` new-solver analyzer passed. The first changed run found
one shared-empty-tag-table generic annotation and an obsolete dev helper; both were fixed.
The second run passed with zero diagnostics. The final full `-Check all` run also passed:
zero analyzer diagnostics in every touched file; Selene with zero errors/warnings/parse
errors; StyLua; behavioral tests; package/dev Rojo builds; and VitePress docs build.
Studio behavior remains unverified; headless constraints are simulated property sinks.

New source tests exercise actual instances and hosts for generic inference, root and
same-named-sibling path resolution, frozen tags, duplicate registration, equal priorities,
nested socket replacement/fallback, direct/indirect cycles, shared tag reference counts,
failed initial validation, reentrant removal, borrowed teardown, and affected-name updates.
A provider probe verifies that one socket change does not query the source again or notify
unrelated socket names. Existing explicit-mount tests and 20 watcher cleanup cycles remain.
The Studio demo and its six original behavioral groups were migrated to the new API.

Removal of the four empty anatomyHostLayer implementation/type directories was blocked by
automatic approval review without a specific reason. The tracked module deletions are complete;
empty local directories remain and are not represented in Git. No cleanup bypass was attempted.
