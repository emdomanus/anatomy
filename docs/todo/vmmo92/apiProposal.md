# Anatomy API proposal (VMMO-92)

Written 2026-11-21 against Anatomy `706600c` and VoxelMMO `main` at `cbbc2e50`, and amended twice the
same day with the user's reviews. The user accepted this API on 2026-11-21 with four answers, which
section 7 records, and stage 2 built it; the page is updated to what was built. VoxelMMO paths below
are relative to the VoxelMMO repository; line numbers are from that commit.

What the two amendments changed:

- Composition is general: a host is pushed into a host, through one capability, `AnatomySource`,
  that the instance and the host both implement.
- Anatomy reads no model, holds no Instance, returns none and makes no engine call. A template is
  built from an element table. A socket and a tagged element are both an element index with the
  instance that supplied it.
- `mount` is not in the package. The host keeps the one thing a mount needed: the winner of a socket
  among the sources other than one given source, with a report when it changes.
- The package has no Roblox type left, so its pesde target is plain Luau (section 6).

Sections: 0 findings checked, 1 the model and the public types, 2 the new rig's calls, 3 the old call
sites that read differently, 4 cost of each call, 5 Foundry, 6 the pesde target, 7 the answers.

## 0. Findings checked

Every finding in the brief holds, with these corrections and additions.

**What VoxelMMO calls.**

- `bindTopTaggedChanged`: `CharacterRig.bindTopTaggedChanged`
  (`src/shared/libraries/character/rig/managers/characterRig/shared/characterRig/init.luau` L360)
  calls `self._host:bindTopTaggedChanged`, but nothing in `src` calls
  `CharacterRig.bindTopTaggedChanged`. Its one caller is `tests/lune/anatomyIntegration.spec.luau`.
- `getTagged` on a host: `CharacterRig.getTagged` (L356) calls `self._host:getTagged`, and nothing in
  `src` calls `CharacterRig.getTagged`. Every real caller of `getTagged` asks one instance:
  `rigComponent/init.luau` L96 and L100, `characterHurtboxManager.luau` L81,
  `weaponPartRender/init.luau` L230.
- Called and not in the brief's list: `anatomyHost.new` (`characterRig/init.luau` L160),
  `host:remove` (L254), `host:deconstruct` (L384), `anatomyInstance:deconstruct`
  (`rigComponent/init.luau` L118), `socket:getAttachment`, `element:getInstance`, and on a mount
  `deconstruct`, `isConnected` and `setAttachments`.
- Never called in `src`, beyond the brief's list: `host:clear`, `instance:getRoot`,
  `instance:getTemplate`, `instance:setParent`, `template:getSource`, and on a mount `getConstraint`,
  `setEnabled`, `setParent`, `getName`, `getFromAttachment`, `getToAttachment`.
  `tests/lune/anatomyIntegration.spec.luau` calls `getConstraint`, `getFromAttachment` and
  `getToAttachment`.
- Five files call Anatomy's objects without requiring the package, so they are callers too:
  `characterHurtboxManager.luau` (an instance's `getSocket` and `getTagged`),
  `aCarryTransformRelationship.luau`, `presentationVisualRegistry/init.luau`,
  `characterPresentationHost/init.luau` and `characterVisualizer/init.luau`.

**Where the API breaks compass.** All seven hold. Two more:

- `AnatomyInstance<TemplateT, SocketT, TagT>` takes `TemplateT` only so that the instance's type
  file does not require the template's. compass: a cycle between type contracts is never broken with
  a generic parameter standing in for the real type.
- `types/def/anatomy/shared/anatomy.luau`, a type file, requires the `guard` package by `script`
  path into `roblox_packages`.

**The defect.** Confirmed in `utils/callbackSet/shared/callbackSet.luau`: `callbacks[callback] = true`.
Two more consequences of the same set:

- In `AnatomyHost.bindToSocket` and `bindTopTaggedChanged`, the release of the first subscription
  finds the set empty and deletes the per-name entry (`self._socketCallbacksByName[name] = nil`),
  while the second subscription of the same function still holds a release it believes is live.
- A callback that subscribes another function during a report assigns a new key to the table
  `for callback in callbacks` is traversing. Luau does not define whether that traversal then visits
  each callback once.

**Cost.** Confirmed. More of the same kind:

- Each tagged element is also a wrapper object (`AnatomyTaggedElement.new`), one per element per
  instance.
- `AnatomyInstance.getTagged` returns a new `{}` when nothing matches, so a host's `getTagged`
  allocates 2 tables plus 1 per pushed instance whatever it finds.
- `AnatomyHost.push` allocates a registration record, 2 maps, 3 subscription closures, the `pcall`
  closure, the `addedTaggedElements` array and the `table.sort` comparator, and adds one entry per
  tagged element to `_taggedElementCounts`.
- `push` calls `socketNameGuard` on every socket name and `tagGuard` on every tag of the instance.
  VoxelMMO's two guards call `string.split` (`isDottedKey` in
  `src/shared/domain/definitions/character/rig/socket/init.luau` L132), so every `push` allocates one
  table per socket name and one per tag.

## 1. The model and the public types

### The model

```luau
-- The one shape Anatomy declares and somebody else supplies.
AnatomyElement = { authoredAttributes: { [string]: unknown } }

AnatomyTemplate = {                                -- one per element table; frozen data, all four public
	socketNames: { string },                       -- in element-index order
	socketElementIndexByName: { [string]: number },
	taggedPrefixes: { string },                    -- "weapon", "weapon.blade", "weapon.blade.main"
	taggedElementIndexesByPrefix: { [string]: { number } },   -- each array in ascending element index
}
AnatomyInstance = {                                -- one per clone; frozen; nothing about the clone
	-- references to its template's four tables, and nothing else
}
AnatomyHost = {                                    -- one per entity, or one pushed into another host
	anatomySources: { AnatomySource },             -- lowest precedence first: by priority, then by push order
	priorities: { number },                        -- priorities[i] belongs to anatomySources[i]
	releaseAnySocketChanged: { () -> () },         -- [i]: this host's subscription on anatomySources[i]
	releaseAnyTopTaggedChanged: { () -> () },

	socketNames: { string },                       -- every name a source has supplied since `new`; only grows
	taggedPrefixes: { string },
	knownSocketNames: { [string]: true },          -- the same names as a set, so each is listed once
	knownTaggedPrefixes: { [string]: true },
	winnerElementIndexes: { [string]: number },    -- socket name -> getSocket's first result
	winnerInstances: { [string]: AnatomySource },  -- socket name -> getSocket's second result
	topTaggedElementIndexes: { [string]: number }, -- prefix -> getTopTagged's first result
	topTaggedInstances: { [string]: AnatomySource },
	reportedWinnerInstances: { [string]: AnatomySource },      -- what subscribers and parents were last told
	reportedTopTaggedInstances: { [string]: AnatomySource },

	anySocketChangedList: CallbackList<string>,    -- its parents; created when first pushed into a host
	anyTopTaggedChangedList: CallbackList<string>,
	socketChangedLists: { [string]: CallbackList<number?, AnatomySource?> },   -- per subscribed name
	topTaggedChangedLists: { [string]: CallbackList<number?, AnatomySource?> },
	socketAmongOthersLists: { [string]: CallbackList<> },      -- per name with an "among others" subscriber
}
```

**What an instance is.** `anatomyInstance.new(anatomyTemplate)` takes nothing about the clone and
returns one frozen table that refers to the template's four tables. Two instances of one template answer every query with the same element
indexes. They differ only in being two tables: an instance is the identity of one clone inside
Anatomy. The rig creates one per clone and keeps its own map from the instance to the clone's lease.
Every query result is `(elementIndex, anatomyInstance)`, and the rig turns that pair into an
Attachment, an Instance or an element handle through the lease. Anatomy never sees the lease.

One example through it. An entity's host `entityHost` holds a body instance at priority 0 and a helm
instance at 10. In the body's element table `body.head` is element 14; in the helm's it is element 3.
`entityHost:getSocket("body.head")` returns `3, helm`. `entityHost:remove(helm)` sets
`winnerElementIndexes["body.head"] = 14` and `winnerInstances["body.head"] = body`, and calls
`socketChangedLists["body.head"]:fire(14, body)`. The rig's subscriber looks up the body's lease and
asks it for the Instance at element 14.

A host keeps everything about a push in its own arrays. A source holds nothing about the hosts it is
in, except that a host keeps the list of functions its parents subscribed.

### Entry

```luau
local Anatomy = require(...)             -- src/shared.luau, typed and frozen
Anatomy.anatomyTemplate.new
Anatomy.anatomyInstance.new
Anatomy.anatomyHost.new
```

It depends on `luauUtils` only. No file under `src` names `Instance`, `Attachment` or any other
Roblox type, and none calls the engine.

### The declared shape

```luau
-- types/def/anatomy/anatomyElement/public.luau
-- One element of an asset, as its owner indexes it. An element table is an array of these:
-- elements[elementIndex]. Anatomy reads this one field.
export type AnatomyElement = {
	read authoredAttributes: { read [string]: unknown },
}
```

Foundry's `AssetTemplateData.elements` is an array of records that have `authoredAttributes`, and it
passes as `{ read [number]: AnatomyElement }` as it is. The package's
`tests/src/components/anatomyTemplate/anatomyTemplate.typecheck.luau` checks that on Foundry's
`AssetTemplateElement` record, copied with all seven fields. `AnatomyElementInstances` is gone.

### The capability

```luau
-- types/def/anatomy/anatomySource/public.luau
-- What a host composes. Two objects implement it: the AnatomyInstance and the AnatomyHost. It is a
-- def leaf because no single object implements it.
-- Where a result is "the instance", it is the AnatomySource `anatomyInstance.new` built and whose template
-- holds the element index: never a host. A def leaf cannot name AnatomyInstance, so the type says
-- AnatomySource.
export type AnatomySource = {
	-- getSocket returns nil for every name not listed, and getTopTagged for every prefix not
	-- listed. An instance lists exactly what it has. A host lists every name a source of it has
	-- supplied since it was built, so a listed name can currently have no supplier.
	read socketNames: { read [number]: string },
	read taggedPrefixes: { read [number]: string },

	-- The element index of the socket and the instance that supplies it, or nil, nil.
	read getSocket: (self: AnatomySource, socketName: string) -> (number?, AnatomySource?),
	-- The element index of the top element under `prefix` and the instance it belongs to, or nil, nil.
	-- An instance's top element is its last one under the prefix in element-index order.
	read getTopTagged: (self: AnatomySource, prefix: string) -> (number?, AnatomySource?),
	-- Appends every element under `prefix`: its element index to `intoElementIndexes` and its
	-- instance, at the same position, to `intoAnatomyInstances`. Lowest precedence first, each
	-- instance's elements in element-index order; the last pair is what getTopTagged returns.
	read getTagged: (
		self: AnatomySource,
		prefix: string,
		intoElementIndexes: { number },
		intoAnatomyInstances: { AnatomySource }
	) -> (),

	-- Calls `callback(socketName)` each time getSocket(socketName) starts returning something else;
	-- `callback(prefix)` likewise for getTopTagged. Returns the function that unsubscribes.
	-- An instance never changes: it keeps nothing and returns a function that does nothing.
	read onAnySocketChanged: (self: AnatomySource, callback: (socketName: string) -> ()) -> () -> (),
	read onAnyTopTaggedChanged: (self: AnatomySource, callback: (prefix: string) -> ()) -> () -> (),

	-- True when `anatomySource` is this source, or is reachable from it through pushed sources.
	-- An instance has no sources, so it answers `anatomySource == self`.
	read containsSource: (self: AnatomySource, anatomySource: AnatomySource) -> boolean,
}
```

### The objects

```luau
-- Reads the element table once, in index order.
-- An element whose `socketAttribute` attribute is set is a socket named by that string. A name may
-- appear once per table.
-- An element whose `tagsAttribute` attribute is set is a tagged element. The string is a list of
-- tags separated by ";", each trimmed of surrounding spaces, an empty entry skipped. A tag is a
-- dotted name, and the element is found under every prefix of it: "weapon.blade.main" is found
-- under "weapon", "weapon.blade" and "weapon.blade.main".
-- A socket name and a tag are each one or more segments of letters, digits and "_" joined by ".".
-- It raises, naming the element index, for an attribute that is not a string, a name not of that
-- form, and a socket name a lower element index already carries.
anatomyTemplate.new(
	elements: { read [number]: AnatomyElement },
	socketAttribute: string,
	tagsAttribute: string
): AnatomyTemplate

-- Frozen data with no method. `anatomyInstance.new` reads the four tables through this public type,
-- and a consumer may read them too, for example to check each socket's element at load.
export type AnatomyTemplate = {
	read socketNames: { read [number]: string },
	read socketElementIndexByName: { read [string]: number },
	read taggedPrefixes: { read [number]: string },
	read taggedElementIndexesByPrefix: { read [string]: { read [number]: number } },
}

-- A new instance of the template. It takes nothing about the clone: see "What an instance is".
anatomyInstance.new(anatomyTemplate: AnatomyTemplate): AnatomyInstance

-- It is the capability and nothing more: no setter and no teardown.
export type AnatomyInstance = AnatomySource

-- What a consumer of one composed anatomy holds.
export type AnatomyHost = AnatomySource & {
	-- Calls `callback` with getSocket(socketName)'s two results each time they differ from what
	-- this host last reported for that name. With `initially`, also calls it once with the current
	-- results before returning. Returns the function that unsubscribes.
	read onSocketChanged: (
		self: AnatomyHost,
		socketName: string,
		callback: (elementIndex: number?, anatomyInstance: AnatomySource?) -> (),
		initially: boolean?
	) -> () -> (),
	-- The same for getTopTagged(prefix).
	read onTopTaggedChanged: (
		self: AnatomyHost,
		prefix: string,
		callback: (elementIndex: number?, anatomyInstance: AnatomySource?) -> (),
		initially: boolean?
	) -> () -> (),
	-- The same as onSocketChanged, for the socket as the highest-precedence source of this host
	-- other than `excluded` supplies it. This is what a mount follows when the mounted component
	-- may supply the socket itself.
	read onSocketAmongOthersChanged: (
		self: AnatomyHost,
		socketName: string,
		excluded: AnatomySource,
		callback: (elementIndex: number?, anatomyInstance: AnatomySource?) -> (),
		initially: boolean?
	) -> () -> (),
}

-- What the owner of the host holds: `anatomyHost.new` returns it.
export type AnatomyHostOwned = AnatomyHost & {
	-- Adds the source above every pushed source of the same or a lower priority. Raises, before
	-- anything changes, when the source is already pushed to this host, or when
	-- `anatomySource:containsSource(self)` is true: the source is this host or contains it.
	read push: (self: AnatomyHostOwned, anatomySource: AnatomySource, priority: number) -> (),
	-- Does nothing when the source is not pushed to this host.
	read remove: (self: AnatomyHostOwned, anatomySource: AnatomySource) -> (),
	-- Moves the source as if removed and pushed at `priority`, in one step with one set of reports.
	-- Raises when the source is not pushed to this host. An unchanged priority does nothing.
	read setPriority: (self: AnatomyHostOwned, anatomySource: AnatomySource, priority: number) -> (),
	-- Removes every source, so every subscriber and parent is told nil, then drops every
	-- subscriber. Afterwards the queries return nil and append nothing, `push` and the
	-- subscriptions raise, and a release obtained earlier still works.
	read deconstruct: (self: AnatomyHostOwned) -> (),
}

anatomyHost.new(): AnatomyHostOwned
```

No type takes a type parameter.

### The smallest form of what a mount needed

One method, `onSocketAmongOthersChanged(socketName, excluded, callback, initially?)`. There is no
getter beside it: a mount needs the current winner once, when it is made, and `initially = true`
gives it in the same call. A mount that excludes nothing uses `onSocketChanged`.

- `excluded` is compared with the sources pushed directly to this host. A source that is not pushed
  to it excludes nothing, and that is not an error, so a component can subscribe before or after it
  is pushed.
- The winner among the others can change while the overall winner does not, so this cannot read
  `winnerInstances`. The subscription is one entry in `socketAmongOthersLists[socketName]`, which the
  host fires for every name a `push`, `remove`, `setPriority` or nested report visits, changed or
  not. The entry scans `anatomySources` from the top, skips the source equal to `excluded`, and calls
  `callback` when the instance it finds differs from the one it last reported.

### Behaviour

- **Precedence.** A higher priority is above a lower one. Among equal priorities the later `push`
  is above, and `setPriority` counts as a push for this. A host pushed into a host is one source
  there: its own winner competes at the priority the parent gave it.
- **A cycle is refused at `push`.** `push` calls `anatomySource:containsSource(self)` first and
  raises when it is true. `push` is the only call that adds a source, so no other call can make a
  cycle and none checks. The check walks the pushed source's own sources, and theirs: one call per
  source below it.
- **`push`, `remove` and `setPriority` work in two passes.** First, for each of the source's
  `socketNames` and `taggedPrefixes`, the host scans `anatomySources` from the top and writes
  `winnerElementIndexes`, `winnerInstances`, `topTaggedElementIndexes` and `topTaggedInstances`.
  Then, for each of those names again, it reports: when `winnerInstances[name]` differs from
  `reportedWinnerInstances[name]` it sets the latter, fires `anySocketChangedList` with the name, and
  fires `socketChangedLists[name]` with the two results. The same for prefixes. Every query is
  already correct on this host when the first callback runs.
- **How a nested host reports to its parent.** At `push`, a parent calls
  `anatomySource:onAnySocketChanged` and `onAnyTopTaggedChanged` with two functions it created once,
  in `new`, and keeps the two releases beside the source. An instance returns a function that does
  nothing. A host adds the function to its `anySocketChangedList`. When the child fires it with a
  name, the parent runs both passes for that one name: it scans its own sources, calling the child's
  `getSocket`, which already returns the child's new winner, and reports only if its own winner
  changed. That report goes to the parent's parents the same way. `remove` calls the two releases.
- **A parent changes one name at a time.** When one `push` into a child changes several names, the
  child is correct for all of them before it reports, but the parent learns them one by one. Inside
  a callback for the first name, the parent's `getSocket` for a later name of the same push still
  returns the old winner.
- **A callback that changes the composition.** The nested `push`, `remove` or `setPriority` runs to
  its end, reports included, inside the callback. For a name both calls report, the outer `fire`
  then still calls its remaining subscribers with the older results. So after `fire` returns the
  host compares `winnerInstances[name]` with the instance it fired, and fires again with the current
  results while they differ. Every subscriber's last call carries the current results; a subscriber
  may be called twice with the same ones. The host keeps no flag about a report in progress.
- **A callback that raises.** `push`, `remove` or `setPriority` raises with it. The first pass is
  complete, so every query on this host is correct. The names the second pass had not reached are
  reported at the next `push`, `remove`, `setPriority` or nested report that involves them, because
  `reportedWinnerInstances[name]` still holds what was last reported. The name being reported when
  the callback raised is already recorded as reported: the subscribers after the raising one in that
  fire are called when that name's winner next changes. `reportedWinnerInstances[name]` is written
  before the fire because, written after, an operation a subscriber ran inside its own call and that
  visits the same name would find it unreported and fire it to that subscriber again.
- **`initially`.** The callback is added first and then called once with the current results. If
  that call raises, the subscription stays; the caller has no release for it.
- **One function subscribed twice** is two entries, called twice, each removed by its own release.
  A release called twice does nothing the second time. A subscriber released during a report, before
  its turn, is not called. A subscriber added during a report waits for the next one. These are
  `callbackList`'s rules (`luauUtils`, `docs/callbackList.md`).
- **A subscriber list is kept until `deconstruct`.** The first subscriber of a socket name or prefix
  creates its `CallbackList`; the last one leaving does not remove it. `callbackList` has no count,
  and the names are a fixed vocabulary per game.
- **A source in two hosts at once** works, for an instance and for a host.

### What it removes

| Removed | Because |
| --- | --- |
| Every read of a model: `template:instantiate`, `template:wrap(root)`, `AnatomyPath`, `anatomyPath`, the `GetDescendants` scan, `GetAttribute` | The element table is the only input. |
| Every Instance the package held or returned: `ownsRoot`, `instance:deconstruct`, `instance:setParent`, `getRoot`, `getTemplate`, `getSource` | An instance holds nothing about a clone. |
| `SocketMount`, `SocketMountOptions`, `socketMount.new`, `host:mount`, `getConstraint` and the other eight mount methods | The rig library builds the constraint; the host gives it `onSocketAmongOthersChanged`. |
| `InstancePolicy`, `applyInstancePolicy`, `category`, `metadata`, `getCategory`, `getMetadata` | No caller. |
| `RecognizeOptions`, `tagDelimiter`, `tagPathDelimiter` | `new` is positional; the delimiters are the package's constants `;` and `.`. |
| `socketNameGuard`, `tagGuard`, `NameGuard`, the `guard` dependency, `<SocketT, TagT>` | The names are `string`; the package checks the dotted form itself. |
| `AnatomySocket` with `getAttachment`, `getName`, `getPath`, `getMetadata` | `getSocket` returns the element index and its instance. |
| `AnatomyTaggedElement` with `getInstance`, `getTags`, `hasTag`, `getLeafUnder` | A tagged query returns the element index and its instance. |
| `bindSocketChanged`, `bindTaggedAdded`, `bindTaggedRemoved` | A parent needs only the name that changed: `onAnySocketChanged`, `onAnyTopTaggedChanged`. |
| `bindToSocket`, `bindTopTaggedChanged`, `runInitially` | Renamed `onSocketChanged`, `onTopTaggedChanged`, `initially`. |
| The weak `hostSources` table | `containsSource` on the capability. |
| `anatomyHost.new`'s options, `host:clear`, `remove`'s boolean, `push`'s default priority | No caller reads or needs them. |
| `callbackSet`, both files | `luauUtils`' `callbackList`. |

Kept from the package as it is today: `AnatomySource`, now a `def/` leaf where it was under
`types/ports/`; a host inside a host; the refusal of a cycle.

## 2. The new rig's calls

From `docs/todo/entityRework/presentation.md` section 3. `assetLease` is Foundry's `AssetLease` with
the two methods of section 5. Everything that touches the engine below is the rig library's code.

```luau
-- Once per Foundry template, beside it. No model is read: the table is the template's own.
local anatomyTemplate = Anatomy.anatomyTemplate.new(
	assetTemplateData.elements,
	RigSocketAPI.definitions.attributeNames.socket,          -- "RigSocket"
	RigTagAPI.definitions.attributeNames.tags                -- "RigSurface"
)

-- Per clone: one frozen table. The rig keeps the pair, because only it knows which lease the
-- instance stands for.
local anatomyInstance = Anatomy.anatomyInstance.new(anatomyTemplate)
self._assetLeaseByAnatomyInstance[anatomyInstance] = assetLease

-- Once per entity, in CharacterRig.new().
local anatomyHost = Anatomy.anatomyHost.new()

-- registerComponent(component, priority), unregisterComponent, a priority change, teardown
anatomyHost:push(anatomyInstance, priority)
anatomyHost:remove(anatomyInstance)
anatomyHost:setPriority(anatomyInstance, priority)
anatomyHost:deconstruct()

-- A host in a host, when the rig wants a group that moves as one source
local weaponHost = Anatomy.anatomyHost.new()
weaponHost:push(swordAnatomyInstance, 0)
anatomyHost:push(weaponHost, -100)

-- The rig's one function from a result to an Attachment
local function toAttachment(self, elementIndex: number?, anatomyInstance): Attachment?
	if elementIndex == nil then
		return nil
	end
	return self._assetLeaseByAnatomyInstance[anatomyInstance]:getElementInstance(elementIndex) :: Attachment
end

-- getSocketAttachment(socketName)
return toAttachment(self, anatomyHost:getSocket(socketName))

-- The subscription that gives an Attachment
anatomyHost:onSocketChanged(socketName, function(elementIndex, anatomyInstance)
	callback(toAttachment(self, elementIndex, anatomyInstance))
end, initially)

-- The mount that follows a socket and returns a release: the rig builds the constraint.
-- `excluded` is the mounted component's own instance, so it never lands on its own socket.
local function mount(self, from: Attachment, socketName: string, excluded): () -> ()
	local constraint = Instance.new("RigidConstraint")
	constraint.Attachment0 = from
	constraint.Parent = from
	local unsubscribe = anatomyHost:onSocketAmongOthersChanged(socketName, excluded, function(elementIndex, anatomyInstance)
		constraint.Attachment1 = toAttachment(self, elementIndex, anatomyInstance)
	end, true)
	return function()
		unsubscribe()
		constraint:Destroy()
	end
end

-- The body form on the rig's own root: nothing to exclude, so onSocketChanged
anatomyHost:onSocketChanged("body.root", function(elementIndex, anatomyInstance)
	visualRootConstraint.Attachment1 = toAttachment(self, elementIndex, anatomyInstance)
end, true)

-- The top element under a tag, as a Foundry handle
local elementIndex, anatomyInstance = anatomyHost:getTopTagged("weapon.blade.main")
if elementIndex ~= nil then
	local assetLease = self._assetLeaseByAnatomyInstance[anatomyInstance]
	local bladeElement = assetLease:getElementAtIndex("BasePart", elementIndex)
end
anatomyHost:onTopTaggedChanged("weapon.blade.main", function(elementIndex, anatomyInstance) end, true)

-- A colour written to every tagged surface under "body", on the body, the ears and the tail.
-- The two arrays are the rule applier's own and are reused.
table.clear(elementIndexes)
table.clear(anatomyInstances)
anatomyHost:getTagged("body", elementIndexes, anatomyInstances)
for position, elementIndex in elementIndexes do
	local assetLease = self._assetLeaseByAnatomyInstance[anatomyInstances[position]]
	assetLease:getElementAtIndex("BasePart", elementIndex):setProperty("color", skinColor)
end
```

- The colour goes through Foundry's element handle, so Foundry records the write and restores the
  authored colour when the lease is released.
- A surface is not always a `BasePart`. The applier reads
  `assetLease.assetTemplateData.elements[elementIndex].className` and asks for that class.
- The rig's subscription closure and its constraint are the rig's costs now; section 4 lists only
  what Anatomy allocates.
- `AssetLease.getRootInstance`, which the plan adds in ER1.4a so that the old `wrap` has a root, is not
  needed for Anatomy.
- Two lines of the plan no longer hold: "a tagged element is the one Anatomy object still handed
  out", and that the rig's mount call "builds the `Anatomy.socketMount`". Below the rig a socket
  and a tagged element are each an element index with its instance, and the constraint is the rig's.

## 3. The old call sites that read differently

The old stack does not adopt this API: VoxelMMO pins the old revision as `anatomyLegacy` for these
files. This lists how each kind of site would read, where it differs from the first version of this
page. `anatomyHost.new()`, `push`, `remove`, `setPriority` and `deconstruct` read as they did there.

**`rig/utils/anatomyTemplateCache.luau` L47 to L61.** The old rig has no element table: it clones a
Model itself (`rigComponent/init.luau` L33). It cannot call `anatomyTemplate.new` without building a
table from the Model, which nothing in the package does any more. A port of the old rig would carry
its own crawl and its own array of Instances by element index; it is not planned.

**Every site that reads an Attachment from a socket**: `characterRig/init.luau` L266, L267, L278,
L322 and L334, `rigComponent/init.luau` L91, `characterHurtboxManager.luau` L78,
`weaponPartRender/init.luau` L74, `accessoryPartRender/init.luau` L54 and `swordOfJudgement.luau`
L397, L454 and L455. `getSocket` returns an element index, and the component that owns the clone
turns it into the Attachment:

```luau
-- rigComponent: the component holds its own Instances by element index
function RigComponent.getSocketAttachment(self, socket: RigSocket): Attachment?
	local elementIndex = self._anatomyInstance:getSocket(socket)
	return if elementIndex ~= nil then self._instancesByElementIndex[elementIndex] :: Attachment else nil
end

-- characterRig L334 getSocketAttachment
local elementIndex, anatomyInstance = self._host:getSocket(socket)
local component = if anatomyInstance ~= nil then self._componentByAnatomyInstance[anatomyInstance] else nil
return if component ~= nil then component:getElementInstance(elementIndex) :: Attachment else nil
```

**The socket subscribers**: `characterVisualizer/init.luau` L494,
`aCarryTransformRelationship.luau` L270 and L334, `characterNameplate/init.luau` L373,
`characterPresentationHost/init.luau` L86. They subscribe through `CharacterRig`, whose
`onSocketChanged` wraps the callback once and hands on the Attachment, so their own code reads as in
the first version: a callback that receives `Attachment?`.

**`characterRig/init.luau` L258 `connectSocketToComponent` and L272 `connectSocketToVisualRoot`,
and `swordOfJudgement.luau` L392 `createReplicaMount`.** `host:mount` and `socketMount.new` are
gone. The rig builds the RigidConstraint with the `mount` function of section 2 and returns its
release; `createReplicaMount` calls that function on the rig view.

**`characterRig/init.luau` L303 to L328 `getComponentForInstance`, `getComponentForTagged`,
`getComponentForSocket`, and `indexComponent` L108.** All go: every query returns the instance, and
the rig keeps one map from an instance to its component.

**The tagged queries**: `characterRig/init.luau` L352 and L356, `rigComponent/init.luau` L95 and
L99, `characterHurtboxManager.luau` L81, `weaponPartRender/init.luau` L230,
`characterPresentationHost/init.luau` L79, `presentationVisualRegistry/init.luau` L196 and
`swordOfJudgement.luau` L364. As in the second version of this page: they return element indexes
with instances, and a caller that needs the Instance asks the component that owns the clone.

**The type aliases.**

| Today | New |
| --- | --- |
| `Anatomy.AnatomyInstance<RigSocket, RigTag>` | `Anatomy.AnatomyInstance` |
| `Anatomy.AnatomyTemplate<RigSocket, RigTag>` | `Anatomy.AnatomyTemplate` |
| `Anatomy.AnatomyHost<RigSocket, RigTag>` | `Anatomy.AnatomyHostOwned` where it is constructed, `Anatomy.AnatomyHost` where it is only read |
| `Anatomy.AnatomySocket<RigSocket>`, `Anatomy.AnatomyTaggedElement<RigTag>` | `number`, the element index, with its `Anatomy.AnatomyInstance` |
| `Anatomy.SocketMount` | the rig's own `() -> ()` |
| `Anatomy.SocketChangedCallback<T>`, `Anatomy.TaggedChangedCallback<T>` | `(number?, Anatomy.AnatomySource?) -> ()` |
| `Anatomy.RecognizeOptions`, `Anatomy.SocketMountOptions` | gone |

## 4. Cost of each call

No call in the package calls the engine, so the table has no engine column.

Paths that can run every frame: `getSocket`, `getTopTagged` and `getTagged`, on a host or an
instance. None allocates. `push`, `remove`, `setPriority` and a report run when a loadout or form
changes; with instances they allocate nothing. `anatomyTemplate.new`, `anatomyInstance.new`, `anatomyHost.new` and
the subscriptions run at load or when a holder is constructed.

| Call | Luau allocation |
| --- | --- |
| `anatomyTemplate.new` | the template, 2 arrays, 2 maps, 1 array per prefix, the prefix strings, and `string.split`'s arrays while it reads tags |
| `anatomyInstance.new` | 1 table: the instance |
| `anatomyHost.new` | 18 tables, the host and its 17 fields that are tables, and the 2 functions it gives its sources; the two `any…` lists are not created here |
| `push`, `remove`, `setPriority` of an instance | none; the host's arrays grow when it holds more sources, or sees more names, than it ever has |
| `push` of a host | 2 closures, `callbackList`'s two releases; the pushed host's 2 `CallbackList`s (6 tables) the first time it is pushed anywhere |
| a report, a nested report | none |
| `getSocket`, `getTopTagged` on a host | none; 2 table reads |
| `getSocket` on an instance | none; 1 table read |
| `getTopTagged` on an instance | none; 2 table reads |
| `getTagged` | none beyond the growth of the two `into` arrays |
| `containsSource` | none; 1 call per source reachable below |
| `onSocketChanged`, `onTopTaggedChanged` | 1 closure, `callbackList`'s release (80 bytes); for the first subscriber of that name on that host, 1 `CallbackList` (3 tables), kept until `deconstruct` |
| `onSocketAmongOthersChanged` | 2 closures: the entry that scans and remembers what it last reported, and `callbackList`'s release; for the first such subscriber of that name on that host, 1 `CallbackList` (3 tables) |
| an "among others" entry when its name is visited | none; one scan of `anatomySources` |
| `onAnySocketChanged`, `onAnyTopTaggedChanged` on an instance | none |
| `deconstruct` | none |

The work in `push`, `remove` and `setPriority`: for each of the source's socket names and prefixes,
one scan of `anatomySources` from the top that stops at the first source supplying it, where each
step is one `getSocket` or `getTopTagged` call on a source. With `s` names and prefixes on the source
and `n` sources in the host, that is at most `s * n` calls. A nested report costs one such scan per
host above the change.

Compared with today: `anatomyInstance.new` makes no engine call and allocates 1 table, where `wrap` makes one
`GetChildren` per path step per socket and element and allocates 1 object for each; `push` of an
instance allocates nothing, where it allocates the list in section 0.

## 5. Foundry

**For Anatomy: nothing.** `AssetTemplateData.elements` is passed to `anatomyTemplate.new` as it is.
Anatomy relies on one thing Foundry already states: an element index numbers a template's elements
and a clone's Instances and handles alike (`assetTemplateData/public.luau` L4).

**For the rig, to use what Anatomy returns: two methods on the asset object.** They are between the
rig library and Foundry, both VoxelMMO's; proposed here, not built. Paths are under
`src/shared/libraries/foundry/`.

1. The element handle at an element index, on `Asset` in
   `types/components/asset/shared/asset/public.luau`, with the seven overloads `getElement` has:

   ```luau
   type GetAssetBasePartAtIndex = (self: Asset, className: "BasePart", elementIndex: number) -> AssetElement<BasePart>
   -- and the same for Model, Attachment, ParticleEmitter, Trail, Beam and Decal

   read getElementAtIndex: GetAssetModelAtIndex & GetAssetBasePartAtIndex & ...,
   ```

   It returns `self._handles[elementIndex]` after the class check `getElement` makes, and fails the
   same way for an index without a handle or of another class. It allocates nothing: every handle
   exists from `Asset.new`.

2. The Instance at an element index, on `Asset`, for the rig's constraint and for a caller that
   parents something under a tagged element:

   ```luau
   -- The same Instance for the same index for the clone's whole life. Fails for an index that
   -- holds none: out of range, or after deconstruct.
   read getElementInstance: (self: Asset, elementIndex: number) -> Instance,
   ```

   It returns `self._instances[elementIndex]`. The second version of this page needed its `self` to
   be a narrow type so the lease would pass as a shape Anatomy declared. That shape is gone, so
   `self: Asset` is enough.

## 6. The pesde target

**It is plain Luau.** No file under `src` uses a Roblox type or global, and the one dependency,
`luauUtils`, is itself a `luau` target. `pesde.toml` has:

```toml
[target]
environment = "luau"
lib = "src/shared.luau"
```

with no `build_files`, as `luauUtils` has it.

**What that changes for the package's checks and tests.**

- `compass.json` extends `luau`, as `luauUtils` does. Its `luauAnalyze` runs with no sourcemap and
  no Roblox definitions, so an `Instance` or `Attachment` written in `src` is a diagnostic. "No
  Roblox type in the package" becomes something a check decides.
- The roblox preset's parts go: the game mirror (the `game/` folder and the `.luaurc` alias that
  setup made in this checkout), `robloxLayout`, `robloxSource`, `robloxPackageRequires`, and the
  sourcemap. There is no availability split to state, because nothing is a Roblox module.
- `selene.toml` is `std = "luau"`. `rojo` leaves `rokit.toml`.
- The suites are `tests/src/**/*.spec.luau`, run in Lune by `scripts/verify/tests.ps1`, requiring
  the package by relative path (`require("../../src/shared")`), as `luauUtils`' do. They use no
  `@lune/roblox`. Today's `tests/lune/anatomy.spec.luau` goes whole: it builds a stand-in `script`
  tree, loads every module through it, and substitutes a fake `RigidConstraint`.
- A test's element table is a Luau literal, such as
  `{ { authoredAttributes = {} }, { authoredAttributes = { RigSocket = "body.head" } } }`, and its
  instances are `Anatomy.anatomyInstance.new(anatomyTemplate)`.

**What it changes for the dev place.** The dev place exists to show sockets resolving and a
constraint following them in Studio. The package now does neither with the engine: there is nothing
in it for Studio to show or to verify, and the behaviour that needs Studio, the constraint following
a socket, is the rig library's. Under the `luau` preset no check covers `dev/`, `dev.project.json` or
`default.project.json`, and under a `luau` target pesde writes no project file that keeps them out of
a consumer's game. All three are deleted, with the `.vscode` sourcemap settings. This replaces two
earlier lines: the brief's "the `dev` place still opens", and the accepted helper
`dev/utils/modelElements` (question 9 of the second version), which had no other user.

**What it changes for VoxelMMO.**

- The new revision installs under `luau_packages/`, where `luauUtils` is, and is required as
  `@game/ReplicatedStorage/luauPackages/anatomy`. `anatomyLegacy` stays under `roblox_packages/` at
  `@game/ReplicatedStorage/packages/anatomyLegacy`.
- A `luau` target has no `build_files`, so the installed copy has no generated
  `default.project.json`: Rojo syncs the package's whole folder, its `tests/` Luau files included,
  under `ReplicatedStorage.luauPackages`, as it does for `luauUtils` today. Nothing requires them.
- A `luau`-target package that requires its own `luau`-target dependency resolves from an installed
  copy in VoxelMMO's game tree. The user checked it on `jiwonz+luau_path`, which depends on
  `luau_disk`: its link `luau_path/luau_packages/luau_disk.luau` stays inside `luau_packages/.pesde`,
  and Rojo syncs the whole package folder. It was read from a sourcemap, not run in Studio. Anatomy's
  `src` requires `luauUtils` the same way (`"../../../luau_packages/luauUtils"`).

## 7. The answers

The four questions the third version of this page ended with, as the user answered them on
2026-11-21, and as built:

1. **The pesde target is plain Luau and the dev place is deleted**, as section 6 says.
2. **Anatomy does not read `className`.** `AnatomyElement` has `authoredAttributes` only, and a
   socket is whichever element carries the socket attribute. The rig library checks the class when
   it loads an asset.
3. **`wrap` is renamed.** An instance is created by `Anatomy.anatomyInstance.new(anatomyTemplate)`,
   and `AnatomyTemplate` has no method. `anatomyInstance.new` needs the template's four tables, so
   they are `read` fields of `AnatomyTemplate`'s public type. The rule: an object reads another
   object only through that object's public contract, and a private contract is its own
   implementation's alone. A public type without the fields would also accept any table as a
   template.
4. **`onSocketAmongOthersChanged` is built alone**, with no getter beside it.

Accepted earlier on 2026-11-21 and built as written:

- `getTagged`'s `into` is two parallel arrays, both required.
- The report callbacks receive the same two values the getters return.
- `excluded` is matched against the sources pushed directly to the host.
- A host's `socketNames` and `taggedPrefixes` only grow.
- A parent host changes one name at a time.
- A deconstructed host that is still pushed in a parent answers nil until the parent's owner removes
  it.
- Anatomy returns the index of any tagged element, whether or not Foundry has a handle for it.
- `AnatomyInstance` is an alias of `AnatomySource`.
- The objects are under `src/components/` and the entry is flat.
- Stage 2 deletes the five dated review pages from `docs/` and rewrites `ARCHITECTURE.md`,
  `types.md`, `index.md` and `README.md`.
- Version `0.3.0`; `luauUtils` pinned at `51f6051`; `private = true` in `pesde.toml`.

No longer apply: the mount's constraint and its parent, and a mount on a tagged element, because
`mount` left the package.
