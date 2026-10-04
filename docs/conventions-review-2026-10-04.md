# Anatomy convention cleanup

Follow-up to [VMMO-22](https://voxelmmo.youtrack.cloud/issue/VMMO-22), requested after
the accepted direct-subscription migration. Base: `97e88a993068b21ec0b24aac2e41c60358732ba4`.
Workspace: `C:/Users/edwar/Documents/RobloxProjects/anatomy`.
Branch: `codex/anatomy-conventions-cleanup`. Changes remain uncommitted for review.

## Contracts and ownership

- `getTags()` exposes `{ read [TagT]: true }` and continues to return the existing frozen
  membership table. No clone, wrapper, callback, or additional table is allocated by the getter.
  Retirement still returns the shared frozen empty table.
- `AnatomySource` now owns its complete observation protocol at
  `src/anatomy/types/ports/components/anatomySource/shared/anatomySource.luau`.
  Hosts consume this provider-neutral protocol; hosts and instances implement it directly.
  The unused independent `SocketSubscription` interface and its module are removed.
- Host imports and type names retain their canonical names. Missing optimization headers are
  supplied, and touched type records bind imported types near their requires.
- Caller construction inputs consistently use `RecognizeOptions`; the redundant exported
  `RecognizeConfig` alias is removed. The template's private options snapshot is still captured
  once at construction, with unchanged allocation and ownership behavior.
- Subscription, priority, mount, and teardown behavior is unchanged.

## Consumer integration

The VMMO consumer audit found one direct use of the removed public alias in
`src/shared/libraries/character/rig/types/components/rigComponent.luau`:
`RigRecognizeConfig = Anatomy.RecognizeConfig<RigSocket, RigTag>`.
When updating VMMO's Anatomy dependency pin, change its right-hand side to
`Anatomy.RecognizeOptions<RigSocket, RigTag>`. The game-owned alias can be renamed with
its consumers in the separately scoped CharacterRig convention migration.
VMMO's pin and source are untouched in this package checkpoint.

## Verification

- Guarded full package analyzer (`src` and `dev`, pinned Luau-LSP 1.70.1, solver V2):
  zero diagnostics before editing and zero diagnostics after cleanup. All touched source/dev
  Luau files are clean in the final run.
- The initial read-only change rejected the existing contract test's direct dictionary write
  with `Property bad of table '{ read [string]: true }' is read-only`, proving static enforcement.
  That runtime-negative test now deliberately asserts a writable view to continue checking the
  independent runtime freeze. The identity/frozen-table assertion remains unchanged.
- `pwsh -NoProfile -File scripts/verify/run.ps1 -Check all`: passes formatting, Selene
  (0 errors, 0 warnings, 0 parse errors), analyzer, maintained Lune contract tests including
  20 mount/subscription lifecycle cycles, package and dev Rojo builds, and VitePress docs.
- Generated Rojo sourcemap inspected: no duplicate sibling names. Every source Luau file
  has `--!optimize 2`.
- Automatic approval review rejected deletion of obsolete port directories with "blocked by
  policy". The empty local directories remain at `types/ports/anatomySource` and
  `types/ports/managers/anatomyHost` beneath `src/anatomy`, including their shared children.
  Earlier blocked cleanup of legacy empty SocketWatcher directories was not retried.
- No Studio run was performed; this type/layout cleanup does not establish a new engine-behavior proof.

Package review and the subsequent VMMO pin/consumer update remain pending. The earlier merged
integration stays accepted; this follow-up is tracked as in progress.
