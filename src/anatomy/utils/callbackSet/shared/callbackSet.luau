--!strict
--!optimize 2

local CallbackSetTypes =
	require(script.Parent.Parent.Parent.Parent.types.def.callbackSet.shared.callbackSet)

type CallbackSet<Args...> = CallbackSetTypes.CallbackSet<Args...>
local function bind<Args...>(callbacks: CallbackSet<Args...>, callback: (Args...) -> ()): () -> ()
	local connected = true
	callbacks[callback] = true
	return function()
		if not connected then
			return
		end
		connected = false
		callbacks[callback] = nil
	end
end
local function fire<Args...>(callbacks: CallbackSet<Args...>, ...: Args...): ()
	for callback in callbacks do
		callback(...)
	end
end
return { bind = bind, fire = fire }
