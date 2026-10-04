# Direct subscriptions and ordered tagged selection

Status: uncommitted package revision awaiting human review. VMMO is unchanged and remains pinned to
`cf423e01ebbcde34762f0889f7d87c7bb15682b0`. Tracking: [VMMO-22](https://voxelmmo.youtrack.cloud/issue/VMMO-22).
Workspace: `C:/Users/edwar/Documents/RobloxProjects/anatomy`, existing `main`, same base revision.

## Consumer migration

Replace `host:watchSocket(name)` plus `watcher:bindSocketChanged` with
`host:bindToSocket(name, callback, runInitially)`. Replace watcher reads with `host:getSocket(name)`
and release its returned disconnect instead of destroying a watcher. The watcher implementation,
type and public export are removed; no compatibility layer remains. Mounts still accept explicit
attachments; owners update them from their subscriptions. See `dev/client/bindMountSockets.luau`.

`getTagged(prefix)` retains all matching elements, ordered lowest-to-highest precedence. At each host,
higher priority wins, with later registration breaking ties; a nested host contributes its internally
ordered result as one group. Instances retain recognition order. `getTopTagged(prefix)` returns the
last match from the winning source without a temporary array. Shared leaves appear only at their
highest-precedence occurrence. This deliberately replaces previously unspecified host result order.

`bindTopTaggedChanged(prefix, callback, runInitially)` installs one shared selection per host/prefix.
It observes that same prefix on children only while needed, including children with no current match.
Nested priority-only changes propagate without pretending they added or removed an element. On final
release, child subscriptions and cached selection are discarded. Unrelated-prefix mutations do not
query this selection. Removal of its winner re-resolves fallback candidates. No perpetual candidate
cache is added. Initial delivery includes nil, follows subscription registration, and rolls back the
subscription if it throws. Host teardown publishes removal before destroying owned mounts.

Custom AnatomySource providers must add direct socket binding and top-tag query/binding, retain stable
source-local ordering, and keep the top result equal to the final entry of getTagged. Static instances
have fixed membership, so their subscriptions require no retained tables. Remove static/custom sources
from parents before destroying them; host teardown itself is observable by parent hosts.

VMMO can subsequently delegate its priority selection to Anatomy and remove its mirrored priority map.
Its component-level getSurface currently selects the first local match whereas host getSurface selects
the last match in the winning component. Preserve that difference or explicitly review its change when
renaming the VMMO APIs; this package change does not silently migrate either consumer behavior.

## Allocation accounting

- Direct sockets: one callback table per observed host/name; no per-consumer watcher or callback table.
- Top tagged: three tables per observed host/prefix (selection, callback set, child-disconnect map), shared
  by listeners. Nested hosts activate the same prefix recursively. No per-listener table is introduced.
- Two maps per host retain these lazy entries. Disconnects and forwarding callbacks are closures.
- Single-result queries create no explicit tables. Bulk queries still allocate an output array and one
  deduplication map per host, plus each source's independent query array. No profiler measurements claimed.

## Verification

Pre-change and final full package/dev solver-V2 analysis: zero diagnostics in both runs, including all
touched source and dev modules. The first post-change analysis found one optional captured selection
variable at the subscription closure boundary; retaining an explicitly typed nonoptional local fixed it
without any casts or weakened contracts. The second analysis and final all-checks run passed.

`scripts/verify/run.ps1 -Check all` passed: StyLua; Selene (0 errors, 0 warnings, 0 parse errors);
solver-V2 analysis; Lune caller/contract tests; both Rojo builds; and VitePress build. Tests cover direct
subscription cleanup over 20 mount cycles, initial nil, nested priority-only changes, equal-priority
ordering, shared-leaf deduplication, removal/fallback/recovery, lazy shared subscriptions, final listener
release, unrelated-prefix query counts, callback-error rollback, reentrant removal, and nested teardown.
Existing guard, ownership and explicit constraint tests also passed. No generated Lune tree is created.

Automatic approval review rejected native removal of the newly empty
`src/anatomy/components/socketWatcher/{shared/}` and
`src/anatomy/types/components/socketWatcher/{shared/}` trees with "blocked by policy" and no specific
reason. Their tracked source files are deleted, but four empty local folders remain. Deletion was not
retried. Older empty anatomyHostLayer trees from the previous checkpoint are unchanged.

 Behavioral coverage executes real package modules and the owner mount helper;
headless RigidConstraint remains a property sink, not a proof of Studio physics. Studio verification
of actual constraints and the interactive demo remains pending. No commit, push, or VMMO update authorized.
