--!strict
--!optimize 2

-- The owner releases these subscriptions before destroying its explicit mount.
local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)
type SocketMount = Anatomy.SocketMount
type AnatomySource<S, T> = Anatomy.AnatomySource<S, T>

local function bindMountSockets<S, T>(
	mount: SocketMount,
	source: AnatomySource<S, T>,
	fromName: S,
	toName: S
): () -> ()
	local function update(): ()
		local from = source:getSocket(fromName)
		local to = source:getSocket(toName)
		mount:setAttachments(
			if from then from:getAttachment() else nil,
			if to then to:getAttachment() else nil
		)
	end
	local disconnectFrom = source:bindToSocket(fromName, update)
	local disconnectTo = source:bindToSocket(toName, function()
		update()
	end)
	update()
	return function()
		disconnectFrom()
		disconnectTo()
	end
end
return bindMountSockets
