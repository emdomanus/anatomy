--!strict
--!optimize 2

local AnatomyTypes = require(script.Parent.Parent.Parent.Parent.def.anatomy.shared.anatomy)

type AnatomyPath = AnatomyTypes.AnatomyPath
type DescriptorMetadata = AnatomyTypes.DescriptorMetadata
export type AnatomySocket<SocketT> = {
	read getAttachment: (self: AnatomySocket<SocketT>) -> Attachment,
	read getName: (self: AnatomySocket<SocketT>) -> SocketT,
	read getPath: (self: AnatomySocket<SocketT>) -> AnatomyPath,
	read getMetadata: (self: AnatomySocket<SocketT>) -> DescriptorMetadata?,
}
export type AnatomySocketOwned<SocketT> = AnatomySocket<SocketT> & {
	read deconstruct: (self: AnatomySocketOwned<SocketT>) -> (),
}
export type AnatomySocketImpl<SocketT> = AnatomySocketOwned<SocketT> & {
	_name: SocketT,
	_path: AnatomyPath,
	_attachment: Attachment,
	_metadata: DescriptorMetadata?,
	_destroyed: boolean,
}
return {}
