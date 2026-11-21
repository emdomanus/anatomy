# Public contracts

`src/shared.luau` is the entry. It hands out three modules and six types, and no type takes a type
parameter.

```luau
Anatomy.anatomyTemplate.new(elements, socketAttribute, tagsAttribute): AnatomyTemplate
Anatomy.anatomyInstance.new(anatomyTemplate): AnatomyInstance
Anatomy.anatomyHost.new(): AnatomyHostOwned

Anatomy.AnatomyElement, Anatomy.AnatomySource, Anatomy.AnatomyTemplate,
Anatomy.AnatomyInstance, Anatomy.AnatomyHost, Anatomy.AnatomyHostOwned
```

## AnatomyElement

```luau
export type AnatomyElement = {
	read authoredAttributes: { read [string]: unknown },
}
```

The one shape Anatomy declares and the asset's owner supplies. An element table is an array of
these, `elements[elementIndex]`. A table whose records have more fields passes as it is.

## AnatomyTemplate

`anatomyTemplate.new(elements, socketAttribute, tagsAttribute)` reads each element's
`authoredAttributes` once, in element-index order, and returns frozen data.

- An element whose `socketAttribute` attribute is set is a socket named by that string. A name may
  appear once per table.
- An element whose `tagsAttribute` attribute is set is a tagged element. The string is a list of
  tags separated by `;`. An entry is trimmed of surrounding spaces and an empty entry is skipped.
- A socket name and a tag are each one or more segments of letters, digits and `_` joined by `.`.
- An element is found under every prefix of each of its tags: `weapon.blade.main` is found under
  `weapon`, `weapon.blade` and `weapon.blade.main`. A prefix is whole segments.
- It raises, naming the element index, for an attribute that is not a string, a name that is not of
  that form, and a socket name a lower element index already carries.

```luau
export type AnatomyTemplate = {
	read socketNames: { read [number]: string },                 -- in element-index order
	read socketElementIndexByName: { read [string]: number },
	read taggedPrefixes: { read [number]: string },              -- each prefix once
	read taggedElementIndexesByPrefix: { read [string]: { read [number]: number } },   -- ascending
}
```

The template has no method. `anatomyInstance.new` reads the four tables, and a consumer may read
them too, for example to check each socket's element when it loads the asset.

## AnatomySource

What a host composes. An `AnatomyInstance` and an `AnatomyHost` both implement it.

```luau
export type AnatomySource = {
	read socketNames: { read [number]: string },
	read taggedPrefixes: { read [number]: string },
	read getSocket: (self: AnatomySource, socketName: string) -> (number?, AnatomySource?),
	read getTopTagged: (self: AnatomySource, prefix: string) -> (number?, AnatomySource?),
	read getTagged: (
		self: AnatomySource,
		prefix: string,
		intoElementIndexes: { number },
		intoAnatomyInstances: { AnatomySource }
	) -> (),
	read onAnySocketChanged: (self: AnatomySource, callback: (socketName: string) -> ()) -> () -> (),
	read onAnyTopTaggedChanged: (self: AnatomySource, callback: (prefix: string) -> ()) -> () -> (),
	read containsSource: (self: AnatomySource, anatomySource: AnatomySource) -> boolean,
}
```

- `getSocket` and `getTopTagged` return an element index and the instance that supplies it, or
  `nil, nil`. The instance is always one `anatomyInstance.new` built, never a host.
- An instance's top element under a prefix is its last one in element-index order.
- `getTagged` appends an element index to `intoElementIndexes` and its instance, at the same
  position, to `intoAnatomyInstances`: lowest precedence first, each instance's elements in
  element-index order. The last pair is what `getTopTagged` returns. It does not empty the arrays.
- `socketNames` and `taggedPrefixes` list what the source can supply; every other name gives nil.
  An instance lists exactly what its template has. A host lists every name a source of it has
  supplied since it was built, so a listed name can currently have no supplier.
- `onAnySocketChanged` and `onAnyTopTaggedChanged` are how a host hears a host pushed into it. An
  instance never changes: it keeps nothing and returns a function that does nothing.
- `containsSource` is true for the source itself and for every source reachable from it through
  pushed sources.

## AnatomyInstance

```luau
export type AnatomyInstance = AnatomySource
```

`anatomyInstance.new(anatomyTemplate)` returns one frozen table that refers to the template's four
tables and takes nothing about the clone. Two instances of one template answer every query with the
same element indexes and differ only in being two tables. It has no setter and no teardown.

## AnatomyHost and AnatomyHostOwned

`anatomyHost.new()` returns `AnatomyHostOwned`. The owner hands a consumer the same object as
`AnatomyHost`.

```luau
export type AnatomyHost = AnatomySource & {
	read onSocketChanged: (self, socketName: string, callback, initially: boolean?) -> () -> (),
	read onTopTaggedChanged: (self, prefix: string, callback, initially: boolean?) -> () -> (),
	read onSocketAmongOthersChanged: (
		self, socketName: string, excluded: AnatomySource, callback, initially: boolean?
	) -> () -> (),
}
-- callback: (elementIndex: number?, anatomyInstance: AnatomySource?) -> ()

export type AnatomyHostOwned = AnatomyHost & {
	read push: (self, anatomySource: AnatomySource, priority: number) -> (),
	read remove: (self, anatomySource: AnatomySource) -> (),
	read setPriority: (self, anatomySource: AnatomySource, priority: number) -> (),
	read deconstruct: (self) -> (),
}
```

**Precedence.** A higher priority is above a lower one. Among equal priorities the later `push` is
above, and `setPriority` counts as a push for this. A host pushed into a host is one source there:
its own winner competes at the priority the parent gave it.

**The owner's methods.**

- `push` raises, before anything changes, when the source is already pushed to this host, or when
  `anatomySource:containsSource(self)` is true: the source is this host or contains it.
- `remove` does nothing when the source is not pushed to this host.
- `setPriority` raises when the source is not pushed to this host. An unchanged priority does
  nothing.
- `deconstruct` removes every source, tells every subscriber and every host this one is pushed to
  nil once per name, then drops every subscriber. Afterwards the queries return nil and append
  nothing, `push` and the subscriptions raise, and a release obtained earlier still works. A
  deconstructed host that is still pushed in another host answers nil there until that host removes
  it.

**The subscriptions.**

- Each calls `callback` with the getter's two results each time they differ from what the host last
  reported for that name. With `initially`, the callback is added and then called once with the
  current results before the call returns. Each returns the function that unsubscribes.
- `onSocketAmongOthersChanged` reports the socket as the highest-precedence source of this host
  other than `excluded` supplies it. `excluded` is compared with the sources pushed directly to this
  host; a source that is not pushed to it excludes nothing, and that is not an error. There is no
  getter beside it: `initially` gives the current result.
- One function subscribed twice is two entries, each removed by its own release. A release called
  twice does nothing the second time. A subscriber released during a report, before its turn, is not
  called; one added during a report waits for the next.

**A callback that changes the composition** may do so. Its `push`, `remove` or `setPriority` runs to
its end, reports included, inside the callback. Every subscriber's last call carries the current
results; a subscriber may be called twice with the same ones.

**A callback that raises** makes the `push`, `remove` or `setPriority` raise with it. Every query on
the host is already correct. The names the operation had not yet reported are reported at the next
operation or nested report that involves them. For the name being reported when it raised, the
subscribers after the raising one are called when that name's winner next changes.
