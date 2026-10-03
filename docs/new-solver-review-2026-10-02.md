# New-solver review — 2026-10-02

The socket/watcher and explicit-mount checkpoints below were accepted and committed
as `3738a5a`. The subsequent performance work and current verification receipt are in
[the allocation checkpoint](./allocation-review-2026-10-03.md).

## Historical checkpoint: explicit attachment mounts — 2026-10-03

The user authorized simplifying the remaining mount API. This continues the uncommitted
socket/watcher redesign below in the same checkout. Plinth and VMMO remain untouched;
other allocation work stays deferred. No commit or package-pin change was made.

- `Anatomy.socketMount.new(from: Attachment?, to: Attachment?, options?)` and
  `host:mount(from, to, options?)` create one constraint immediately, even for empty inputs.
- `setAttachments(from, to)` reuses that constraint. A missing side disables it;
  restoring both respects the caller's requested enabled state.
- `setParent(parent: Instance?)` is explicit. Omitted constructor parent means nil,
  and attachment/enabled updates never infer or restore a parent.
- Removed polymorphic mount inputs, `SocketMountInput`, `refresh`, watcher subscriptions,
  automatic parenting, lazy constraint construction, and duplicated attachment caches.
  Mount construction allocates one Luau object table and one Roblox constraint; it
  does not allocate a default options table or retain caller options.
- `isConnected` reports configured enabled/two-attachment state, not physical activity
  or ancestry. The owner handles visual parenting and mount validity policy.
- Reactive wiring lives in callers. `dev/client/bindMountWatchers.luau` demonstrates
  two watcher subscriptions updating a plain mount; it is not a published abstraction.
  Release these subscriptions before mount/host teardown. Host-created mounts remain
  host-owned; mounts own only their constraint and borrow the attachments.

VMMO migration must extract `socket:getAttachment()` for concrete mounts and explicitly
wire watcher changes into `setAttachments` where reactive retargeting is needed. Supply
the intended constraint parent, manage visual parenting in the renderer, and disconnect
callbacks before destroying mounts. The earlier watcher/guard migration requirements
still apply. Consumer source and dependency pins have not been changed.

Verification: baseline full `src` + `dev` new-solver analysis passed. The first changed
run found one test-only stale property refinement across `setParent`; boolean checks
were routed through an assertion helper without changing their runtime expectations.
The second changed run passed with zero diagnostics. Final behavioral tests passed,
including stable constraint identity, explicit parenting, enabled intent, rejected
post-destruction mutation, owner-driven visual removal, and subscription cleanup over
20 cycles. StyLua and Selene passed (zero errors/warnings/parse errors); package/dev
Rojo builds and the VitePress documentation build passed. Studio physics verification remains pending: the headless
constraint is a simulated property sink.

## Historical checkpoint: concrete sockets and socket watchers

The preceding solver/conventions checkpoint was accepted and committed locally as
`96461b7e79bd99600fea5b68ff64f868bd91a32f`. This continuation starts from that clean
commit in the same Anatomy checkout on `main`; it is a non-YouTrack task. The user
authorized only the socket/watcher redesign, not the other allocation proposals.
These continuation changes are uncommitted. Plinth and VMMO remain untouched.

- `AnatomySocket:getAttachment()` returns a required `Attachment`. Concrete sockets
  have no attachment event or callback storage. Retired sockets reject attachment access.
- `SocketWatcher` replaces `SocketBinding`. `host:watchSocket(name, layerId?,
  includeOverrides?)` follows an address, returning a socket or nil through `getSocket`
  and one `bindSocketChanged` callback set. Its constructor stays internal and receives
  the host directly as `SocketSubscription`; no per-watcher source adapter is allocated.
- Socket selectors are positional. Tag selection takes an optional layer id. The
  query/address records, endpoint interface/adapter/lifecycle port, and now-unused
  instance-address lookup port have been removed.
- Both mount constructors take `(from, to, options?)`. Inputs are concrete sockets,
  watchers, or raw attachments. Mounts borrow all inputs and release only their own
  subscriptions. Failed construction releases any subscription already installed.
- Remove instances from all hosts before instance teardown; destroy mounts using
  concrete sockets before those sockets retire. Host removal produces the watcher's
  nil/replacement notification. External engine destruction/streaming is not observed.
- The dev examples and all six existing Studio assertion groups were migrated to this
  API. Contract coverage exercises typed watcher/socket inputs, different name vocabularies,
  overrides, priority changes, layer replacement, nil selection, static mounts, watcher
  teardown, borrowed ownership, and failed mount construction. The headless suite checks
  subscription cleanup over 20 cycles using actual package modules.

Verification: baseline full `src` + `dev` analyzer passed. The first changed-tree run
found leftover socket teardown lines referring to the removed callback storage; these
were removed. Both subsequent full analyzer runs passed with zero diagnostics. The
initial lint run found four missing dev assertion messages; the final lint run passed
with zero errors, warnings, or parse errors. Behavioral tests, StyLua, package/dev Rojo
builds, and VitePress build passed. Studio has not run; headless constraints remain
simulated property sinks, not a physics verification.

VMMO integration must rename binding type annotations to `SocketWatcher`, change
`host:socket(name, query)` to `host:watchSocket(name, layerId, includeOverrides)`, and
replace attachment subscriptions with socket subscriptions that read `socket:getAttachment()`
when non-nil. Flatten query arguments in rig/view forwarding signatures. Convert mount
address records to explicit caller-owned watchers or concrete sockets, pass mount inputs
positionally, and release created watchers with their owning render/controller. Existing
guard integration requirements from the preceding checkpoint still apply. Package pins
and consumer code have not been updated here.

Broader performance work is deferred: descriptor copies, recognition scans, instance
construction records, host refresh copies, tag lookups, weak metatables, and mount
defaults retain their previous implementation.

## Historical solver/conventions checkpoint

**Solver-clean; automated checks pass. Ready for human review, with Studio verification pending.** Non-YouTrack task.

## Completed repair checkpoint

The user authorized three new attempts after the preceding blocked handoff. Two analyzer
runs were used, both successful: the first cleared the outstanding type errors; the second
confirmed the final source after resolving the remaining Selene warning.

- Restored the template contract's `AnatomyInstance<TemplateT, SocketT, TagT>` alias.
- Declared recognition/host options and instance policy fields read-only for their consumers.
  This allows the typed guard functions to supply both constructor generics and accurately
  models the retained frozen snapshots. No `any` escape or diagnostic suppression was added.
- Built the frozen recognition snapshot from a complete initializer instead of mutating a
  clone through a read-only contract.
- Used `table.clone` with a specific borrowed-socket snapshot assertion for `getSockets`,
  preserving the independent collection and hiding child-owner teardown authority.

Final checkpoint results:

- Full `src` + `dev` new-solver analysis: zero diagnostics, including the constructor-inference fixture.
- Selene: zero errors, zero warnings, zero parse errors.
- Headless behavioral suite: passed, including 20 owned mount-subscription cycles and borrowed
  endpoint preservation. The constraint property sink remains simulated; no Studio physics claim.
- StyLua, package/dev Rojo builds, and VitePress documentation build: passed.
- Changes remain unstaged/uncommitted. No VMMO integration or allocation-optimization pass was performed.

Real constraint/physics behavior, the dev UI and the full Studio assertion harness still require
human Studio verification. The integration instructions below remain applicable. The stopped
attempts recorded later are historical and are superseded by this completed repair checkpoint.

## Guard/conventions continuation — current handoff

Continued in `C:/Users/edwar/Documents/RobloxProjects/anatomy`, branch `main`, base
`a6ecdee7eeb045c0c7c347b27ca2ec97087ad4c8`. All earlier migration edits and the user's
in-progress dev-helper edit were present at entry. Nothing was staged or committed.
Plinth and VMMO source/dependencies were not modified. Allocation optimization is deferred.

Implemented candidate:

- Both host and recognition options require socket and tag guards. They alias the standalone
  Guard package's `GuardFn<T>` (`unknown -> T`, throwing on rejection). Anatomy now pins the
  same Guard commit already used by VMMO, `6d6eab5c06e5b0e68408e9bd6ef1a985cc16806f`;
  Pesde install was run only in Anatomy. Host insertion validates all incoming names/tags.
- Canonical types/utilities have explicit shared domains; category forwarding barrels were
  removed. The package root selects exact public leaves. Callback storage has typed packs.
- Added endpoint, subscription, socket lookup, layer command and endpoint lifecycle ports.
  Layers no longer hold the host Impl; children no longer retain unused parent Impl generics.
  Instance construction receives explicit data rather than accessing a template's private config.
- Borrowed sockets/tagged elements no longer expose teardown. Layer identities are read-only,
  registration ordinals guard stale operations, and internally acquired mount bindings are released.
  Socket/binding teardown publishes terminal nil attachments. Descriptor/config snapshots are frozen.
- Added actual-package headless behavioral coverage plus a Studio/public-inference fixture;
  retained the original six Studio groups and their assertions. Lune 0.10.5 is pinned for the new gate.
  Package/dev Rojo layouts now represent the src module beside its Pesde dependency folder.
- Updated README, architecture and type documentation. No allocation optimization pass was performed.

### Previous stopped attempts and now-resolved blockers

The three-attempt stop rule was reached. No fourth analyzer attempt was made, and source
editing stopped after the third result. The following errors include defects introduced in this pass;
they are not accepted inherited debt.

1. Pre-change guarded analyzer: the user's unfinished dev helper at line 105 produced a syntax
   error and the existing `AnatomyHost<string, unknown>` result mismatch. This was the baseline.
2. First migrated guarded analyzer: Rojo refused the new `anatomy` folder without `$className`.
   Folder classes were subsequently added to both project mappings.
3. Final guarded analyzer: produced diagnostics, including these root locations:
   - `src/anatomy/types/components/anatomyTemplate/shared/anatomyTemplate.luau:8`:
     the local `AnatomyInstance` alias lost its three generic parameters during alias normalization.
     Its uses at lines 38 and 42 consequently fail, with downstream cascades.
   - `src/anatomy/components/anatomyTemplate/shared/anatomyTemplate.luau:266` and `:268`:
     frozen policy/options have read-only properties, while their canonical retained contracts
     still require writable properties. Distinguish construction options from retained policy or
     make the appropriate consumed fields read-only; do not erase the mismatch with `any`.
   - `dev/client/contractTests.luau:32` and `dev/client/init.client.luau:100`:
     guard-based constructor calls still fail inference/compatibility. Retest after repairing the
     canonical aliases and option variance. Do not assume the new API is solver-clean.
   Full output also included downstream template/instance compatibility failures; no reliable
   normalized diagnostic count was captured, and these locations are not claimed exhaustive.

Other results:

- Explicit-file formatting passed after adding `syntax = "Luau"` to StyLua configuration.
- Headless tests: first run failed because Lune cannot clear a reflected constraint attachment
  reference to nil. The harness now models only the constraint property sink; source behavior and
  assertions were not weakened. Second run passed guard rejection, prefix queries, immutable
  descriptors, retired handles, terminal endpoint notifications, 20 mount-owned subscription cycles,
  and borrowed endpoint preservation. This pass preceded the final storage-initialization edits;
  it is not a final-tree behavioral certification.
- Selene's first run reported four errors and one manual-clone warning. The identified missing
  assertion messages and stale `return Path` were corrected. No final lint rerun was performed
  before the analyzer stop; the warning concerns an explicit owned-to-public collection copy.
- Final Rojo builds and documentation build have not run for this continuation. Studio has not run.
  The headless constraint sink does not prove real physics, engine teardown, or UI behavior.

### Required integration edits after package acceptance

In VMMO, change `CharacterRig` construction to pass both typed guards (use the socket API's
`guards.rigSocket`, not its boolean `isRigSocket`, and the typed surface guard). Update recognition
options in `anatomyTemplateCache` the same way; those files were only read. Host option aliases now
take both generics. Callers receiving borrowed socket/tagged-element results may not destroy them.
Installed consumers keep their Pesde package-link import; only this package's dev model uses `.src`.

The previous narrow-migration receipt below remains historical context, not current verification.

## Baseline and tooling

- Starting `main` HEAD: `a6ecdee7eeb045c0c7c347b27ca2ec97087ad4c8`; clean index/worktree.
  No AGENTS.md, local skills, prior solver receipt, or headless behavior suite found.
- Historical configuration: Aftman pins only Rojo 7.7.0-rc.1 (confirmed actual version
  through the Rokit shim). No reproducible analyzer/formatter/linter pins or explicit solver.
- Replaced aftman.toml with rokit.toml: Rojo 7.7.0, Luau-LSP 1.70.1, StyLua 2.5.2,
  Selene 0.32.0, Pesde 0.7.4+registry.0.2.3. Rokit 1.2.0 is already installed.
  Official GitHub release metadata checked at execution; no fallback pin used.
  [Rojo](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0),
  [Luau-LSP](https://github.com/JohnnyMorganz/luau-lsp/releases/tag/1.70.1),
  [StyLua](https://github.com/JohnnyMorganz/StyLua/releases/tag/v2.5.2),
  [Selene](https://github.com/Kampfkarren/selene/releases/tag/0.32.0),
  [Pesde](https://github.com/pesde-pkg/pesde/releases/tag/v0.7.4%2Bregistry.0.2.3).
- Added setup/verification scripts, ignored local outputs, and matching editor/CLI
  `LuauSolverV2=true`. Verification resolves tools explicitly from `~/.rokit/bin` and
  places that directory first on PATH. No installed dependency changes or Pesde install.
- npm workflow unchanged: Node 24.1.0, npm 11.6.2, installed VitePress 1.6.4.
  Lock hashes: Pesde `E669D05FD562E560A91A13F65A9FE63DA23DF53CA4BB320316A8462EEAFBD628`;
  npm `0B321A59A1E33A42C4A9130DA5DD0E32D90DAFDA8629B925D2978518E3C7E4C7`.
- Baseline was captured on unchanged source with the newly pinned tools: analysis
  failed (166 headers), full formatting failed, lint 0 errors/2 warnings, both Rojo
  builds and docs passed. These are a new-toolchain source baseline, not proof of
  a historical analyzer regression. Definitions remained fixed, SHA-256
  `2B0DF788DC3FD1B572E71EE7FE9E1C55CC23882AFBD5024AECDEC30D9BD7520F`.

## Changes

- Typed empty array allocations in path reversal and template recognition.
- Explicit canonical self types for host/layer construction and comparator parameters;
  retains initialization order, layer ordering, ownership, and mutation behavior.
- A private read-only endpoint inspection record in the host's existing canonical
  type module replaces the unstructured endpoint probe; existing attachment, endpoint,
  instance-address, and host-address branch order is preserved. Public exports unchanged.
- Callback iteration carries an explicit callable annotation, retaining the existing
  variadic callback utility's erasure. No new blanket casts or suppressions.
- Dev harness: recognize-options and address annotations, attempted concrete generic
  host-constructor view, equivalent UDim2 offset constructors, and an Activated adapter
  that drops Roblox event arguments before calling the existing no-argument callback.
- Formatted only the seven edited Luau files. Existing assertions and expected results
  remain unchanged. No production transform, constraint, lifecycle, or serialization logic changed.

## Results and stop

Analyzer attempts: 166 headers before repairs; 14 after the first repair; **one** after
the second repair. The last diagnostic is in `dev/client/init.client.luau:104`:
the generic `<SocketT, TagT>` host factory cannot be assigned to the concrete
`(AnatomyHostOptions<string>?) -> AnatomyHost<string, string>` helper. The tag generic
is absent from the constructor inputs. Stopped after the third failed attempt as requested.
The final full-package run emitted no production-source diagnostics, but the gate still fails.

Final lint: 0 errors/0 warnings/0 parse errors. Formatting of all edited Luau files passed;
untouched files have baseline full-tree formatting debt. Package and dev Rojo builds passed.
Documentation build passed after the receipt was added. No generated transport exists.

The existing six Studio assertion groups were not executed. They cover recognition/policy,
guards, wrap/instantiate ownership, static attach, reactive socket/mount updates, and override
resolution. Rojo build success and clean production analysis do not prove these behaviors.
Run these groups, rig/addon swaps, transform/constraint behavior, and teardown in Studio
before accepting or integrating. No place or asset was uploaded or modified.

Temporary evidence: `C:/Users/edwar/AppData/Local/Temp/vmmo-package-solver-2026-10-01/`
(`anatomy-*`, original Aftman/editor settings, clean starting diffs, and official release metadata).
Task changes remain unstaged/uncommitted.

## VMMO follow-up

Resume the generic constructor compatibility work in a new authorized pass; no material API
change is proposed yet. Public type shapes are unchanged by this candidate. Later integration
must check the same inference boundary in these paths under `src/shared/`:

- `libraries/character/rig/managers/characterRig/shared/characterRig/init.luau` constructs
  `RigAnatomyHost`; its concrete socket/tag vocabulary is declared in
  `libraries/character/rig/types/managers/characterRig.luau`.
- `libraries/character/rig/utils/anatomyTemplateCache.luau` recognizes templates.
- `libraries/character/visualizer/views/characterPresentationHost/shared/characterPresentationHost/init.luau`
  and `services/characterService/components/carryTransformRelationship/shared/aCarryTransformRelationship.luau`
  consume endpoints and transforms.

Expect explicit factory specialization/address annotations if the final solver solution needs
them; preserve legitimate writes and instance ownership. VMMO source, pins, locks, installed
packages, and generated state were not changed. Integrate only after the blocker and Studio gate clear.
