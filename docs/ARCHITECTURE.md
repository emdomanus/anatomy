# Architecture

Anatomy owns two things: reading socket names and tags from an element table, and composing sources
by priority. It owns no asset, no clone and no engine object, and it is plain Luau.

## The records

```luau
AnatomyElement = { authoredAttributes: { [string]: unknown } }     -- declared here, supplied by the asset's owner

AnatomyTemplate = {                                -- one per element table; frozen
	socketNames: { string },
	socketElementIndexByName: { [string]: number },
	taggedPrefixes: { string },
	taggedElementIndexesByPrefix: { [string]: { number } },
}
AnatomyInstance = {                                -- one per clone; frozen
	socketNames, taggedPrefixes,                   -- its template's tables
	_socketElementIndexByName, _taggedElementIndexesByPrefix,
}
AnatomyHost = {
	_anatomySources: { AnatomySource },            -- lowest precedence first
	_priorities: { number },                       -- parallel to _anatomySources
	_releaseAnySocketChanged, _releaseAnyTopTaggedChanged,     -- parallel: this host's subscriptions on each source
	socketNames, taggedPrefixes,                   -- every name a source has supplied; only grow
	_winnerElementIndexes, _winnerInstances,       -- socket name -> getSocket's two results
	_topTaggedElementIndexes, _topTaggedInstances, -- prefix -> getTopTagged's two results
	_reportedWinnerInstances, _reportedTopTaggedInstances,     -- the instance last reported per name
	_anySocketChangedList, _anyTopTaggedChangedList,           -- the hosts this one is pushed to
	_socketChangedLists, _topTaggedChangedLists, _socketAmongOthersLists,   -- per name
}
```

`src/components/` holds the three modules and `src/types/components/` their contracts, and one
contract with no module: `anatomySource`, the capability the instance and the host both implement.
`AnatomyElement`, the shape a provider supplies, is in anatomyTemplate's contract, because
`anatomyTemplate.new` reads it.

## Why an instance holds nothing about its clone

An element index numbers the elements of an asset and the engine objects of each of its clones
alike, so `(elementIndex, anatomyInstance)` identifies one object of one clone. The asset's owner
already has the object at each index, and a consumer that writes a property should write it through
that owner so the write can be restored. So Anatomy returns the pair and the consumer resolves it.
An instance is then only the identity of a clone: one frozen table per clone, built without reading
anything.

The template's four tables are on its public type. `anatomyInstance.new` is another object and reads
only the template's public contract, and with the fields declared the type checker rejects a table
that is not a template.

## Composition

A host keeps everything about a push in its own arrays. A source holds nothing about the hosts it is
in, except that a host keeps the functions its parents subscribed.

`push`, `remove` and `setPriority` work in two passes over the socket names and prefixes of the
source they moved:

1. For each name, scan `_anatomySources` from the top and write the winner. After this pass every
   query on the host is correct.
2. For each name, when the winner differs from `_reportedWinnerInstances[name]`: record it, fire
   `_anySocketChangedList` with the name, and fire `_socketChangedLists[name]` with the two results.
   Then fire `_socketAmongOthersLists[name]`, changed or not.

A host pushed into a host is a source like an instance. At `push` the parent calls the source's
`onAnySocketChanged` and `onAnyTopTaggedChanged` with two functions it created once, in `new`. An
instance returns a function that does nothing; a host adds the function to its list. When the child
fires it with a name, the parent runs both passes for that one name, reading the child's `getSocket`,
and reports only if its own winner changed. So when one push into a child changes several names, the
parent learns them one at a time.

A cycle is refused at `push`, the only call that adds a source: `push` calls
`anatomySource:containsSource(self)` and raises when it is true.

`deconstruct` empties the source arrays first and then runs both passes over every name the host has
listed, so each name is reported as nil once, without the lower sources being reported on the way.

## Reports and reentrancy

Subscribers are held in `luauUtils`' `callbackList`, which calls them in the order they were added
and holds no state about a fire in progress. The host holds none either.

- A callback may change the composition. The nested operation reports the newer winner to every
  subscriber of the name; the outer fire then still calls its remaining subscribers with the older
  one. After a fire returns, the host compares the winner with the instance it fired and fires again
  while they differ.
- `_reportedWinnerInstances[name]` is written before the fire, not after. Written after, an
  operation a subscriber ran inside its own call, visiting the same name, would find the name
  unreported and fire it again to that subscriber.
- That choice sets what a raising callback leaves: the names the second pass had not reached still
  differ from what was reported, so the next operation that visits them reports them; the name being
  fired is already recorded, so its remaining subscribers are called when its winner next changes.

An `onSocketAmongOthersChanged` subscriber is one entry in `_socketAmongOthersLists[socketName]`. The
winner among the other sources can change while the overall winner does not, so the entry is called
for every name an operation visits; it scans the sources from the top, skips `excluded`, and calls
the subscriber when the instance differs from the one it last reported.

## Allocation

| Call | Allocates |
| --- | --- |
| `anatomyTemplate.new` | the template, 2 arrays, 2 maps, 1 array per prefix, the prefix strings, and `string.split`'s arrays while it reads |
| `anatomyInstance.new` | 1 table |
| `anatomyHost.new` | 18 tables and 2 functions; the two `any…` lists are created when the host is first pushed into a host |
| `getSocket`, `getTopTagged`, `getTagged`, `containsSource` | nothing; `getTagged` grows the arrays it is given |
| `push`, `remove`, `setPriority` of an instance, and every report | nothing; the host's arrays grow when it holds more sources, or sees more names, than it ever has |
| `push` of a host | 2 closures, `callbackList`'s releases |
| `onSocketChanged`, `onTopTaggedChanged` | 1 closure, `callbackList`'s release; the name's `CallbackList` (3 tables) for its first subscriber |
| `onSocketAmongOthersChanged` | 2 closures, the entry and its release; the name's `CallbackList` for its first such subscriber |

A subscriber list is kept until `deconstruct`: the last subscriber leaving does not remove it.
`tests/src/components/anatomyHost/anatomyHost.spec.luau` measures the queries and the changes of an
instance at 0 bytes.

## Verification

`compass checks run -ProjectRoot . -Kind code` runs the `luau` preset's checks and
`scripts/verify/tests.ps1`. The analysis loads no engine definitions, so an engine type or global
written in `src` is a diagnostic. The suites build element tables as Luau literals and run in Lune.
Nothing in the package needs Studio.
