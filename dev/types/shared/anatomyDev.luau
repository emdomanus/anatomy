--!strict
--!optimize 2

local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)

export type DevModelKind = "rig" | "weapon"
export type TestDefinition = {
	name: string,
	run: () -> (),
}
export type DemoState = {
	reactiveMountDisconnect: (() -> ())?,
	weaponWatcher: Anatomy.SocketWatcher<string>?,
	rigWatcher: Anatomy.SocketWatcher<string>?,
	host: Anatomy.AnatomyHost<string, string>?,
	reactiveMount: Anatomy.SocketMount?,
	directMount: Anatomy.SocketMount?,
	rigInstances: { Anatomy.AnatomyInstance<string, string> },
	weaponInstances: { Anatomy.AnatomyInstance<string, string> },
	activeRigIndex: number,
	activeWeaponIndex: number,
	mountedRigIndex: number?,
	mountedWeaponIndex: number?,
}

return {}
