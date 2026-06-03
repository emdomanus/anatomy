--!strict
--!optimize 2
--!native

export type CallbackSet = { [any]: true }

local CallbackSet = {}

function CallbackSet.new(): CallbackSet
	return {}
end

function CallbackSet.bind(callbacks: CallbackSet, callback: any): () -> ()
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

function CallbackSet.fire(callbacks: CallbackSet, ...: any): ()
	for callback in callbacks do
		callback(...)
	end
end

return CallbackSet
