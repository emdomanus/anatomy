# Changelog

## Unreleased

- Replace SocketWatcher with direct `bindToSocket` subscriptions and shared per-name callback buckets.
- Add allocation-free single-result `getTopTagged` and lazy `bindTopTaggedChanged` observation.
- Order host tagged queries by source priority, registration order and source-local element order;
  deduplicate shared leaves at their highest-precedence occurrence and propagate nested priority changes.
- Publish host membership removal during teardown before disposing its explicit mounts.

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
