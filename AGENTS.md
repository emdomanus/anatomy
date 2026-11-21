# Anatomy repository guide

Anatomy follows workflowCompass: `compass.json` extends the `luau` preset, and the compass skills
apply.

## Repository map

- `src/` is the package. It names no engine type and calls no engine API, so every module in it is
  shared: it runs under Lune and in Roblox alike, and no module sits in a `shared`, `server` or
  `client` folder. Its one entry is `src/shared.luau`, the `lib` `pesde.toml` names.
- `tests/` mirrors the repository: `tests/src/...` tests the package through its entry, and
  `tests/scripts/...` the scripts.
- `scripts/verify/tests.ps1` runs every `*.spec.luau` in Lune and every `*.tests.ps1` in PowerShell.
- `docs/` holds the package documentation; start with `docs/index.md`. `docs/todo/` holds the open
  task records.
- Generated local state: `luau_packages/`, `node_modules/`, `.verification/`.

## Checks

Tools resolve from `~/.rokit/bin`, as `rokit.toml` pins them. Once per checkout, from PowerShell:

```powershell
rokit install
pesde install --locked
```

Then:

```powershell
compass checks run -ProjectRoot . -Kind code
compass checks run -ProjectRoot . -Kind docs
```

The `docs` check needs `npm ci` first.
