--!strict
--!optimize 2

export type CallbackSet<Args...> = { [(Args...) -> ()]: true }
return {}
