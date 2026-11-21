# Changelog

## 0.3.0

The package was rewritten (VMMO-92). Every 0.2 name is removed with no alias, and the unreleased
direct-subscription work (`bindToSocket`, `bindTopTaggedChanged`) is removed with the rest; it
remains in the repository's history.

### Changed

- The pesde target is `luau`. The package names no engine type and calls no engine API: it reads no
  model, holds no engine object and builds no constraint. Its entry is `src/shared.luau` and its one
  dependency is `emdomanus/luau_utils`; the `guard` dependency is gone.
- A socket and a tagged element are each an element index with the instance that supplied it.
  `getSocket` and `getTopTagged` return `(elementIndex, anatomyInstance)` or `nil, nil`, and
  `getTagged(prefix, intoElementIndexes, intoAnatomyInstances)` appends pairs to two arrays the
  caller owns. The consumer turns a pair into an engine object through whatever owns the asset.
- `anatomyTemplate.new(elements, socketAttribute, tagsAttribute)` reads an element table,
  `elements[elementIndex].authoredAttributes`, and returns frozen data with four readable tables.
  The tag delimiters `;` and `.` are fixed. The package checks each socket name and tag itself:
  segments of letters, digits and `_` joined by `.`.
- `anatomyInstance.new(anatomyTemplate)` builds an instance: one frozen table per clone that holds
  nothing about the clone and has no teardown.
- `anatomyHost.new()` takes nothing and returns `AnatomyHostOwned`; a consumer holds the same object
  as `AnatomyHost`, which cannot `push`, `remove`, `setPriority` or `deconstruct`.
- `AnatomySource` is the capability a host pushes, implemented by the instance and the host, so a
  host is still pushed into a host. A cycle is refused at `push` through `containsSource`.
- Subscriptions are `onSocketChanged`, `onTopTaggedChanged` and `onSocketAmongOthersChanged`, each
  `(name, ..., callback, initially?)` returning the function that unsubscribes. They are held in
  `luau_utils`' `callbackList`: one function subscribed twice is two entries, in the order added.
- `setPriority` puts the source above the others at its new priority, as a push does.
- `push` takes its priority as a required argument, `remove` returns nothing, and `push`,
  `remove` and `setPriority` of an instance allocate nothing.
- The package follows workflowCompass with the `luau` preset. The suites are
  `tests/src/**/*.spec.luau`, run in Lune by `scripts/verify/tests.ps1`.

### Removed

- `template:instantiate`, `template:wrap`, `AnatomyPath`, instance ownership of a root,
  `instance:deconstruct`, `setParent`, `getRoot`, `getTemplate`, `getSource`.
- `SocketMount`, `socketMount.new`, `host:mount` and every mount method. A consumer builds its own
  constraint and follows a socket with `onSocketChanged` or `onSocketAmongOthersChanged`.
- `AnatomySocket`, `AnatomyTaggedElement`, `getTags`, `hasTag`, `getLeafUnder`.
- `RecognizeOptions`, `socketNameGuard`, `tagGuard`, `NameGuard`, `InstancePolicy`, `category`,
  `metadata`, and the `<SocketT, TagT>` type parameters.
- `bindSocketChanged`, `bindTaggedAdded`, `bindTaggedRemoved`, `host:clear`.
- The dev place, `dev.project.json`, `default.project.json` and the Rojo pin.

### Fixed

- Subscribing one function twice made one entry: the first release removed both, and the order of
  calls was undefined.

## 0.2.0

- Removed the surface API and surface descriptors.
- Removed the part API and part descriptors; use hierarchical tags for named or
  semantic element lookup.
- Removed template/instance role metadata; hosts, layers, sockets, and tags carry
  runtime semantics now.
- Added hierarchical tags with `tagsAttribute`, `tagDelimiter`,
  `tagPathDelimiter`, and `tagGuard`.
- Added `TagDescriptor`, `AnatomyTaggedElement`, `template:getTagDescriptors()`,
  `instance:getByTag(prefix)`, `host:getByTag(prefix, query?)`, and
  `host:bindByTag(prefix, onAdded, onRemoved, runInitially?)`.
- Renamed public generics from `<TSocketName, TSurfaceName>` to
  `<SocketT, TagT>`.
- Kept mounts, socket bindings, and endpoints socket-only.

## 0.1.2

- Initial public socket, part, surface, host, and mount APIs.
