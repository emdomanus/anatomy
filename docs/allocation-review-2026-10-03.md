# Anatomy allocation checkpoint â€” 2026-10-03

Historical checkpoint: the watcher and unordered-tag API below is superseded by [direct subscriptions](./direct-subscriptions-review-2026-10-04.md).

This is a historical checkpoint. The current contract and verification are in the
[source-model checkpoint](./source-model-review-2026-10-03.md).

Non-YouTrack task, local checkout `C:/Users/edwar/Documents/RobloxProjects/anatomy`,
branch `main`. Accepted socket/watcher/explicit-mount changes were committed as
`3738a5a` before this work. This performance continuation is uncommitted. Plinth,
VMMO source, and consumer dependency pins remain untouched.

## Changes

- Retain one frozen construction record per template; `wrap`/`instantiate` no longer
  allocate options or clone descriptor collections on each call.
- Recognize with one descendant array; reverse paths in place. Freeze recognized
  descriptors directly. Public `anatomyTemplate.new` still snapshots caller input.
- Add synchronous read-only traversal and first/last-tag lookup to existing objects;
  host ingress and refresh no longer collect temporary per-instance snapshots.
- Collect watched tags directly into their destination set. Keep fresh refresh sets
  for nested callback safety; no shared mutable scratch or object pooling.
- Share the frozen weak-key metatable between host registries and across hosts.
- Keep existing collection snapshot semantics, ordering, priority/override behavior,
  guard checks, cleanup, and the accepted socket/watcher/mount API.

Traversal callbacks must not destroy or structurally mutate the instance being traversed.
Use snapshot getters when mutation during iteration is required. This pass adds methods,
not new wrapper objects, adapters, or port types.

## Source-derived table counts

These are counts of table constructors, clones, and arrays returned by Roblox hierarchy
queries in the source, **not profiler measurements or elapsed-time claims**. They exclude
closures, Roblox instances, module initialization, consumer guards/callbacks, and engine
internals. Caller-created options tables are excluded unless stated. Baseline is `3738a5a`,
after the already-accepted removal of socket callback storage and watcher/mount adapters.

`S` = sockets; `T` = tagged elements; `P` = unique indexed prefixes; `D` = sum of
socket and tag descriptor path depths. `L` = layers after a host operation;
`W` = watched tag prefixes. Nested caller operations have their own additional costs.

| Operation | Before | After |
| --- | ---: | ---: |
| Cached template `wrap` / `instantiate` | `7 + S + T + P + D` | `4 + S + T + P + D` |
| Host construction | 12 | 10 |
| Host push | `4 + T + L + W(L + 2)` | `2 + W` |
| Remove existing layer / change its priority | `1 + L + W(L + 2)` | `1 + W` |
| Unwatched host tag collection across layers | `L + 1` | 1 |
| Watched host tag collection | 1 | 1 |
| First tag subscription for a prefix | `L + 5` | 4 |
| Additional tag subscription to that prefix | 0 | 0 |
| Instance single match via snapshot vs `getFirstByTag`/`getLastByTag` | 1 | 0 |
| Host single match via snapshot vs `getFirstByTag`/`getLastByTag` | `L + 1`, or 1 when watched | 0 |
| Instance/tag traversal methods | N/A | 0 |

An instance policy adds one descendant array per construction, unchanged. Each template
retains one extra construction-record table. Existing `getByTag` callers keep allocating
a snapshot until migrated to a single-result method or traversal. First/last selection
matches the corresponding end of `getByTag(...)`; watched prefix order remains unspecified.

Example: `S=10, T=20, P=8, D=60` gives cached construction **105 â†’ 102** tables in
this pass. Compared with the original solver checkpoint's socket callback tables,
the cumulative count is **115 â†’ 102**.

Recognition without metadata or policy snapshots, with valid nonempty tags:

| Component | Before | After |
| --- | ---: | ---: |
| Base tables | 9 | 6 |
| Each socket at depth `d > 0` | `5 + 3d` | `2 + 2d` |
| Each tagged element at depth `d > 0`, `r` nonempty tag tokens | `10 + 3d + r` | `5 + 2d + r` |
| Root socket | 4 | 2 |
| Root tagged element with `r` tokens | `9 + r` | `5 + r` |

Policy and metadata shallow snapshots each add one table, unchanged. Empty/whitespace-only
tag attributes have different parsing costs. Caller-supplied descriptor construction keeps
its defensive copies and adds the one retained construction record.

Watchers and mounts were already simplified in the committed checkpoint: a watcher takes
2 tables plus 1 host callback bucket for the first default-name subscription, or 1 query
entry for an explicit selector. A mount takes 1 table plus 1 Roblox constraint. This pass
makes no further changes to those paths.

## VMMO entrypoints for later integration

Paths are relative to `VoxelMMO/ServiceDev`; VMMO has not adopted these changes yet.

- `src/shared/libraries/character/rig/components/rigComponent/shared/rigComponent/init.luau`:
  `RigComponent.new` â†’ template cache â†’ `template:wrap` â†’ instance construction.
- `src/shared/libraries/character/rig/utils/anatomyTemplateCache.luau`: cache miss â†’
  `anatomyTemplate.recognize`; cache hits avoid recognition.
- `src/shared/libraries/character/rig/managers/characterRig/shared/characterRig/init.luau`:
  `registerComponent` â†’ host push; unregister/priority changes â†’ host refresh.
- `RigComponent.getSurface` uses `getByTag(...)[1]`: migrate to `getFirstByTag`.
- `CharacterRig.getSurface` returns `surfaces[#surfaces]`: migrate to `getLastByTag`,
  not the first-result method. This distinction was verified in the current VMMO source.
  Both eliminate the result table. `getSurfaces` continues to return a snapshot.

The guard, watcher, positional-selector, and explicit-mount migration from the previous
checkpoint is still required alongside the package pin update. No game-side allocation
savings are claimed until that integration happens.

## Verification

Baseline full `src` + `dev` new-solver analysis passed. The first changed run exposed
generic-helper complexity and a zero-based-loop lint diagnostic; helper arguments
were narrowed to their actual inputs, and the loop now starts at one. The second
run identified one mutable path fixture needing its canonical array annotation.
The third run passed with zero diagnostics. A subsequent final full run after
adding last-result selection also passed with zero diagnostics in every touched file.

`scripts/verify/run.ps1 -Check all` passed: StyLua; Selene (zero errors, warnings,
and parse errors); full new-solver analysis; behavioral tests; package/dev Rojo
builds; and VitePress build. `git diff --check` passed. Tests exercise actual package
callers for duplicate-name path resolution, root tags, repeated construction,
public snapshot isolation, external descriptor mutation, first/last result parity,
nested host refresh, and duplicate-layer tag membership. Existing mount/lifecycle
tests also pass. Studio physics remains unverified; headless constraints use a
simulated property sink. No profiler-based timing or heap measurement was performed.
