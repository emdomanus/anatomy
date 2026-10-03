--!strict
--!optimize 2

-- Example owner wiring, outside the published package. Release this subscription
-- before destroying the mount; the mount itself knows only explicit attachments.
local Anatomy = require(game.ReplicatedStorage.packages.anatomy.src)

type SocketMount = Anatomy.SocketMount
type SocketWatcher<SocketT> = Anatomy.SocketWatcher<SocketT>

local function bindMountWatchers<FromSocketT, ToSocketT>(
	mount: SocketMount,
	from: SocketWatcher<FromSocketT>,
	to: SocketWatcher<ToSocketT>
): () -> ()
	local function update()
		local fromSocket = from:getSocket()
		local toSocket = to:getSocket()
		mount:setAttachments(
			if fromSocket then fromSocket:getAttachment() else nil,
			if toSocket then toSocket:getAttachment() else nil
		)
	end
	local disconnectFrom = from:bindSocketChanged(update)
	local disconnectTo = to:bindSocketChanged(update)
	update()
	return function()
		disconnectFrom()
		disconnectTo()
	end
end

return bindMountWatchers
