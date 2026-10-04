# Architecture

Anatomy owns visual asset recognition, concrete socket/tagged-element identity, composition,
and explicit attachment constraints. Game-specific policy and rendering ownership remain in consumers.

## Asset and runtime ownership

`anatomyTemplate.new(asset, options)` scans the root and one descendant array, builds paths,
and freezes the descriptors it owns. Paths are reversed in place. The template retains one frozen
construction record reused by `instantiate` and `wrap`; descriptor shapes are not a public input.
An instantiated model is cloned and owned; a wrapped model is borrowed. Both resolve the captured
paths into concrete sockets and tagged elements. Attributes are not watched after recognition.

Tags are immutable per-element membership. `getTags` returns the frozen set directly, shared across
instances of the template. Retired elements return a shared frozen empty set. Collection queries
return independent arrays and never expose mutable internal registries.

## AnatomySource composition

Instances and hosts directly satisfy the source port: socket lookup, prefix-tag query, source-wide
socket changes, tag additions/removals, and direct named socket/top-tag subscriptions. Synchronous initial subscription delivery supplies
actual membership without public enumeration methods. Static instances have no change-listener
storage; their owner must detach them from all parents before destruction.

A host registers sources by table identity. Registrations are private records containing priority,
registration order, cached socket/tag contributions, and three disconnect functions. The source
key is retained strongly. There are no public layer objects, registration IDs, override switches,
or allocated source wrappers. A source can occur only once within one host and in multiple hosts.

Highest priority supplies the resolved socket; later registration wins ties. Nested hosts resolve
internally, then contribute their result at the parent's priority. An identity-only weak host graph
borrows each host's existing source array to reject direct and indirect cycles without adding a
second child collection or widening the public port. Custom providers must not hide cyclic composition.

## Incremental updates

Initial source subscription stages and validates membership before installing the registration.
Failure releases all acquired subscriptions and publishes no partial registration. No per-socket
entry object is allocated: each registration stores a name-to-socket map.

A child socket event updates its cached contribution and resolves that name against ordered
registrations only. Insertion, removal, and reprioritization reconsider only names supplied by
that registration. The host publishes a socket change only when its selected identity changes.
No collection of every socket name or full-prefix refresh is performed.

Tag changes update an element-identity reference count. The first contribution emits added;
the last contribution emits removed. Shared leaves through multiple child hosts are deduplicated.
Host `getTagged(prefix)` queries sources in precedence order and returns an independent, ordered,
identity-deduplicated array. Shared elements occupy their highest-precedence occurrence. Child ordering
remains local to each child; parent priority ranks child groups. `getTopTagged` returns the last match
from the highest-ranked nonempty source without constructing arrays.

Top-tag selection caches exist only for observed prefixes. The first listener subscribes to that prefix
on child sources; later listeners share the cache and subscriptions. Membership/priority mutations
reconcile affected observed prefixes, and nested priority-only changes propagate through the same
prefix stream. Identity equality suppresses redundant callbacks. Last disconnect releases the child
subscriptions and cache. Unobserved getters scan on demand; observed getters return the cache.
There is no eager index or retained candidate list for every possible tag prefix.

Mutation commits registration/tag state before notification. Publication checks the current state
between callbacks so reentrant removal or replacement does not continue emitting stale selections.
Removal detaches subscriptions before reconciling output. `clear` snapshots source identities so
new registrations created by callbacks are not accidentally swept into the same clear operation.

## Direct subscriptions, mounts, and teardown

`bindToSocket(name, callback, runInitially)` registers directly in a shared per-name callback bucket.
The host retains the source-wide socket stream for composition; consumers need no forwarding object.
An AnatomySocket always has an Attachment until retired. SocketMount owns one reusable RigidConstraint
with explicit attachments, enabled intent, and parent. Rendering owners bind externally and update it.

Remove static/custom sources from their parents before final teardown. Host teardown publishes source
removals and nil/fallback selections before destroying owned mounts, then clears subscriptions. It never
destroys borrowed sources. Release mount-update callbacks before manually destroying a mount. A static
instance's subscription returns a no-op release because its membership cannot change while alive.

## Allocation tradeoff

The previous recognition/instance improvements are preserved. Frozen tags remove per-read cloning.
Source registration now retains one record and two contribution maps, plus disconnect closures;
this retained state allows incremental updates and nesting. There is no options table at push.
Push/remove currently use a temporary tag-notification list to finish membership changes before
calling observers. Priority changes and individual source socket/tag events allocate no explicit
Luau tables in Anatomy. Consumer callbacks, closures, engine allocations, and array capacity growth
are separate costs; this is source accounting, not a profiler claim.

A named socket bucket costs one table per observed name, shared by all listeners, instead of two
watcher tables per consumer. A top-tag observation costs three tables per host/prefix (selection,
callbacks, child releases), shared by all listeners; subscribing through nested hosts activates the
same prefix there. Each host has two empty maps holding these lazy entries. Last release removes an
entry. Discrete top-tag queries allocate no explicit tables. Bulk queries still allocate result arrays,
a deduplication set per host query, and source query arrays; they are not allocation-free.

## Verification

The guarded runner covers formatting, lint, full new-solver analysis, behavioral tests, package/dev
Rojo builds, and docs. Source tests exercise real instance/host callers for constructor inference,
frozen tags, duplicate-name paths, identity registration, priority ties, nested propagation, cycles,
shared tag contributions, rollback, reentrant removal, borrowed lifetime, and incremental event scope.
The existing explicit-mount contract tests remain. The Studio demo and six behavioral groups use
the new API. Headless constraints are simulated property sinks; Studio verification is pending.
