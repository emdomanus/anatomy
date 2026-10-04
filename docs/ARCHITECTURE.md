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
socket changes, tag additions, and tag removals. Synchronous initial subscription delivery supplies
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
Host `getTagged(prefix)` filters the current union and returns an independent array; its cost is
linear in current union membership. Results are unordered and are unaffected by whether listeners
exist. Priority affects sockets, not tags.

Mutation commits registration/tag state before notification. Publication checks the current state
between callbacks so reentrant removal or replacement does not continue emitting stale selections.
Removal detaches subscriptions before reconciling output. `clear` snapshots source identities so
new registrations created by callbacks are not accidentally swept into the same clear operation.

## Watchers, mounts, and teardown

A SocketWatcher filters the source socket stream by one name and has one socket-change callback set.
It does not own its selected socket. An AnatomySocket always has an Attachment until retired.
SocketMount owns one reusable RigidConstraint with explicit attachments, enabled intent, and parent.
It does not know about sources or watchers. Rendering owners subscribe externally and update it.

Remove sources from all parents before their final teardown; source deconstruction is not an
observable membership operation. Remove instances from hosts and clear/destroy their attachment
mounts before retiring their sockets. Disconnect owner callbacks before mount/host teardown.
Host teardown releases its watchers/mounts and all child subscriptions but never destroys sources.

## Allocation tradeoff

The previous recognition/instance improvements are preserved. Frozen tags remove per-read cloning.
Source registration now retains one record and two contribution maps, plus disconnect closures;
this retained state allows incremental updates and nesting. There is no options table at push.
Push/remove currently use a temporary tag-notification list to finish membership changes before
calling observers. Priority changes and individual source socket/tag events allocate no explicit
Luau tables in Anatomy. Consumer callbacks, closures, engine allocations, and array capacity growth
are separate costs; this is source accounting, not a profiler claim.

## Verification

The guarded runner covers formatting, lint, full new-solver analysis, behavioral tests, package/dev
Rojo builds, and docs. Source tests exercise real instance/host callers for constructor inference,
frozen tags, duplicate-name paths, identity registration, priority ties, nested propagation, cycles,
shared tag contributions, rollback, reentrant removal, borrowed lifetime, and incremental event scope.
The existing explicit-mount contract tests remain. The Studio demo and six behavioral groups use
the new API. Headless constraints are simulated property sinks; Studio verification is pending.
